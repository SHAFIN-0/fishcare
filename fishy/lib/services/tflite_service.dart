import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Runs the fish disease classifier fully on-device, with no network
/// dependency. Model + labels are bundled as app assets (see pubspec.yaml).
///
/// The model comes from fish_training.ipynb (Keras MobileNetV2 -> TFLite). It takes raw
/// pixel values 0..255 as input (the [-1, 1] scaling happens INSIDE the model), so this
/// class only has to resize the photo the same way training did.
/// The input size is read from the model itself, so a 128px or 224px model both work.
class TfliteService {
  TfliteService._();
  static final TfliteService instance = TfliteService._();

  /// true  = model from fish_training.ipynb (normalization is inside the model; feed 0..255).
  /// false = ONLY for the old PyTorch scratch_v1 model, which needed ImageNet mean/std outside.
  static const bool _modelNormalizesInput = true;
  static const List<double> _mean = [0.485, 0.456, 0.406];
  static const List<double> _std = [0.229, 0.224, 0.225];

  int _imageSize = 224; // overwritten in load() from the model's real input shape
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool get isReady => _interpreter != null;

  Future<void> load() async {
    if (_interpreter != null) return; // already loaded
    final interpreter = await Interpreter.fromAsset('assets/fish_disease_model.tflite');
    final labelsRaw = await rootBundle.loadString('assets/labels.txt');
    final labels = labelsRaw.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    // Fail loudly if the two asset files don't belong together (a classic silent-wrong-answer bug).
    final inShape = interpreter.getInputTensor(0).shape; // [1, size, size, 3]
    final outShape = interpreter.getOutputTensor(0).shape; // [1, numClasses]
    if (inShape.length != 4 || inShape[1] != inShape[2] || inShape[3] != 3) {
      interpreter.close();
      throw Exception('Unexpected model input shape $inShape (expected [1, size, size, 3]).');
    }
    if (outShape.last != labels.length) {
      interpreter.close();
      throw Exception('assets/labels.txt has ${labels.length} labels but the model outputs '
          '${outShape.last} classes. Replace the .tflite and labels.txt together.');
    }
    _imageSize = inShape[1];
    _labels = labels;
    _interpreter = interpreter;
  }

  /// Runs inference on raw image bytes (any format image_picker returns).
  /// Returns (label, confidence, allScores) matching the shape the app's
  /// PredictionResult model expects.
  Future<({String label, double confidence, Map<String, double> allScores})> predict(
    Uint8List imageBytes,
  ) async {
    if (_interpreter == null) {
      await load();
    }

    final raw = img.decodeImage(imageBytes);
    if (raw == null) {
      throw Exception('Could not decode image for on-device inference.');
    }
    // Phone photos are often stored sideways plus an EXIF "rotate" flag. The old copyResize call applied it
    // for us; our own resize must too, otherwise the model sees sideways fish (in a test this raised false
    // "healthy" calls from 63% to 73%). Does nothing if the photo is already upright.
    final decoded = img.bakeOrientation(raw);

    // Build the NHWC float32 input [1, size, size, 3] exactly like training did
    // (anti-aliased bilinear resize; normalization is inside the model).
    final input = [_preprocess(decoded)];

    // Output shape [1, num_classes] — raw logits (no softmax applied by the model).
    final output = List.generate(1, (_) => List.filled(_labels.length, 0.0));

    _interpreter!.run(input, output);

    final logits = output[0];
    final probs = _softmax(logits);

    var bestIdx = 0;
    for (var i = 1; i < probs.length; i++) {
      if (probs[i] > probs[bestIdx]) bestIdx = i;
    }

    final allScores = <String, double>{
      for (var i = 0; i < _labels.length; i++) _labels[i]: probs[i],
    };

    return (label: _labels[bestIdx], confidence: probs[bestIdx], allScores: allScores);
  }

  /// Anti-aliased bilinear resize (triangle filter whose width grows with the shrink factor).
  /// This is the same algorithm as PIL's Resize() and TensorFlow's tf.image.resize(antialias: true),
  /// which the models were trained with (checked offline: max difference < 0.003 grey levels vs
  /// TensorFlow). Do NOT swap it for img.copyResize: its default (nearest) just skips pixels, and
  /// even Interpolation.average is not the same filter. On a test photo the old code turned a 49%
  /// "bacterial_aeromoniasis" prediction into 97% "healthy".
  List<List<List<double>>> _preprocess(img.Image src) {
    final w = src.width;
    final h = src.height;

    // Copy source pixels once into a flat RGB array (0..255).
    final rgb = Float32List(w * h * 3);
    var n = 0;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final p = src.getPixel(x, y);
        rgb[n++] = p.r.toDouble();
        rgb[n++] = p.g.toDouble();
        rgb[n++] = p.b.toDouble();
      }
    }

    final xTaps = _filterTaps(w, _imageSize);
    final yTaps = _filterTaps(h, _imageSize);

    // Horizontal pass: h rows x _imageSize columns.
    final tmp = Float32List(h * _imageSize * 3);
    for (var y = 0; y < h; y++) {
      for (var ox = 0; ox < _imageSize; ox++) {
        final tap = xTaps[ox];
        var r = 0.0, g = 0.0, b = 0.0;
        for (var k = 0; k < tap.weights.length; k++) {
          final i = (y * w + tap.start + k) * 3;
          final wt = tap.weights[k];
          r += rgb[i] * wt;
          g += rgb[i + 1] * wt;
          b += rgb[i + 2] * wt;
        }
        final o = (y * _imageSize + ox) * 3;
        tmp[o] = r;
        tmp[o + 1] = g;
        tmp[o + 2] = b;
      }
    }

    // Vertical pass + normalization -> [_imageSize][_imageSize][3].
    return List.generate(_imageSize, (oy) {
      final tap = yTaps[oy];
      return List.generate(_imageSize, (ox) {
        var r = 0.0, g = 0.0, b = 0.0;
        for (var k = 0; k < tap.weights.length; k++) {
          final i = ((tap.start + k) * _imageSize + ox) * 3;
          final wt = tap.weights[k];
          r += tmp[i] * wt;
          g += tmp[i + 1] * wt;
          b += tmp[i + 2] * wt;
        }
        return [_norm(r, 0), _norm(g, 1), _norm(b, 2)];
      });
    });
  }

  /// Input value for one colour channel (v is 0..255).
  double _norm(double v, int channel) =>
      _modelNormalizesInput ? v : (v / 255.0 - _mean[channel]) / _std[channel];

  /// For every output index: first source index + normalized triangle-filter weights.
  List<({int start, List<double> weights})> _filterTaps(int inSize, int outSize) {
    final scale = inSize / outSize;
    final filterScale = max(scale, 1.0); // widen the filter when shrinking (anti-aliasing)
    final taps = <({int start, List<double> weights})>[];
    for (var o = 0; o < outSize; o++) {
      final center = (o + 0.5) * scale;
      final start = max((center - filterScale + 0.5).floor(), 0);
      final end = min((center + filterScale + 0.5).floor(), inSize);
      final weights = <double>[];
      var sum = 0.0;
      for (var s = start; s < end; s++) {
        final d = ((s + 0.5 - center) / filterScale).abs();
        final v = d < 1.0 ? 1.0 - d : 0.0;
        weights.add(v);
        sum += v;
      }
      taps.add((start: start, weights: [for (final v in weights) v / sum]));
    }
    return taps;
  }

  List<double> _softmax(List<double> logits) {
    final maxLogit = logits.reduce(max);
    final exps = logits.map((v) => exp(v - maxLogit)).toList();
    final sumExp = exps.reduce((a, b) => a + b);
    return exps.map((v) => v / sumExp).toList();
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
