import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

class HistoryRecord {
  final String id;
  final String label; // raw class id, e.g. 'healthy', 'bacterial_red_disease'
  final double confidence;
  final int timestampMillis;
  final String? thumbnailBase64;
  final bool isUncertain;

  HistoryRecord({
    required this.id,
    required this.label,
    required this.confidence,
    required this.timestampMillis,
    required this.thumbnailBase64,
    required this.isUncertain,
  });

  DateTime get date => DateTime.fromMillisecondsSinceEpoch(timestampMillis);
  bool get isHealthy => label.toLowerCase() == 'healthy' && !isUncertain;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'confidence': confidence,
        'timestampMillis': timestampMillis,
        'thumbnailBase64': thumbnailBase64,
        'isUncertain': isUncertain,
      };

  factory HistoryRecord.fromJson(Map<String, dynamic> j) => HistoryRecord(
        id: j['id'] as String,
        label: j['label'] as String,
        confidence: (j['confidence'] as num).toDouble(),
        timestampMillis: j['timestampMillis'] as int,
        thumbnailBase64: j['thumbnailBase64'] as String?,
        isUncertain: j['isUncertain'] as bool? ?? false,
      );
}

/// Local-only detection history, persisted with shared_preferences.
/// No server, no account — matches the on-device-only design of the app.
class HistoryService {
  HistoryService._();
  static final HistoryService instance = HistoryService._();

  static const _key = 'fishcare_history_v1';
  static const _maxRecords = 200; // cap so storage doesn't grow unbounded

  List<HistoryRecord>? _cache;

  Future<List<HistoryRecord>> getAll() async {
    if (_cache != null) return _cache!;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      _cache = [];
      return _cache!;
    }
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    _cache = list.map(HistoryRecord.fromJson).toList();
    return _cache!;
  }

  Future<void> add({
    required String label,
    required double confidence,
    required Uint8List imageBytes,
    required bool isUncertain,
  }) async {
    final thumb = _makeThumbnail(imageBytes);
    final record = HistoryRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      label: label,
      confidence: confidence,
      timestampMillis: DateTime.now().millisecondsSinceEpoch,
      thumbnailBase64: thumb,
      isUncertain: isUncertain,
    );
    final all = await getAll();
    all.insert(0, record);
    if (all.length > _maxRecords) all.removeRange(_maxRecords, all.length);
    _cache = all;
    await _save(all);
  }

  Future<void> clear() async {
    _cache = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<void> _save(List<HistoryRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(records.map((r) => r.toJson()).toList()));
  }

  /// Small re-encoded JPEG thumbnail so history doesn't bloat local storage.
  String? _makeThumbnail(Uint8List bytes) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      final resized = img.copyResize(decoded, width: 160);
      final jpg = img.encodeJpg(resized, quality: 70);
      return base64Encode(jpg);
    } catch (_) {
      return null;
    }
  }

  // ---- Dashboard stats ----
  Future<({int total, int healthy, int needsAttention})> getStats() async {
    final all = await getAll();
    final healthy = all.where((r) => r.isHealthy).length;
    return (total: all.length, healthy: healthy, needsAttention: all.length - healthy);
  }
}
