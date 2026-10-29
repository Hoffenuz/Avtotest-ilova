import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bepul foydalanuvchiga animatsiya NAMUNASI (saytdagi `animDemo.ts` bilan
/// bir xil): birinchi 2 ta animatsiyali savolda video PRO'dagidek o'ynaydi,
/// keyin burchakda «▶ PRO» qoladi.
///
/// Hisob qurilmada (SharedPreferences), savol kaliti bo'yicha — bitta savolni
/// qayta ochish yangi namuna sarflamaydi.
class AnimDemo {
  AnimDemo._();

  static const int limit = 2;
  static const String prefsKey = 'anim_demo_keys';

  static List<String> _keys = const [];
  static bool _loaded = false;
  static Future<void>? _loading;

  /// Ishlatilgan namunalar soni.
  static int get used => _keys.length;

  /// Keshni o'qiydi. Ilova ishga tushganda bir marta chaqiriladi; keyin
  /// [allowed] va [consume] sinxron ishlaydi.
  static Future<void> load() {
    if (_loaded) return Future.value();
    return _loading ??= _load().whenComplete(() => _loading = null);
  }

  static Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _keys = List<String>.from(prefs.getStringList(prefsKey) ?? const []);
    } catch (e) {
      debugPrint("AnimDemo: kesh o'qilmadi: $e");
    }
    _loaded = true;
  }

  /// Shu savol uchun namuna ko'rsatish mumkinmi (allaqachon ko'rilgan yoki
  /// limit hali to'lmagan).
  static bool allowed(String? animKey) {
    if (animKey == null || animKey.isEmpty) return false;
    return _keys.contains(animKey) || _keys.length < limit;
  }

  /// Namuna ishlatildi; qaytaradi: nechanchi namuna (1 dan) yoki ruxsat
  /// bo'lmasa 0. Takror savol yangi namuna sarflamaydi.
  static int consume(String? animKey) {
    if (animKey == null || animKey.isEmpty) return 0;
    final idx = _keys.indexOf(animKey);
    if (idx >= 0) return idx + 1;
    if (_keys.length >= limit) return 0;
    _keys = [..._keys, animKey];
    _persist();
    return _keys.length;
  }

  static Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(prefsKey, _keys);
    } catch (e) {
      // Yozilmasa — joriy sessiyada baribir ko'rsatiladi.
      debugPrint('AnimDemo: saqlanmadi: $e');
    }
  }

  @visibleForTesting
  static void resetForTest() {
    _keys = const [];
    _loaded = false;
    _loading = null;
  }
}
