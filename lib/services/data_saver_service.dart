import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android «Trafikni tejash» (Data Saver) rejimi.
///
/// Yoqilgan bo'lsa savol videosi javobdan OLDIN oldindan yuklanmaydi — faqat
/// javobdan keyin so'raladi (saytdagi `navigator.connection.saveData` bilan
/// bir xil). Natija qisqa vaqt keshlanadi: bir test ichida har savolda
/// platforma kanaliga murojaat qilmaslik uchun.
class DataSaverService {
  DataSaverService._();

  static const MethodChannel _channel = MethodChannel('avtotestu/platform');
  static const Duration _ttl = Duration(seconds: 30);

  static bool _cached = false;
  static DateTime? _cachedAt;

  /// Oxirgi ma'lum qiymat (so'rov tugamagan bo'lsa ham). Standart — o'chiq.
  static bool get lastKnown => _cached;

  static Future<bool> isEnabled() async {
    final at = _cachedAt;
    if (at != null && DateTime.now().difference(at) < _ttl) return _cached;
    try {
      final value = await _channel.invokeMethod<bool>('dataSaver');
      _cached = value ?? false;
    } catch (e) {
      // iOS / eski Android / kanal yo'q — tejamkor rejim yo'q deb hisoblanadi.
      debugPrint('DataSaverService: $e');
      _cached = false;
    }
    _cachedAt = DateTime.now();
    return _cached;
  }

  @visibleForTesting
  static void resetForTest() {
    _cached = false;
    _cachedAt = null;
  }
}
