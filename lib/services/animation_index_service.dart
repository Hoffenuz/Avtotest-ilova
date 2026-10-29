import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Savol animatsiyalari (Blender videolari) indeksi: savol rasmi → video URL.
///
/// Manba: `https://media.avtotestu.uz/animatsiya/index.json`
/// `{ "version": 1, "videos": { "u1003uz": "u1003uz.8a77af85.mp4", ... } }`
///
/// Kalit — savol rasmining nomi kengaytmasiz (`u1003uz.webp` → `u1003uz`).
/// Rasm tilga bog'liq emas, shuning uchun bitta indeks uchala tilga yetadi.
/// Fayl nomida kontent hash bor — manzil o'zgarmaydi, xavfsiz keshlanadi.
///
/// Indeks ilova ishga tushganda fon rejimida bir marta yuklanadi va
/// SharedPreferences da saqlanadi; 24 soatdan eski bo'lsa qayta so'raladi.
/// Tarmoq yo'q — eski indeks ishlatiladi; indeks umuman yo'q — animatsiya
/// funksiyasi jim o'chiq (hech qanday xato chiqmaydi, rasm qoladi).
class AnimationIndexService {
  AnimationIndexService._();

  static const String baseUrl = 'https://media.avtotestu.uz/animatsiya/';
  static const String indexUrl = '${baseUrl}index.json';

  static const String prefsJsonKey = 'anim_index_json';
  static const String prefsFetchedAtKey = 'anim_index_fetched_at';

  /// Shu muddatdan eski indeks qayta so'raladi (eskisi shu orada ishlaydi).
  static const Duration maxAge = Duration(hours: 24);

  static const Duration _fetchTimeout = Duration(seconds: 10);

  /// `null` — indeks hali yuklanmagan yoki umuman yo'q (funksiya o'chiq).
  static Map<String, String>? _videos;
  static Future<void>? _loading;

  /// Yuklangan va bo'sh emas — animatsiya funksiyasi ishlaydi.
  static bool get isReady => _videos != null && _videos!.isNotEmpty;

  /// Indeksdagi video soni (diagnostika uchun).
  static int get count => _videos?.length ?? 0;

  /// Savol rasmidan animatsiya kaliti: `u1003uz.webp` → `u1003uz`.
  /// Papka va so'rov qismi tashlanadi, faqat oxirgi kengaytma olinadi.
  static String? keyFor(String? mediaUrl) {
    var name = mediaUrl?.trim() ?? '';
    if (name.isEmpty) return null;
    final q = name.indexOf('?');
    if (q >= 0) name = name.substring(0, q);
    final slash = name.lastIndexOf('/');
    if (slash >= 0) name = name.substring(slash + 1);
    final dot = name.lastIndexOf('.');
    if (dot > 0) name = name.substring(0, dot);
    return name.isEmpty ? null : name;
  }

  /// Savol rasmiga mos video manzili yoki `null` (video yo'q / indeks yo'q).
  static String? urlFor(String? mediaUrl) {
    final key = keyFor(mediaUrl);
    if (key == null) return null;
    final file = _videos?[key];
    if (file == null || file.isEmpty) return null;
    return '$baseUrl$file';
  }

  /// Indeks JSON matnini tekshirib, `kalit → fayl` xaritasiga aylantiradi.
  /// Tuzilma boshqa bo'lsa (masalan SPA fallback HTML) — `null`.
  static Map<String, String>? parse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final data = json.decode(raw);
      if (data is! Map<String, dynamic>) return null;
      final videos = data['videos'];
      if (videos is! Map<String, dynamic>) return null;
      final out = <String, String>{};
      videos.forEach((key, value) {
        if (value is String && value.isNotEmpty && key.isNotEmpty) {
          out[key] = value;
        }
      });
      return out;
    } catch (_) {
      return null;
    }
  }

  /// Saqlangan indeks qayta so'ralishi kerakmi.
  static bool isStale(int? fetchedAtMs, {DateTime? now}) {
    if (fetchedAtMs == null) return true;
    final at = DateTime.fromMillisecondsSinceEpoch(fetchedAtMs);
    return (now ?? DateTime.now()).difference(at) > maxAge;
  }

  /// Keshdan o'qiydi, kerak bo'lsa fon rejimida yangilaydi. Bir necha marta
  /// chaqirish xavfsiz — bitta yuklash jarayoni ulashiladi. Hech qachon
  /// xato otmaydi.
  static Future<void> load({
    Future<String?> Function()? fetch,
    DateTime Function()? now,
  }) {
    return _loading ??= _load(
      fetch ?? _fetchIndex,
      now ?? DateTime.now,
    ).whenComplete(() => _loading = null);
  }

  static Future<void> _load(
    Future<String?> Function() fetch,
    DateTime Function() now,
  ) async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      final cached = parse(prefs.getString(prefsJsonKey));
      if (cached != null) _videos = cached;
      if (!isStale(prefs.getInt(prefsFetchedAtKey), now: now())) return;
    } catch (e) {
      debugPrint("AnimationIndexService: kesh o'qilmadi: $e");
    }

    try {
      final raw = await fetch();
      final fresh = parse(raw);
      if (fresh == null) return; // eski indeks (bo'lsa) ishlayveradi
      _videos = fresh;
      await prefs?.setString(prefsJsonKey, raw!);
      await prefs?.setInt(prefsFetchedAtKey, now().millisecondsSinceEpoch);
    } catch (e) {
      // Tarmoq yo'q / 404 — jim. Eski indeks bo'lsa ishlaydi, bo'lmasa o'chiq.
      debugPrint('AnimationIndexService: indeks yuklanmadi: $e');
    }
  }

  static Future<String?> _fetchIndex() async {
    final client = HttpClient()..connectionTimeout = _fetchTimeout;
    try {
      final request = await client
          .getUrl(Uri.parse(indexUrl))
          .timeout(_fetchTimeout);
      final response = await request.close().timeout(_fetchTimeout);
      if (response.statusCode != 200) return null;
      return await response
          .transform(utf8.decoder)
          .join()
          .timeout(_fetchTimeout);
    } finally {
      client.close(force: true);
    }
  }

  @visibleForTesting
  static void setForTest(Map<String, String>? videos) {
    _videos = videos;
    _loading = null;
  }

  @visibleForTesting
  static void resetForTest() => setForTest(null);
}
