# AvtoSmart mobil ilova auditi — 2026-11-05

Branch: `feat/animatsiya` (oxirgi commit — avtodrom simulyatori WebView). 87 Dart fayl, 26 592 qator `lib/`,
3 548 qator `test/`. Faqat o'qildi va tahlil qilindi, kodga tegilmadi. Oldingi audit (`docs/AUDIT-MOBIL.md`,
2026-10-29) topilmalari takrorlanmaydi — holati 9-bo'limda yangilandi.

**Tekshiruv natijasi:** `flutter analyze --no-pub` — **0 muammo** (59,6 s). `flutter test --no-pub` — **175 o'tdi, 2 yiqildi**
(`test/app_version_test.dart` — versiya farqi; `test/narrow_screen_test.dart` «Home fits a 320 dp phone» — 308 px overflow).

## (a) Xulosa — 10 qator

1. Ilova texnik jihatdan pishgan: ishga tushish tartibi to'g'ri (faqat til/tema birinchi kadrgacha), JSON `compute` da, rasm keshi chegaralangan, barcha tarmoq so'rovlari timeout'li, analyze toza.
2. **Reliz to'sig'i:** `pubspec.yaml` 1.0.18+18, `app_version.dart` esa 1.0.17/17 — test yiqiladi, «Ilova haqida» eski versiyani ko'rsatadi.
3. **Bosh ekrandagi yangi Avtodrom kartasi** 320–360 dp telefonlarda sarlavha+«YANGI» belgisi qatorida **308 px overflow** beradi (kesilgan matn), test ham yiqiladi.
4. **Sayt bilan biznes nomuvofiqligi:** ilovada 1–5 variant bepul (`v1..v5.json`, to'liq biletlar), saytda 1–3 (va «1-variant» = v59 ma'lumoti). Foydalanuvchi ikkala joyda boshqa savol va boshqa qulf ko'radi.
5. **PRO izohlar (1 275 ta) APK ichida ochiq** `barcha.json` da yotadi — qulf faqat klientda; APK ni ochgan har kim hammasini oladi.
6. PRO holati diskka yozilmaydi: sust/uzilgan tarmoqda PRO foydalanuvchi har sovuq startda 15 s spinner → xato → paywall ko'radi.
7. 5 joyda `await` dan keyin `mounted` tekshirilmay `setState` chaqiriladi (test ekranidagi «saqlash» tugmasi ham) — ekrandan chiqib ketilsa async xato.
8. PRO video oldindan yuklanishi (preload) har animatsiyali savolda javobdan OLDIN tarmoqdan boshlanadi — 20 savollik test ≈ 12 MB mobil trafik.
9. Dizayn: pastki menyu nomlari saytdan farq qiladi («Asosiy/Sozlamalar» vs «Bosh sahifa/Profil»), asosiy tugmalar ko'k (#3B82F6), sayt siyoh (#131A45). 3 til pariteti to'liq (389 kalit).
10. Sayt bilan muvofiqlik yaxshi (variant, mavzu, real imtihon, xatolar, saqlangan, qidirish, qiyin, yodlash, avtodrom jadval+sim, animatsiya 301, Payme/Click), ilovada yo'q: darslik videolari, belgi tavsiflari (252), Telegram login, yangiliklar.

## (b) JIDDIY XATOLAR

| № | Xato | Fayl:qator | Qanday yuz beradi (ssenariy) | Oqibati | Tuzatish | Muhimlik |
|---|---|---|---|---|---|---|
| 1 | Avtodrom kartasida `Row` ichida sarlavha va «YANGI» belgisi `Flexible`siz, o'ng padding 150 px | `lib/widgets/avtodrom_card.dart:56-90` | Bosh ekran 320–360 dp telefonda ochiladi; kartaga 100–160 px qoladi, «Avtodrom simulyatori» 18 px qalin matn sig'maydi | Sarlavha kesiladi (release'da jim), debug'da sariq-qora chiziq; `narrow_screen_test` yiqiladi | Sarlavhani `Flexible` + `FittedBox(scaleDown)`/`ellipsis` ga o'rash, belgini ikkinchi qatorga tushirish, o'ng paddingni ~110 px qilish, rasmni `Positioned` da `width` bilan cheklash | **Yuqori** (bosh ekran, bugungi commit) |
| 2 | Versiya konstantasi pubspec bilan mos emas | `lib/config/app_version.dart:12,15` ↔ `pubspec.yaml:13` | Reliz yig'iladi, test yiqiladi (loyihaning o'z qoidasi — qurilishni to'xtatish) | Play'ga 1.0.18 chiqadi, ilova ichida «v1.0.17»; yangilanish banneri mantig'i chalkashadi | `name='1.0.18'`, `code=18` | **Yuqori** (reliz to'sig'i) |
| 3 | Bepul variantlar soni va mazmuni saytdan farq qiladi | `lib/config/free_access.dart:12` (5 ta, `v1..v5.json`) ↔ sayt `src/lib/variantAccess.ts:9` (`[1,2,3]`, 1-variant = v59, 2–3 bepul bazadan) | Bepul foydalanuvchi ilovada v4, v5 to'liq biletlarni (PRO savollari bilan) ochadi; saytda 1-variant deb v59 ni ishlaydi, ilovada v1 ni | Ikki mahsulot «bitta» emas; 2 ta PRO bilet bepul tarqaladi; natijalar statistikasi (`variant` 1) ikki xil to'plamni aralashtiradi | Mahsulot qarori: ikkalasida **bir xil** ro'yxat (tavsiya 1–3) va bir xil savol manbasi; `FreeAccess` ni saytdagi `variantAccess` bilan sinxron saqlash testi | **Yuqori** (biznes) |
| 4 | PRO izohlar APK ichida shifrlanmagan | `assets/tests-json/barcha.json` (1 275 `izoh`), `lib/models/question.dart:26-27`, qulf: `lib/widgets/explanation_panel.dart:91,118` | Har kim APK ni zip sifatida ochib `barcha.json` ni o'qiydi; Telegram'da «izohlar fayli» tarqaladi | PRO ning asosiy qiymati bepul; sayt bilan bir xil ochiq masala (PRO JSON himoyasi) | `izoh` ni bundle'dan olib tashlash; PRO uchun `get_question_izoh(global_id)` RPC (RLS/`get_user_access_state` bilan) + qurilmada shifrlangan kesh (PRO muddati bilan). Minimal variant: izohni alohida obfuskatsiya qilingan faylda saqlash (vaqtinchalik) | **Yuqori** (xavfsizlik/biznes) |
| 5 | PRO holati faqat xotirada, diskda yo'q | `lib/providers/subscription_provider.dart:18,197-233`; `lib/widgets/pro_gate.dart:79-87`; `lib/widgets/guarded_test_launcher.dart:74-103` | PRO foydalanuvchi metroda ilovani ochadi: `_access == null` → `isUnknown` → spinner → 15 s timeout → `error` → paywall «qayta urinish» | Pullik foydalanuvchi «PRO yo'qolgan» deb o'ylaydi (qo'llab-quvvatlash murojaatlari); mavzu/variant umuman ochilmaydi (dizayn bo'yicha), lekin **xabar** paywall emas, «tarmoq yo'q» bo'lishi kerak | Oxirgi `UserAccessState` (+`expiresAt`, +vaqt) ni SharedPreferences ga yozish; sovuq startda `resolved=true` deb ko'rsatish, fonda yangilash; 7 kunlik «grace» ichida oflayn izoh/ko'rish; sessiya ochish server tekshiruvi qoladi | **O'rta-yuqori** |
| 6 | `await` dan keyin `mounted` tekshirilmay `setState` | `lib/screens/test_screen.dart:132,135`; `lib/screens/errors_screen.dart:147`; `lib/screens/saved_questions_screen.dart:71,101` | Test ichida «saqlash» bosiladi, prefs yozilguncha foydalanuvchi orqaga chiqadi (yoki test tugaydi) | `setState() called after dispose` — release'da unhandled async xato (crash emas, lekin Crashlytics/logcat shovqini, debug'da qizil ekran) | Har birida `if (!mounted) return;` (test_screen da `await` dan keyin ikkala shox uchun) | **O'rta** |
| 7 | `launchGuardedTest` statik `_launchInProgress` bayrog'i `try` dan oldin o'rnatiladi | `lib/widgets/guarded_test_launcher.dart:33-61` | 36–61 qatorlarda istisno (masalan, `ScaffoldMessenger.of` yo'q kontekst, `navigator.push` xatosi) | Bayroq hech qachon tiklanmaydi → barcha mavzu/variant bosishlari ilova qayta ochilguncha jim e'tiborsiz | Bayroqni `try` ichiga olish yoki butun funksiyani `try/finally` bilan o'rash | **O'rta-past** |
| 8 | To'lovdan keyingi tekshiruv yomon tarmoqda ~2,5 daqiqa yopilmas dialog | `subscription_provider.dart:111-131` (8 ta RPC, har biri `subscription_service.dart:86` 15 s) + `pro_screen.dart:274-280` (`_verifyWithLoader`, `barrierDismissible:false`) | Click/Payme'dan qaytgan foydalanuvchi, 2G tarmoq: har RPC 15 s kutadi | Foydalanuvchi ilovani «qotdi» deb yopadi; to'lov tasdiqlangan bo'lsa ham | Umumiy devor-soat chegarasi (~25 s) + «Keyinroq tekshirish» tugmasi; `watchForActivation` fon rejimi qoladi | **O'rta** |
| 9 | Animatsiya videosi javobdan OLDIN har savolda oldindan yuklanadi | `lib/widgets/question_media.dart:208,254-259` | PRO (va 2 ta namuna) foydalanuvchi mobil internetda 20 savollik test ochadi; har animatsiyali sahifada `VideoPlayerController.networkUrl` yaratiladi | ~600 KB × savol → 10–12 MB trafik, batareya; Data Saver faqat tizimda «fon cheklovi» yoqiq bo'lsa ishlaydi | Preload'ni faqat Wi-Fi/o'lchanmagan tarmoqda (`connectivity_plus` `wifi`/`ethernet`) va faqat joriy sahifada qilish; mobil tarmoqda javobdan keyin yuklash | **O'rta** (trafik) |
| 10 | 8 s start-timeout'dan keyin rasm qorong'i + spinner holatida qoladi | `question_media.dart:316-318` | Sekin tarmoq, video 8 s da boshlanmaydi: `_finish()` chaqiriladi, lekin `_phase` `loading` da qoladi | Avto-o'tish ketadi, lekin qo'lda qolgan foydalanuvchi qorong'i rasm + aylanuvchi spinner ko'radi | Timeout'da `_phase = _Phase.image` (yoki `error`) + controller dispose | **Past** |
| 11 | `isPro` mahalliy `expiresAt` ni tekshirmaydi | `subscription_provider.dart:28` | Ilova ochiq turganda PRO muddati tugaydi (yarim tun) | Keyingi `resume`/refresh'gacha PRO ochiq qoladi (bir necha soat) | `isPro => isPremium && (expiresAt == null \|\| now < expiresAt)` | **Past** |
| 12 | Har `resume` da 3–4 ta majburiy RPC zanjiri | `auth_gate.dart:72-77`, `pro_gate.dart:46-50`, `premium_access_gate.dart:50-54`, `pro_screen.dart:352-360` | Foydalanuvchi ilovaga qaytadi; har kuzatuvchi `refresh(force:true)` — `refresh` majburiy so'rovlarni ketma-ket navbatga qo'yadi | Har qaytishda 3–4 ta `get_user_access_state` so'rovi (Supabase hisobida ko'rinadi) | `resume` ni faqat `AuthGate` da `force`, qolganlarida `refresh()` (keshli) | **Past** (xarajat) |
| 13 | Avtodrom WebView fonda to'xtamaydi, tizim UI rejimi shartsiz tiklanadi | `lib/screens/avtodrom_sim_screen.dart:42-44,93-99` | O'yin paytida qo'ng'iroq/ilova fonga o'tadi | Godot o'yini CPU/ovozni davom ettiradi (batareya); `dispose` da `edgeToEdge` qaytariladi (ilgari qaysi rejim bo'lganidan qat'i nazar) | `WidgetsBindingObserver` → `paused` da `_web.runJavaScript('...pause')` yoki `loadRequest(about:blank)`; oldingi rejimni saqlab tiklash | **Past** |
| 14 | `PremiumAccessGate._onAccessAttempt` bo'sh lifecycle kodi | `premium_access_gate.dart:33-59` | — | O'lik kod, kuzatuvchi ro'yxatini band qiladi, o'qiydiganni chalg'itadi | Observer va metodni olib tashlash (ProGate hammasini qiladi) | **Past** |

**Tekshirildi, muammo topilmadi:** `main.dart` ishga tushish tartibi va orientatsiya; `StreamSubscription`/`Timer` lar `dispose` da yopiladi (auth_provider, test_screen, real_exam, question_media, readiness); Supabase init yiqilsa mehmon rejimi (`currentSession` himoyalangan); auth refresh — `autoRefreshToken`, sayt (2026-11-04) dagi `navigator.locks` muammosi Flutter'da yo'q, bir vaqtda ikki so'rov `SubscriptionProvider.refresh` da navbatlanadi; to'lov oqimi — PRO hech qachon klientda yoqilmaydi, return URL `startsWith` bilan ushlanadi, tashqi sxemalar (`payme://`, `uzcard://`, `humo://`) manifest `queries` da; Payme/Click id'lari va anon kalit ommaviy (RLS); keystore va `key.properties` ishchi papkada bor, lekin `.gitignore` da (`.gitignore:49-52`); ruxsatlar minimal (INTERNET, POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED); `largeHeap=true` — xotira muammosini yashiradi, ishlatish sababi hujjatlanmagan.

## (c) Arxitektura — topilmalar va tavsiyalar

**Qatlamlar.** UI (`screens/` 23, `widgets/` 22) → `providers/` (6 `ChangeNotifier`: auth, subscription, settings, language, theme, readiness) → `services/` (27 ta, hammasi `static` sinflar). Chegaralar aniq: ekranlar Supabase'ga to'g'ridan-to'g'ri murojaat qilmaydi, servislar Flutter widget'iga bog'liq emas (`deep_link_service.dart` istisno — u ekranlarni import qiladi, bu maqbul). Domain/data ajratilmagan, lekin loyiha hajmi uchun ortiqcha.

**Static singleton servislar.** `QuestionService._cache`, `AnimDemo`, `AnimationIndexService`, `ConnectivityService`, `PaymeService._last`, `AppUpdateService`, `DataSaverService` — hammasi global o'zgaruvchan holat. Test uchun `resetForTest/setForTest` ilgaklari qo'yilgan (yaxshi amaliyot), lekin `SupabaseService.client` ni almashtirib bo'lmaydi — shuning uchun to'lov/obuna ekranlari faqat «ko'rinish» darajasida test qilinadi. Tavsiya: faqat `SupabaseService` uchun yupqa interfeys (`SupabaseGateway`) va `ProScreen.plansLoader` uslubidagi inyeksiya nuqtalari — to'liq DI kerak emas.

**setState vs Provider.** Izchil: ekran holati `setState`, global holat `context.watch/select` (`watchHasPro` selector — yaxshi). `TestScreen` taymeri `ValueNotifier` da — to'g'ri. Jiddiy aralashish yo'q.

**Takrorlanish.** `TestScreen` (1 818 qator) va `RealExamScreen` (803) o'z taymeri, raqamlar chizig'i, javob kafeli, tugatish dialogini alohida saqlaydi. `_QuestionNumberStrip`, `_AnswerOptionTile`, taymer chipi `widgets/` ga chiqarilsa ~400 qator kamayadi va ikki ekran bir xil ko'rinadi. `PaymeCheckoutScreen` Payme va Click'ni ko'taradi — nomi chalg'itadi (`CheckoutWebViewScreen`).

**Fayl o'lchamlari (eng katta 10):** `app_strings.dart` 2 221 · `test_screen.dart` 1 818 · `profile_screen.dart` 1 507 · `readiness_widgets.dart` 1 274 · `pro_screen.dart` 1 266 · `brand.dart` 932 · `auth_screen.dart` 902 · `real_exam_screen.dart` 803 · `my_results_screen.dart` 757 · `result_screen.dart` 748. Tavsiya: `profile_screen` → sozlamalar bo'limlari alohida fayllar; `pro_screen` → `_PlanCard/_ProviderPicker/_FeaturesCard` ni `widgets/pro/` ga; `app_strings` → ekran bo'yicha bir nechta `part` fayl (kalitlar o'zgarmaydi).

**Test qoplami.** 23 fayl, 177 test (175 o'tdi). Yaxshi qoplangan: to'lov havolalari (Payme/Click), obuna holat mashinasi, animatsiya indeksi/namuna, bepul kirish, tor ekran, real imtihon, deep link. Qoplanmagan: `TestScreen` javob → avto-o'tish → natija oqimi; `PaymeCheckoutScreen._handleNavigation` (return URL, tashqi sxema); `DeepLinkService.screenFor` jadvali; `SubscriptionProvider.refresh` majburiy navbat; `ConnectivityService` kesh. `readiness_test` logida «You must initialize the supabase instance» — test Supabase'siz ishlaydi, ushlangan, lekin ReadinessProvider uchun `SupabaseService.isInitialized` tekshiruvi tozaroq.

## (d) Ishlash

- **Ishga tushish:** birinchi kadrgacha faqat 3 ta prefs o'qish (bitta kanal); Supabase/auth/indeks/bank — fonda; bank 5 s kechikish bilan `compute` da. Qurilmada o'lchanmagan (oldingi auditdagidek) — `flutter run --profile` + `adb shell am start -W` bilan ≤2 s maqsad.
- **Ro'yxatlar:** `GridView.builder` (variantlar), `ListView.builder` (mavzular, raqam chizig'i, belgilar — 269 kafel `shrinkWrap`dan qutqarilgan). Statik `ListView(` 8 ekranda — chegaralangan kontent, muammo emas.
- **Rasm:** `QuestionImage` `cacheWidth` ni `image-sizes.json` nisbati va DPR dan hisoblaydi, `precacheImage` xuddi shu kenglik bilan — dekod ikki marta bo'lmaydi; kesh 40 MB/60 ta. Yaxshi.
- **Video:** bir vaqtda bitta `VideoPlayerController`, sahifa almashganda dispose; disk keshi yo'q (qayta ko'rish = qayta yuklash); preload siyosati — (b) №9.
- **Ilova hajmi (arm64 APK 78 MB):** `assets/tests-json/images` **46,3 MB** (750 WebP, o'rtacha 63 KB, faqat 1 ta >100 KB — qayta siqish chegarasiga yetilgan) + `belgilar_images` **4,6 MB** (195 GIF, 42 PNG, 32 JPG — WebP emas) + `barcha.json` 3,9 MB + themes/variants 0,4 MB + branding 0,6 MB ≈ **56 MB = APK ning ~72 %**. Kamaytirish yo'llari: (1) belgilar GIF/PNG → WebP (≈ −2,5 MB, arzon); (2) rasm kengligi 1280 → 960 px q55 (≈ −15 MB, sifat tekshiruvi bilan); (3) PRO biletlar rasmlarini on-demand yuklash (Play Asset Delivery `on-demand` yoki R2 CDN + `flutter_cache_manager`) — bepul pul (1 009 savol) bundle'da qoladi, APK ≈ 50 MB; (4) `barcha.json` dan `izoh` chiqarilsa (№4) −1 MB.
- **Xotira:** `didHaveMemoryPressure` → bank keshi tozalanadi; `largeHeap=true` — nega kerakligi hujjatlanmagan, 40 MB rasm keshi bilan kerak bo'lmasligi mumkin.
- **Tarmoq xarajati:** har `resume` 3–4 RPC (№12); `_refreshProfile` har `tokenRefreshed` da (soatiga 1) — maqbul.

## (e) Dizayn va matn

| Joy | Hozirgi | Taklif | Nega |
|---|---|---|---|
| Pastki menyu (`main_shell.dart:97-131`, `app_strings.dart:145,347,354`) | Asosiy · Bo'limlar · Test ishlash · Sozlamalar | Bosh sahifa · Bo'limlar · Test · Profil | Sayt `BottomNav.tsx:43-46` aynan shunday; 4-tab aslida profil+sozlamalar; «Test ishlash» 320 dp da ruschada siqiladi |
| Asosiy rang (`app_theme.dart:125-139`) | Tugma/faol tab ko'k `#3B82F6/#2563EB` gradient; `ink #131A45` faqat sarlavha fonida | Navigatsiya/sarlavha/faol holat — siyoh `#131A45`, bitta asosiy CTA ko'k (yoki yashil «Test ishlash» kabi) | Sayt brendi siyoh; ikki mahsulot bir oilaga o'xshashi kerak; kodda «ataylab ko'k» izohi bor — mahsulot qarori |
| Avtodrom kartasi (`avtodrom_card.dart:56-90`) | Sarlavha + «YANGI» bir qatorda, mashina uchun 150 px band | Belgi sarlavha ustida, mashina kengligi `maxWidth: 40 %` | 320–360 dp da sarlavha kesiladi (№1) |
| `ProGate` standart sarlavha (`pro_gate.dart:18`) | `'PRO funksiya'` qattiq o'zbekcha | `AppStrings.get('pro_feature', lang)` | 3 til; ruscha interfeysda o'zbekcha sarlavha chiqishi mumkin |
| `pro_perk_4` (uz_cyr) | «Админ кўмаги ва Premium гуруҳ» | «...ва PRO гуруҳ» | Mahsulotda «Premium» atamasi yo'q, faqat PRO |
| `home_subtitle` uz_lat | «Avtotestlar, yo'l belgilari va 64 variant» | «Avto testlar...» yoki «Imtihon testlari, yo'l belgilari...» | «Avtotestlar» eski brend nomiga o'xshaydi (sayt `home.heroSubtitle` bilan solishtirish) |
| 3 til pariteti | 389 kalit, uchala tilda to'liq (skript bilan tekshirildi; 17 `sources_*` kaliti `"uz_lat"` qo'shtirnoqda — faqat uslub) | Qo'shtirnoqni yagona uslubga keltirish | Parite skriptlari va `grep` lar chalg'imasin |
| Bo'sh/xato holatlar | Test: loading/xato/bo'sh; Avtodrom sim: oflayn + qayta urinish; PRO: tariflar xatosi + qayta; paywall: xato + qayta | PRO gate'da oflaynda «Internet yo'q» (paywall emas) | №5 ssenariysi |
| Bepul variant yorlig'i | 1–5 «bepul» belgisi | Saytga moslab 1–3 | №3 |
| Real imtihon ekrani | 17 qattiq rang (ataylab, ikkala rejimda bir xil) | O'zgartirilmaydi | Oldingi audit qarori |

## (f) Sayt–ilova muvofiqlik jadvali

| Funksiya | Sayt | Ilova | Izoh |
|---|---|---|---|
| Test ishlash (tasodifiy 20) | ✔ `/test-ishlash` | ✔ Test tabi | Bir xil |
| Variantlar (64) | ✔ bepul 1–3 (1 = v59) | ✔ bepul 1–5 (v1–v5) | **Farq** — №3 |
| Mavzuli (34) | ✔ | ✔ bepul 1, 2 | Saytda mavzu qulfi kodda topilmadi — tekshirish kerak |
| Real imtihon (20/25 daq, bepul/PRO pul) | ✔ variant 97 | ✔ variant 97, `free-*.json` manbasi | Bir xil |
| Xatolar ustida ishlash / Xatolar testi | ✔ `/xatolarim`, `/xatolar-testi` | ✔ ErrorsScreen + natija ekranidagi «Xatolar testi» | Ilovada mahalliy (prefs) + `record_question_answers` |
| Qiyin savollar | ✔ | ✔ variant 98 | Bir xil |
| Saqlangan | ✔ | ✔ | Ilovada mahalliy — hisobga bog'lanmagan (sinxron yo'q) |
| Qidirish | ✔ | ✔ (+ `/savol/slug` deep link) | Bir xil |
| Belgilar | ✔ 252 ta yopiq tavsif, `/belgilar/:slug` | ✔ faqat kod + nom (`road_sign.dart`) | **Ilovada tavsif yo'q** — saytdagi JSON ni qayta ishlatish mumkin |
| Avtodrom | ✔ jadval + simulyator | ✔ jadval + simulyator (WebView, landscape) | Bir xil; WebView oflaynda xabar beradi |
| Yodlash kerak | ✔ | ✔ `assets/data/yodlash.json` | Bir xil manba |
| Darslik (11 modul video) | ✔ `/darslik` | ✘ | Ilovaga qo'shish oson (`darslik-videos.json` + `video_player`) |
| Animatsiya (301) | ✔ PRO, 2 namuna | ✔ bir xil indeks, 2 namuna, Data Saver | Bir xil |
| PRO taklifi joylari | `ProOfferSheet` (variant boshlash sahifasi) | 9 joy: bosh (2), profil, test, mavzu, variant, izoh, paywall, deep link | Ilovada taklif ekrani to'liq (`ProScreen`), saytdagi engil sheet yo'q |
| To'lov | Payme, Click | Payme, Click (WebView yoki tashqi ilova), Telegram | Ilovada `ProviderAppLauncher` — qo'shimcha |
| Kirish | telefon, Google, **Telegram** | telefon, Google | Telegram login ilovada yo'q |
| Profil: natijalar, tayyorgarlik, mavzu statistikasi | ✔ | ✔ (+ kunlik savol push, matn o'lchami, hisobni o'chirish) | Ilova to'liqroq |
| Yangiliklar, e-avtomaktab, YHQ, prava-olish, hamkor, contact | ✔ (SEO sahifalar) | ✘ | Saytga xos; ilovada kerak emas |
| Yangilanish | — | ✔ Play in-app update | Ilovaga xos |
| Deep link | — | ✔ (`assetlinks.json` hali saytda yo'q) | Oldingi audit №35 ochiq |

**Qanday bo'lishi kerak.** *Ikkalasida bir xil (yadro):* savollar bazasi va versiyasi, bepul/PRO qoidalari (`FreeAccess` ↔ `variantAccess.ts` — bitta manba: Supabase `app_config` yoki build vaqtida generatsiya), PRO narxi (`payme_plans`), natijalar/tayyorgarlik (Supabase), animatsiya indeksi, belgi tavsiflari, atamalar (Tun rejimi, PRO olish, Xatolar ustida ishlash). *Ilovaga xos:* oflayn bank, push eslatma, in-app update, tashqi to'lov ilovalari, Data Saver, matn o'lchami. *Saytga xos:* SEO sahifalar (savol/slug, yangiliklar, prava-olish, e-avtomaktab), desktop ilova, hamkor. *Keyin ikkalasiga:* Telegram login, saqlangan savollarni hisobga bog'lash.

## (g) Ish rejasi va AI promptlari

**1-hafta — reliz to'siqlari (kodga tegmay bo'lmaydi):**
1. Versiya: `app_version.dart` → 1.0.18/18. *Prompt:* «`lib/config/app_version.dart` ni `pubspec.yaml` versiyasiga (1.0.18+18) moslashtir, `flutter test test/app_version_test.dart` o'tsin.»
2. Avtodrom kartasi overflow. *Prompt:* «`lib/widgets/avtodrom_card.dart` da sarlavha+«YANGI» qatori 320 dp da 308 px overflow beradi: sarlavhani `Flexible`+`FittedBox` ga o'ra, belgini ikkinchi qatorga tushir, mashina rasmini kenglik bo'yicha chekla; `flutter test test/narrow_screen_test.dart` o'tsin; dizaynni saqla.»
3. Bepul variantlar sinxron. *Prompt:* «Saytdagi `src/lib/variantAccess.ts` (bepul [1,2,3]) bilan `lib/config/free_access.dart` ni moslashtir; 1-variant uchun qaysi fayl (v1 yoki v59) ishlatilishini egasi qaroriga ko'ra bir xil qil; `free_access_test.dart` ni yangila.»
4. `mounted` qo'riqlari (5 joy). *Prompt:* «`test_screen.dart:132,135`, `errors_screen.dart:147`, `saved_questions_screen.dart:71,101` — `await` dan keyin `if (!mounted) return;` qo'sh; boshqa mantiqqa tegma.»

**2-hafta — PRO ishonchliligi:**
5. PRO holatini diskka yozish + grace. *Prompt:* «`SubscriptionProvider` ga oxirgi `UserAccessState` (+`expiresAt`, saqlangan vaqt) ni SharedPreferences da saqlash/o'qishni qo'sh; sovuq startda keshdagi javob `resolved` hisoblansin va fonda yangilansin; 7 kundan eski kesh e'tiborsiz; `subscription_state_test.dart` ga 3 test qo'sh (kesh bor/oflayn, kesh eskirgan, chiqishda tozalash).»
6. Izoh himoyasi (sayt bilan birga). *Prompt:* «Supabase'da `get_question_izoh(p_global_id)` RPC yarat: `get_user_access_state` `active_pro` bo'lsa `izoh` ni qaytarsin; ilovada `ExplanationPanel` shu RPC + mahalliy shifrlangan kesh ishlatsin; `tools/gen_data.py` da mobil `barcha.json` dan `izoh` ni olib tashla. Migratsiya tartibi: avval RPC, keyin ilova relizi, keyin JSON.»
7. To'lov tekshiruvi chegarasi. *Prompt:* «`SubscriptionProvider.pollForActivation` ni umumiy 25 s devor-soat bilan chekla (`Future.any`/deadline), `_VerifyingDialog` ga «Keyinroq tekshirish» tugmasi qo'sh; `watchForActivation` o'zgarmasin.»
8. `_launchInProgress` bayrog'i. *Prompt:* «`guarded_test_launcher.dart` da `_launchInProgress` ni `try/finally` butun funksiyani qamrab olsin.»

**3-hafta — ishlash va trafik:**
9. Video preload siyosati. *Prompt:* «`question_media.dart` `_preload` faqat `connectivity_plus` Wi-Fi/ethernet bo'lsa va faqat faol sahifada ishlasin; mobil tarmoqda javobdan keyin yuklansin; 8 s timeout'da `_phase = image` qil.»
10. `resume` da bitta refresh. *Prompt:* «`ProGate`, `PremiumAccessGate`, `ProScreen` dagi `resumed` ishlovchilarini `refresh()` (majburiy emas) ga o'tkaz, majburiy faqat `AuthGate` da qolsin; `PremiumAccessGate` dagi bo'sh `_onAccessAttempt` va observer'ni olib tashla.»
11. Hajm: belgilar WebP. *Prompt:* «`assets/tests-json/belgilar_images` dagi 195 GIF/42 PNG/32 JPG ni WebP q80 ga aylantir (`cwebp`), `belgilar.json` yo'llarini yangila, `question_assets_test` o'tsin; oldin/keyin hajmni hisobotga yoz.»
12. Hajm: PRO rasmlarini on-demand (mahsulot qarori keyin). *Prompt:* «1 009 bepul savol rasmlari bundle'da qolsin, qolgan ~250 ta PRO rasm R2 CDN dan `flutter_cache_manager` bilan yuklansin (oflayn fallback: `image-sizes.json` o'lchamida placeholder); `QuestionImage` ga manba abstraksiyasi qo'sh.»

**4-hafta — muvofiqlik va tozalash:**
13. Pastki menyu nomlari va `ProGate` sarlavhasi. *Prompt:* «`nav_home`→«Bosh sahifa», `nav_settings`→«Profil», `menu_test`→«Test» (3 tilda, sayt `BottomNav.tsx` bilan bir xil); `ProGate.featureTitle` standart qiymatini `AppStrings` kaliti qil.»
14. Belgi tavsiflari. *Prompt:* «Saytdagi 252 belgi tavsifi JSON ini (`src/data/...`) ilovaga `assets/data/belgilar_tavsif.json` sifatida generatsiya qil (`tools/gen_data.py`), `RoadSign` modeliga `description` qo'sh, belgi bosilganda sheet'da ko'rsat.»
15. Darslik videolari. *Prompt:* «`src/data/darslik-videos.json` (11 modul) asosida ilovaga `DarslikScreen` qo'sh — ro'yxat + `video_player`/YouTube havola, PRO qoidasi saytdagidek; Bo'limlar tabining «Ma'lumotnoma» guruhiga joylashtir.»
16. Refaktor + testlar. *Prompt:* «`TestScreen` va `RealExamScreen` dagi raqamlar chizig'i va javob kafelini `widgets/question_strip.dart`, `widgets/answer_tile.dart` ga chiqar (ko'rinish o'zgarmasin); `TestScreen` uchun javob→avto-o'tish→natija widget-testi, `PaymeCheckoutScreen._handleNavigation` uchun unit-test yoz.»

## 9. Oldingi audit (2026-10-29) holati

№1–34, 36–38 — tuzatilgan holda turibdi (kodda tasdiqlandi: `get_pro`=«PRO olish», ⚙ menyu, `AutoAdvanceScheduler`, timeout'lar, flexible update, deep link). **№35 `assetlinks.json`** — hali saytda yo'q (ilovadagi `autoVerify` intent-filter ishlamaydi). Ochiq savollar 2–6 o'zgarmagan; ilk ochilish vaqti hali o'lchanmagan.

## 10. Qo'lda tekshirish (haqiqiy telefon, reliz oldidan)

- [ ] 320 dp (yoki «Kichik ekran» rejimi) — bosh ekran Avtodrom kartasi sarlavhasi to'liq ko'rinadi
- [ ] PRO hisob, parvoz rejimi, ilovani o'chirib-yoqish — qaysi xabar chiqadi (paywall emas, «internet yo'q» bo'lishi kerak)
- [ ] Mobil internet + Data Saver o'chiq — test ochilganda Network Profiler'da video so'rovlari qachon boshlanadi
- [ ] Click to'lovi tashqi ilovada → qaytish → «faollashdi» dialogi bir marta
- [ ] Avtodrom simulyatori: landscape, chiqish tasdig'i, fonga o'tganda ovoz
- [ ] Ilova haqida → versiya 1.0.18
