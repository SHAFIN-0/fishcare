import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../services/tflite_service.dart';
import '../services/history_service.dart';
import '../theme/app_colors.dart';
import '../widgets/brand_widgets.dart';

// Below these thresholds, the model's call is too weak to show as a
// confident diagnosis — see the "Uncertain Result" state below.
// Cross-validation on held-out fish showed the model's confidence is a WEAK signal: accuracy only
// rose from 79% (confidence >= 0.5) to 82% (>= 0.9). Raising these numbers flags more photos but
// catches few extra mistakes, so they are left at modest values. Re-check against cv_report.txt
// after retraining.
const double kConfidenceThreshold = 0.45;
const double kMarginThreshold = 0.12;

class AnalysisResultScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final String fileName;
  const AnalysisResultScreen({super.key, required this.imageBytes, this.fileName = 'upload.jpg'});

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen> {
  bool _loading = true;
  PredictionResult? _result;
  bool _isUncertain = false;

  @override
  void initState() {
    super.initState();
    _analyze();
  }

  bool _checkUncertain(Map<String, double> allScores) {
    // Red disease and EUS are shown as one look-alike group, so judge them as one score.
    // (Otherwise a clear "red-lesion" photo split 55/45 between them would count as uncertain.)
    final merged = Map<String, double>.from(allScores);
    var groupScore = 0.0;
    var hasGroup = false;
    for (final id in MockData.redLesionGroup) {
      final v = merged.remove(id);
      if (v != null) {
        groupScore += v;
        hasGroup = true;
      }
    }
    if (hasGroup) merged['red_lesion_group'] = groupScore;
    final sorted = merged.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    if (sorted.length < 2) return false;
    final top1 = sorted[0].value, top2 = sorted[1].value;
    return top1 < kConfidenceThreshold || (top1 - top2) < kMarginThreshold;
  }

  Future<void> _analyze() async {
    // Fully on-device inference — no network/server required. The TFLite
    // model + labels are bundled as app assets (see pubspec.yaml).
    try {
      final result = await TfliteService.instance.predict(widget.imageBytes);
      final uncertain = _checkUncertain(result.allScores);
      // For the red-disease/EUS look-alike group, show how sure the model is that it is ONE of the two.
      final shownConfidence =
          MockData.isRedLesionGroup(result.label) ? MockData.redLesionScore(result.allScores) : result.confidence;
      if (!mounted) return;
      setState(() {
        _result = PredictionResult(label: result.label, confidence: shownConfidence, allScores: result.allScores);
        _isUncertain = uncertain;
        _loading = false;
      });
      await HistoryService.instance.add(
        label: result.label,
        confidence: shownConfidence,
        imageBytes: widget.imageBytes,
        isUncertain: uncertain,
      );
      return;
    } catch (e, st) {
      // Model/asset failed to load for some reason — fall through to demo result
      // so the UI never gets stuck, but this should not normally happen once
      // the .tflite/labels.txt assets are correctly bundled.
      // Previously this was `catch (_)`, which hid the real cause (missing native TFLite
      // library, running on web, bad asset path, shape mismatch...). Check the debug console.
      debugPrint('On-device inference FAILED -> showing demo data. Cause: $e\n$st');
    }

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    final demo = MockData.diseases.first; // Bacterial Red Disease
    setState(() {
      _result = PredictionResult(
        label: demo.id,
        confidence: 0.89,
        allScores: {demo.id: 0.89, 'healthy': 0.06, 'parasitic_diseases': 0.05},
        isDemo: true,
      );
      _isUncertain = false;
      _loading = false;
    });
  }

  /// The disease(s) to describe: one, or both members of the red-lesion look-alike group (top one first).
  List<DiseaseInfo> get _diseases {
    if (_result == null) return const [];
    final label = _result!.label;
    final ids = MockData.isRedLesionGroup(label)
        ? [label, ...MockData.redLesionGroup.where((id) => id != label)]
        : [label];
    final out = <DiseaseInfo>[];
    for (final id in ids) {
      final d = MockData.byId(id);
      if (d != null) out.add(d);
    }
    return out;
  }

  String get _reportText {
    final r = _result!;
    final buffer = StringBuffer();
    buffer.writeln('FishCare Analysis Report');
    if (_isUncertain) {
      buffer.writeln('Result: Uncertain');
    } else if (r.isHealthy) {
      buffer.writeln('Result: No disease signs found in this photo (not a guarantee that the fish is healthy)');
    } else {
      buffer.writeln('Result: ${MockData.resultName(r.label)}');
      buffer.writeln('Confidence: ${(r.confidence * 100).toStringAsFixed(0)}%');
      if (MockData.isRedLesionGroup(r.label)) buffer.writeln(MockData.lookAlikeNote);
      if (r.label == MockData.otherDiseaseId) buffer.writeln(MockData.otherDiseaseNote);
      for (final d in _diseases) {
        buffer.writeln('\n${d.name}');
        buffer.writeln('Common name: ${d.commonName}');
        buffer.writeln('Affected area: ${d.affectedArea}');
        buffer.writeln('Symptoms: ${d.symptoms}');
        buffer.writeln('Treatment:');
        for (final t in d.treatment) {
          buffer.writeln('- $t');
        }
      }
    }
    buffer.writeln('\n${MockData.scopeNote}');
    buffer.writeln('Generated on-device by FishCare.');
    return buffer.toString();
  }

  void _share() {
    // share_plus 7.x API (the version pinned in pubspec.yaml). If you later
    // upgrade to share_plus 11+, switch this to:
    // SharePlus.instance.share(ShareParams(text: _reportText, subject: '...'));
    Share.share(_reportText, subject: 'FishCare Analysis Report');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Result'),
        actions: [
          if (!_loading)
            IconButton(
              icon: const Icon(Icons.camera_alt_outlined),
              tooltip: 'Retake',
              onPressed: () => Navigator.of(context).pop(),
            ),
        ],
      ),
      body: SafeArea(
        child: _loading ? _buildLoading() : _buildResult(context),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.teal),
          SizedBox(height: 16),
          Text('Analyzing image…', style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildResult(BuildContext context) {
    final result = _result!;

    if (_isUncertain) {
      return _buildUncertainState(result);
    }

    final diseases = _diseases;
    final isHealthy = result.isHealthy;
    final tint = isHealthy ? AppColors.warning : AppColors.danger;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (result.isDemo)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(10)),
              child: const Text(
                'Demo data — the on-device model failed to load, so a placeholder result is shown.',
                style: TextStyle(color: AppColors.warning, fontSize: 12),
              ),
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(widget.imageBytes, height: 210, width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isHealthy ? AppColors.warningBg : AppColors.dangerBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(isHealthy ? Icons.info_outline_rounded : Icons.error_rounded, color: tint, size: 18),
                    const SizedBox(width: 6),
                    Text(isHealthy ? 'No disease detected' : 'Disease Detected',
                        style: TextStyle(color: tint, fontWeight: FontWeight.w700, fontSize: 12.5)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        isHealthy ? 'No Disease Signs Found' : MockData.resultName(result.label),
                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                      ),
                    ),
                    // No percentage for "no disease signs": on photos unlike its training data the model can be
                    // very sure and still wrong, so a big "99%" next to a healthy result would mislead.
                    if (!isHealthy)
                      Text('${(result.confidence * 100).toStringAsFixed(0)}%',
                          style: TextStyle(color: tint, fontWeight: FontWeight.w800, fontSize: 15)),
                  ],
                ),
              ],
            ),
          ),
          if (isHealthy) _noteBox(MockData.healthyNote, AppColors.warningBg, AppColors.warning),
          if (!isHealthy && MockData.isRedLesionGroup(result.label))
            _noteBox(MockData.lookAlikeNote, AppColors.warningBg, AppColors.warning),
          if (!isHealthy && result.label == MockData.otherDiseaseId)
            _noteBox(MockData.otherDiseaseNote, AppColors.warningBg, AppColors.warning),
          for (final disease in diseases) ..._diseaseDetails(disease, showName: diseases.length > 1),
          const SizedBox(height: 18),
          const Text(
            MockData.scopeNote,
            style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.4),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _share,
                  icon: const Icon(Icons.save_alt_rounded, size: 18),
                  label: const Text('Save Report'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GradientButton(label: 'Share', icon: Icons.share_rounded, onPressed: _share),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _noteBox(String text, Color bg, Color fg) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: fg, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12.5, color: fg, height: 1.4))),
        ],
      ),
    );
  }

  List<Widget> _diseaseDetails(DiseaseInfo disease, {required bool showName}) {
    return [
      const SizedBox(height: 18),
      if (showName) ...[
        Text(disease.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
      ],
      Row(
        children: [
          Expanded(child: _InfoBlock(label: 'Common Name', value: disease.commonName)),
          const SizedBox(width: 16),
          Expanded(child: _InfoBlock(label: 'Affected Area', value: disease.affectedArea)),
        ],
      ),
      const SizedBox(height: 14),
      _InfoBlock(label: 'Symptoms', value: disease.symptoms),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.medical_services_outlined, color: AppColors.teal, size: 18),
                SizedBox(width: 6),
                Text('Treatment Recommendation', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
              ],
            ),
            const SizedBox(height: 10),
            ...disease.treatment.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(t, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
                    ],
                  ),
                )),
          ],
        ),
      ),
    ];
  }

  Widget _buildUncertainState(PredictionResult result) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(widget.imageBytes, height: 210, width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warningBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.help_outline_rounded, color: AppColors.warning, size: 20),
                    SizedBox(width: 8),
                    Text('Uncertain Result', style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w800, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  "This photo doesn't clearly match a known healthy or diseased pattern. "
                  "This may be a fish species, condition, or image quality the model wasn't trained to recognize.",
                  style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Please consult a fisheries expert rather than relying on this result.',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    'Best guess (low confidence): ${MockData.resultName(result.label)} — ${(result.confidence * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          GradientButton(
            label: 'Retake Photo',
            icon: Icons.camera_alt_rounded,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String label;
  final String value;
  const _InfoBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
