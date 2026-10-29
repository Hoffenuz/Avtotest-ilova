import 'package:flutter/material.dart';

import '../screens/pro_screen.dart';
import '../screens/question_search_screen.dart';
import '../screens/road_signs_screen.dart';
import '../screens/topic_list_screen.dart';
import '../screens/variant_list_screen.dart';
import '../theme/app_theme.dart';

/// Sayt havolalari ilovada tegishli ekranni ochadi (Android App Links):
///
/// | Havola                          | Ekran                                   |
/// |---------------------------------|-----------------------------------------|
/// | avtotestu.uz/pro                | PRO                                     |
/// | avtotestu.uz/variant            | Variantlar                              |
/// | avtotestu.uz/mavzuli            | Mavzuli testlar                         |
/// | avtotestu.uz/belgilar           | Yo'l belgilari                          |
/// | avtotestu.uz/savol/`slug`       | Savol qidirish (slug so'zlari bilan)    |
/// | avtotestu.uz/savol/variant-N    | Variantlar                              |
///
/// Havola ilova ishga tushishidan oldin kelsa (sovuq start) navigator hali
/// yo'q — havola saqlanadi va [flushPending] bilan bosh ekran chiqqach
/// ochiladi. Google kirish qaytishi (`uz.avtotestu.app://auth-callback`) bu
/// yerga tegishli emas — u AuthProvider da.
///
/// DIQQAT: Android 12+ da https havola ilovada ochilishi uchun saytda
/// `https://avtotestu.uz/.well-known/assetlinks.json` bo'lishi shart —
/// bu sayt tomonida qilinadi (docs/AUDIT-MOBIL.md).
class DeepLinkService {
  DeepLinkService._();

  /// MaterialApp.navigatorKey — havola kelganda ekran shu orqali ochiladi.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const Set<String> hosts = {'avtotestu.uz', 'www.avtotestu.uz'};

  static Uri? _pending;

  /// Saytning https havolasimi.
  static bool isAppLink(Uri uri) =>
      (uri.scheme == 'https' || uri.scheme == 'http') &&
      hosts.contains(uri.host.toLowerCase());

  /// Havolaga mos ekran yoki `null` (bosh sahifa / noma'lum yo'l — hech
  /// narsa ochilmaydi, ilova shunchaki ochiq qoladi).
  static Widget? screenFor(Uri uri) {
    final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    // Til prefiksi (/ru/..., /uz/...) tashlanadi
    if (segs.isNotEmpty && (segs.first == 'ru' || segs.first == 'uz')) {
      segs.removeAt(0);
    }
    if (segs.isEmpty) return null;
    switch (segs.first) {
      case 'pro':
        return const ProScreen();
      case 'variant':
        return const VariantListScreen();
      case 'mavzuli':
        return const TopicListScreen();
      case 'belgilar':
        return const RoadSignsScreen();
      case 'savol':
        if (segs.length < 2) return const QuestionSearchScreen();
        final slug = segs[1];
        if (RegExp(r'^variant-\d+$').hasMatch(slug)) {
          return const VariantListScreen();
        }
        return QuestionSearchScreen(initialQuery: queryFromSlug(slug));
    }
    return null;
  }

  /// Slug → qidiruv so'rovi: `chorrahada-kim-birinchi-otadi-123` →
  /// `chorrahada kim birinchi otadi` (raqam-id tashlanadi).
  static String queryFromSlug(String slug) {
    final words = Uri.decodeComponent(slug)
        .split('-')
        .where((w) => w.isNotEmpty && !RegExp(r'^\d+$').hasMatch(w));
    return words.join(' ');
  }

  /// Havolani qayta ishlaydi. Sayt havolasi bo'lmasa `false`.
  static bool handle(Uri uri) {
    if (!isAppLink(uri)) return false;
    final nav = navigatorKey.currentState;
    if (nav == null) {
      _pending = uri;
      return true;
    }
    final screen = screenFor(uri);
    if (screen != null) nav.push(AppTheme.slideRoute(screen));
    return true;
  }

  /// Bosh ekran chiqqach — sovuq startda kelgan havolani ochadi.
  static void flushPending() {
    final uri = _pending;
    _pending = null;
    if (uri != null) handle(uri);
  }
}
