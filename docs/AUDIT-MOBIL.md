# Mobil ilova auditi — 2026-10-29

Branch: `feat/animatsiya`. Audit animatsiya ishidan keyin, 30 daqiqalik ko'rib
chiqish asosida. Har topilma: fayl, qator (audit paytidagi), muammo, holat.
Versiya raqami o'zgartirilmadi (egasi reliz qiladi).

## 1. Terminlar va matnlar

| № | Fayl:qator | Muammo | Holat |
|---|---|---|---|
| 1 | `lib/services/app_strings.dart:139` | `get_pro` = «Pro olish» — PRO CTA yagona emas («PRO olish» bo'lishi kerak) | Tuzatildi: «PRO olish / PRO олиш / Получить PRO» |
| 2 | `lib/services/app_strings.dart:1427` | `subscribe_pro` = «PRO ga obuna bo'lish» — pro_screen va paywall'dagi asosiy tugma | Tuzatildi: «PRO olish» |
| 3 | `lib/services/app_strings.dart:991` | `dark_mode` = «Qorong'u rejim» — saytda «Tun rejimi» | Tuzatildi: «Tun rejimi / Тун режими / Тёмная тема» |
| 4 | `lib/services/app_strings.dart:598` | `clear_practice_results_msg` — kirill kalitida LOTIN matn («Test ishlash bo'limidagi…») | Tuzatildi |
| 5 | `lib/services/app_strings.dart` | Kalit to'liqligi: 377 kalit, uchala tilda (`uz_lat/uz_cyr/ru`) to'liq — skript bilan tekshirildi; kirill qiymatlarida qolgan lotin so'zlar faqat «email/Email» (qabul qilinadi) | OK |
| 6 | `lib/screens/**`, `lib/widgets/**` | Kodda qattiq yozilgan UI matn topilmadi (faqat `language_provider.dart:14-25` til nomlari — ataylab) | OK |
| 7 | — | «Imtihon formati» / «rasmiy imtihon formatida» ilovada yo'q (egasining `df14e73` WIP'ida olib tashlangan). «Imtihon» so'zi faqat real imtihon kalitlarida | OK |
| 8 | `lib/screens/test_screen.dart:1177` | Sarlavhadagi avto-o'tish belgisi (⏭) — ma'nosi tushunarsiz, alohida tugma | Tuzatildi: bitta ⚙ → Tun rejimi · Animatsiyalar · Avto-o'tish |

## 2. Tun rejimi

| № | Fayl:qator | Muammo | Holat |
|---|---|---|---|
| 9 | `lib/widgets/readiness_widgets.dart:265` | Streak chipi matni `0xFFC2410C` (to'q zarg'aldoq) — tun rejimida shaffof zarg'aldoq fonda o'qilmasdi | Tuzatildi: `dark ? 0xFFFDBA74 : 0xFFC2410C` |
| 10 | `lib/screens/real_exam_screen.dart` (29 ta qattiq rang) | Ataylab: real imtihon ekrani yorug'/tun rejimida BIR XIL ko'rinishi kerak | O'zgartirilmadi |
| 11 | `lib/screens/memorize_screen.dart:36-44`, `avtodrom_screen.dart:29-31` | Kategoriya/daraja ranglari — ikkala rejimda ishlaydi (fon theme tokenidan) | OK |
| 12 | `lib/screens/pro_screen.dart:832,848,1231` | Payme / Click / Telegram brend ranglari — o'zgartirilmaydi | OK |
| 13 | Qolgan ekranlar | `AppTheme.card/surface/textP/textS/textM/border` tokenlari ishlatilgan | OK |

## 3. Test ekrani

| № | Fayl:qator | Muammo | Holat |
|---|---|---|---|
| 14 | `lib/widgets/question_image.dart` | Rasm `AspectRatio` + `image-sizes.json` bilan oldindan joy oladi — CLS yo'q; javob tugmalari siljimaydi | OK (avvaldan) |
| 15 | `lib/screens/test_screen.dart` (`_DeliberatePagePhysics`, `PopScope`) | Swipe faqat ataylab, orqaga tugmasi — chiqish dialogi (saytdagidek) | OK (avvaldan) |
| 16 | `lib/screens/test_screen.dart` | Avto-o'tish video ustidan sakrab ketardi (video yo'q edi) | Tuzatildi: `AutoAdvanceScheduler` video tugashini kutadi (+0,7 s) |

## 4. Natija ekrani

| № | Fayl:qator | Muammo | Holat |
|---|---|---|---|
| 17 | `lib/screens/result_screen.dart:170-185` | Xatolar faqat raqam («Xato: 4») — qaysi savollar ekani ko'rinmaydi, savolga o'tib bo'lmaydi | Tuzatildi: xatolar ro'yxati → savol oynasi (matn, rasm, to'g'ri/tanlangan javob, izoh) |
| 18 | `lib/screens/result_screen.dart` | «Xatolar testi» CTA yo'q | Tuzatildi: faqat xato savollardan mashq (savol boshiga 2 daqiqa) |
| 19 | `lib/widgets/explanation_panel.dart:96` | Bepulda izoh qulfi tugmasi faqat «PRO» | Tuzatildi: «Izohni ochish — PRO olish» (izoh bepulda ochilmaydi — `ExplanationPanel` ichidagi qulf saqlanadi) |

## 5. Tarmoq

| № | Fayl:qator | Muammo | Holat |
|---|---|---|---|
| 20 | `lib/services/profile_service.dart:42,58` | Supabase so'rovlari timeout'siz — sekin tarmoqda cheksiz kutish | Tuzatildi: 15 s |
| 21 | `lib/services/subscription_service.dart:83` | `get_user_access_state` RPC timeout'siz | Tuzatildi: 15 s (keshdagi PRO holati bilan davom etadi) |
| 22 | `lib/services/test_results_service.dart:52,102` | RPC va `test_results` so'rovi timeout'siz | Tuzatildi: 15 s |
| 23 | `lib/providers/auth_provider.dart:130,161,194,257,340,352,366,401,420` | Kirish/ro'yxat/parol/chiqish chaqiruvlari timeout'siz | Tuzatildi: 20 s (chiqish 10 s); `TimeoutException` mavjud `catch` lar orqali «offline» xatosiga tushadi |
| 24 | `lib/services/supabase_service.dart:29` | `autoRefreshToken: true` — sessiya tugasa jim yangilanadi | OK (avvaldan) |
| 25 | `lib/services/question_service.dart` | Testlar asset'dan — offline ishlaydi; PRO holati `SubscriptionProvider` keshidan | OK (avvaldan) |

## 6. Hajm va tezlik

| № | Fayl:qator | Muammo | Holat |
|---|---|---|---|
| 26 | `assets/tests-json/images/` (304 fayl), `belgilar_images/` (1 fayl) | 306 ta rasm > 100 KB, jami 45,7 MB (eng kattasi 1,9 MB jpg, 350 KB webp) | Tuzatildi: qayta kodlandi (WebP q≥60, 6 tasi 1024 px ga kichraytirildi) → 26,3 MB. 1 ta fayl (`u64-9.webp`) 117 KB qoldi |
| 27 | `pubspec.yaml:24` | `cupertino_icons` hech qayerda ishlatilmaydi | Olib tashlandi |
| 28 | `pubspec.yaml` | `timezone`, `crypto`, `flutter_svg`, `webview_flutter`, `connectivity_plus` — har biri ishlatiladi | OK |
| 29 | `android/build/reports/problems/problems-report.html` | Gradle hisoboti repoda tracked | `git rm --cached`, `.gitignore` ga `android/build/` |
| 30 | `_gen_phase3.py`, `_gen_ui.py`, `test/study_features_test.dart.bak` | Bir martalik «barcha Dart UI fayllarini qayta yozish» skriptlari va `.bak` — tasodifan ishga tushsa ilovani buzadi | Repodan olindi (git tarixida qoladi) |
| 31 | `lib/main.dart` | Ilk ochilish: birinchi kadrdan oldin faqat til/tema/sozlama o'qiladi; Supabase/auth/savollar — keyin | OK (avvaldan). **O'lchanmadi**: Android qurilma ulanmagan — egasi `flutter run --profile` bilan tekshirsin (maqsad ≤ 2 s) |
| 32 | APK (release, arm64, `flutter build apk --target-platform android-arm64`) | Oldin (df14e73, animatsiyasiz): **96,6 MB** | Keyin (9a8f8b6): **77,9 MB** (−18,7 MB; `video_player`/ExoPlayer qo'shilgan bo'lsa ham) |

## 7. Havoladan ochish (App Links)

| № | Fayl:qator | Muammo | Holat |
|---|---|---|---|
| 33 | `android/app/src/main/AndroidManifest.xml` | Faqat `uz.avtotestu.app://auth-callback`; `https://avtotestu.uz/...` havolalari ilovada ochilmasdi | Tuzatildi: `autoVerify` intent-filter (`/savol/`, `/variant`, `/pro`, `/mavzuli`, `/belgilar`) + `lib/services/deep_link_service.dart` |
| 34 | `lib/providers/auth_provider.dart:_handleOAuthReturn` | Google qaytishi bo'lmagan havola jim tashlanardi | Tuzatildi: `DeepLinkService.handle` |
| 35 | **Sayt tomonida** | `https://avtotestu.uz/.well-known/assetlinks.json` — **YO'Q** (apex 301 → www, www 404). Android 12+ da busiz https havola ilovada OCHILMAYDI | **Egasiga**: saytga `assetlinks.json` qo'yish kerak (package `com.hoffenuz.avtotestu`, upload/Play signing key SHA-256; Play Console → App integrity → App signing). Cloudflare Pages'da `public/.well-known/assetlinks.json` |
| 36 | `/savol/<slug>` | Ilovada slug ma'lumoti yo'q | Slug so'zlari bilan «Savol qidirish» ochiladi (`QuestionSearchScreen.initialQuery`); `savol/variant-N` → Variantlar |

## 8. Yangilanish va baholash

| № | Fayl:qator | Muammo | Holat |
|---|---|---|---|
| 37 | `lib/services/app_update_service.dart:92` | `performImmediateUpdate` — majburiy, to'liq ekranli Play oynasi testni bo'ladi | Tuzatildi: `startFlexibleUpdate` + `completeFlexibleUpdate` (banner «O'rnatish»ga aylanadi) |
| 38 | `lib/services/review_prompt_service.dart:46` | Baholash oynasi 60 kunda bir | Tuzatildi: 30 kun; 3-muvaffaqiyatli testdan keyin (avvaldan) |

## 9. Ochiq savollar (egasi qaror qiladi)

1. **assetlinks.json** (№35) — sayt tomonida. Busiz havoladan ochish Android 12+ da ishlamaydi.
2. **Tejamkor rejim** — Android «Trafikni tejash» (Data Saver) + o'lchanadigan tarmoq bo'lsa video javobdan oldin yuklanmaydi. «Sekin tarmoq» (2G) aniqlanmaydi — Flutter'da ishonchli signal yo'q; 8 s boshlanish chegarasi shuni qoplaydi.
3. **Video keshi** — `video_player` (ExoPlayer) sessiyalar aro keshlamaydi; bir savol qayta ko'rilsa video qayta yuklanadi (~600 KB). `flutter_cache_manager` — 2-bosqich.
4. **`u64-9.webp`** 117 KB (1024 px, q60) — yanada kichraytirish sifatni buzadi.
5. **iOS** — animatsiya va App Links faqat Android uchun sozlandi.
6. **Ilk ochilish vaqti** — qurilmasiz o'lchanmadi.

## 10. Qo'lda tekshirish ro'yxati (haqiqiy Android telefon)

- [ ] PRO hisob: variant 1 — 5, 13, 20-savollar: javobdan keyin 0,6 s qorayish → video o'zi o'ynaydi, ovozsiz, tugagach ↻; ⛶ kattalashtirish (landscape), 🖼 rasmga qaytish, tegish — pauza/davom
- [ ] Bepul hisob: birinchi 2 ta animatsiyali savolda «Namuna 1/2 · PRO» chipi; 3-savolda faqat «▶ PRO» → PRO ekrani; o'sha savol qayta ochilsa namuna sarflanmaydi
- [ ] ⚙ menyu: Tun rejimi · Animatsiyalar (bepulda PRO belgisi, lekin o'chirib/yoqib bo'ladi) · Avto-o'tish
- [ ] Avto-o'tish yoqiq: video tugagach +0,7 s keyingi savol; kattalashtirilgan holda tugasa — yopilgandan keyin; izoh ochilsa — kutish bekor
- [ ] Internet o'chiq: rasm qoladi, xato chiqmaydi, test to'xtamaydi
- [ ] Trafikni tejash yoqiq: javobdan oldin tarmoq so'rovi yo'q (Android Studio Network Profiler)
- [ ] Natija ekrani: xatolar ro'yxati → savol oynasi; «Xatolar testi»; bepulda «Izohni ochish — PRO olish»
- [ ] Havola: `https://avtotestu.uz/pro` (assetlinks qo'yilgandan keyin) ilovada PRO ekranini ochadi

## 11. Skrinshotlar

`docs/screenshots/animatsiya/` — widget-test render (`test/screenshots/screens_capture_test.dart`,
`SHOT_PHASE=animatsiya`): test ekrani javobdan oldin/keyin (bepul «▶ PRO», PRO), ⚙ menyu,
natija ekrani xatolar ro'yxati — yorug'/tun, 360×800. Test muhitida video platformasi yo'q,
shuning uchun PRO kadrida video o'rniga rasm ko'rinadi; haqiqiy video faqat telefonda.
Barcha ekranlar (3 o'lcham × 2 tema): `flutter test test/screenshots/screens_capture_test.dart --dart-define=SHOT_PHASE=animatsiya`.

