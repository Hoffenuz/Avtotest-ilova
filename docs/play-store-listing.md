# Google Play — do'kon tavsifi (Misleading Claims / davlat ma'lumoti uchun tuzatilgan)

## Nega ikkinchi marta rad etildi (2026-10-10)

Google'ning dalili — **`Full description (en-US)`** maydoni. U yerda hali ham ESKI matn turgan
("updated in accordance with the requirements of the State Traffic Safety Administration",
"2026 State Standards") — manba havolasi ham, ogohlantirish ham yo'q. Ya'ni yangi matn en-US
maydoniga tushmagan (yoki o'zgarish ko'rib chiqishga yuborilmagan).

Bundan tashqari oldingi matndagi havolalarning uchtasi yaroqsiz edi ("valid and functional" sharti):

| Havola | Holat |
|---|---|
| `https://e-avtotalim.uz` | DNS'da yo'q — sayt ochilmaydi |
| `https://yhxx.uz` | SSL sertifikat xatosi — brauzer ogohlantirish beradi |
| `https://lex.uz/acts/-3765833` | Bu VM 408-son (2018) qarori — **avtomaktablarni litsenziyalash**, "guvohnoma berish tartibi" emas |

Ular olib tashlandi, o'rniga ishlaydigan rasmiy manbalar qo'yildi: Hukumat portalidagi IIV sahifasi
(`gov.uz`) va Yagona interaktiv davlat xizmatlari portali (`my.gov.uz`). Barcha havolalar
2026-10-10 da tekshirildi (HTTP 200, sarlavha mos).

Raqamlar ham ilovaga moslandi: **64 variant** (eski matnda 63), **34 mavzu** (eski matnda 35).

## Play Console'da qadamlar

1. **Grow → Store presence → Main store listing**. Tepada til ro'yxatini oching:
   - **English (United States) – en-US** (default) → pastdagi **inglizcha** matn. Eng muhimi shu.
   - **Uzbek – uz** (bo'lsa) → o'zbekcha matn.
   - **Russian – ru-RU** (bo'lsa) → ruscha matn.
   - **Translations** bo'limida avtomatik (Google translated) tarjimalar bo'lsa — o'chiring yoki
     qo'lda almashtiring, ularda eski matn qolib ketadi.
2. Qisqa tavsifni ham har bir tilda almashtiring.
3. Skrinshotlarni yangilang: `avtosmart-brand/play-store/tayyor-v2/` (rasmlarda "rasmiy shartlarda"
   degan da'vo olib tashlangan, ostiga "davlat ilovasi emas" yozilgan).
4. Yangi AAB (manbalar ro'yxati tuzatilgan versiya) ni yuklang.
5. **Publishing overview → Send changes for review**. Saqlash yetmaydi — yuborish kerak.
6. Agar **Policy → App content** da "Government apps" savoli chiqsa: davlat bilan aloqasi yo'q.

---

## Short description (en-US, ≤ 80)

```
Avtotest practice: 64 exam-style variants and road signs. Not a government app.
```

## Full description — English (en-US)

```
AvtoSmart is an INDEPENDENT study app for practicing for the Uzbekistan driving licence theory test (avtotest).

DISCLAIMER: AvtoSmart is NOT a government app. It is not affiliated with, endorsed by, or acting on behalf of any government entity, including the Ministry of Internal Affairs of the Republic of Uzbekistan or its Road Traffic Safety Service, and it does not provide any government service. The official exam, registration and issuance of driving licences are carried out only by government authorities.

SOURCES OF GOVERNMENT INFORMATION (official):
• Road Traffic Rules — Cabinet of Ministers Resolution No. 172 of 12 April 2022 (National Database of Legislation): https://lex.uz/docs/-5953883
• Law "On Road Traffic" No. ZRU-900 of 19 January 2024: https://lex.uz/docs/-6764454
• Driver training and examination system — Cabinet of Ministers Resolution No. 676 of 25 October 2025: https://lex.uz/uz/docs/-7791514
• Ministry of Internal Affairs (Government Portal of Uzbekistan): https://gov.uz/en/iiv
• Exam application and driving licence services (Single Portal of Interactive Public Services): https://my.gov.uz
The questions, explanations and translations in the app are written by the AvtoSmart team for practice and do not replace the official documents. Rules may change — always check the original source above.

WHAT'S INSIDE
More than 1,250 practice questions on the road traffic rules, 64 exam-style variants and a collection of road signs. Works offline.

64 PRACTICE VARIANTS
Each variant follows the format of the theory test: 20 questions and a time limit. Every attempt is saved so you can see your progress.

34 TOPICS
Road signs, intersections, overtaking, stopping and parking, traffic lights, speed limits, road markings, first aid and more — practice each topic separately and focus on your weak spots.

ROAD SIGNS AND MARKINGS
All road signs with pictures and meanings, grouped and searchable.

MISTAKES REVIEW
Questions you answered wrong are collected automatically so you can practice them again. You can also bookmark questions.

DIFFICULT QUESTIONS
A special practice set built from the topics where people make the most mistakes.

EXPLANATIONS
Each question has an explanation of why the answer is correct and which rule it is based on.

THREE LANGUAGES
Uzbek (Latin and Cyrillic) and Russian. Switch at any time, even during a test.

PRO
Topic tests, all 64 variants and explanations for every question are available with a PRO subscription.

• No ads
• No internet required
• Results are linked to your account
• Dark mode

Questions and suggestions: Telegram @avtotestu_ad
Website: https://www.avtotestu.uz
```

---

## Qisqa tavsif — o'zbekcha (uz)

```
Avtotest: 64 variant, mavzuli testlar va yo'l belgilari. Davlat ilovasi emas.
```

## To'liq tavsif — o'zbekcha (uz)

```
AvtoSmart — haydovchilik guvohnomasi (prava) imtihoniga tayyorgarlik uchun MUSTAQIL avtotest ilovasi.

❗ OGOHLANTIRISH: AvtoSmart davlat ilovasi emas. U hech qanday davlat organi (O'zbekiston Respublikasi Ichki ishlar vazirligi, Yo'l harakati xavfsizligi xizmati va boshqalar) nomidan ish yuritmaydi, ularga tegishli emas va davlat xizmatlarini ko'rsatmaydi. Rasmiy imtihon, ro'yxatdan o'tish va guvohnoma berish faqat davlat organlari orqali amalga oshiriladi.

📚 DAVLAT MA'LUMOTI MANBALARI (rasmiy):
• Yo'l harakati qoidalari — Vazirlar Mahkamasining 2022-yil 12-apreldagi 172-son qarori (Qonunchilik ma'lumotlari milliy bazasi): https://lex.uz/docs/-5953883
• «Yo'l harakati to'g'risida» qonun (O'RQ-900, 2024-yil 19-yanvar): https://lex.uz/docs/-6764454
• Transport vositalarini boshqarish tizimi — Vazirlar Mahkamasining 2025-yil 25-oktyabrdagi 676-son qarori: https://lex.uz/uz/docs/-7791514
• Ichki ishlar vazirligi (Hukumat portali): https://gov.uz/uz/iiv
• Imtihonga ariza va haydovchilik guvohnomasi xizmatlari (Yagona interaktiv davlat xizmatlari portali): https://my.gov.uz
Ilovadagi savollar, izohlar va tarjimalarni AvtoSmart jamoasi mashq uchun tayyorlagan; ular rasmiy hujjat o'rnini bosmaydi. Qoidalar o'zgarishi mumkin — shubha tug'ilsa, asl manbaga qarang.

ILOVADA NIMA BOR
Yo'l harakati qoidalari bo'yicha 1250 dan ortiq mashq savoli, 64 ta variant va yo'l belgilari to'plami. Ilova internetsiz ham ishlaydi.

64 TA VARIANT
Har bir variant imtihon formatida: 20 ta savol va vaqt chegarasi. Har bir urinish natijasi saqlanadi — tayyorgarligingiz qanday o'sayotganini ko'rasiz.

34 TA MAVZU BO'YICHA AVTOTEST
Yo'l belgilari, chorrahalar, quvib o'tish, to'xtash va to'xtab turish, svetofor ishoralari, tezlik, yo'l chiziqlari, birinchi tibbiy yordam va boshqalar. Zaif mavzuni topib, faqat shuni mashq qilasiz.

YO'L BELGILARI VA CHIZIQLAR
Barcha yo'l belgilari rasmi va ma'nosi bilan, guruhlarga ajratilgan, qidiruv bor.

XATOLAR USTIDA ISHLASH
Xato javob bergan savollaringiz avtomatik yig'iladi va alohida qayta ishlanadi. Savollarni saqlab qo'yish ham mumkin.

QIYIN SAVOLLAR
Eng ko'p xato qilinadigan mavzulardan tuzilgan maxsus test.

IZOHLAR
Har bir savolga izoh: javob nima uchun to'g'ri va qoidaning qaysi bandiga asoslanadi.

UCH TILDA
O'zbekcha (lotin va kirill) hamda ruscha. Tilni istalgan paytda, hatto test ichida ham almashtirasiz.

PRO
Mavzuli testlar, barcha 64 variant va har bir savolga izoh PRO obuna bilan ochiladi.

• Reklama yo'q
• Internet shart emas
• Natijalar hisobingizga bog'lanadi
• Tungi rejim

Savol va takliflar: Telegram @avtotestu_ad
Sayt: https://www.avtotestu.uz
```

---

## Краткое описание — ru-RU

```
Автотест: 64 варианта, тесты по темам и знаки. Не государственное приложение.
```

## Полное описание — ru-RU

```
AvtoSmart — НЕЗАВИСИМОЕ приложение-автотест для подготовки к теоретическому экзамену на водительское удостоверение в Узбекистане.

❗ ОГОВОРКА: AvtoSmart не является государственным приложением. Оно не связано с государственными органами (Министерством внутренних дел Республики Узбекистан, Службой безопасности дорожного движения и др.), не действует от их имени и не оказывает государственных услуг. Официальный экзамен, регистрация и выдача удостоверения проходят только через государственные органы.

📚 ИСТОЧНИКИ ГОСУДАРСТВЕННОЙ ИНФОРМАЦИИ (официальные):
• Правила дорожного движения — постановление Кабинета Министров № 172 от 12 апреля 2022 года (Национальная база данных законодательства): https://lex.uz/docs/-5953883
• Закон «О дорожном движении» (ЗРУ-900 от 19 января 2024 года): https://lex.uz/docs/-6764454
• Система подготовки водителей и экзаменов — постановление Кабинета Министров № 676 от 25 октября 2025 года: https://lex.uz/uz/docs/-7791514
• Министерство внутренних дел (Правительственный портал): https://gov.uz/ru/iiv
• Заявление на экзамен и услуги по водительскому удостоверению (Единый портал интерактивных государственных услуг): https://my.gov.uz
Вопросы, пояснения и переводы в приложении подготовлены командой AvtoSmart для тренировки и не заменяют официальные документы. Правила могут меняться — при сомнениях обращайтесь к первоисточнику.

ЧТО ВНУТРИ
Более 1250 тренировочных вопросов по ПДД, 64 варианта и подборка дорожных знаков. Работает без интернета.

64 ВАРИАНТА
Каждый вариант в формате экзамена: 20 вопросов и ограничение по времени. Результаты сохраняются — вы видите свой прогресс.

АВТОТЕСТ ПО 34 ТЕМАМ
Знаки, перекрёстки, обгон, остановка и стоянка, светофор, скорость, разметка, первая помощь и другое. Находите слабую тему и тренируйте только её.

ДОРОЖНЫЕ ЗНАКИ И РАЗМЕТКА
Все знаки с картинкой и значением, по группам, с поиском.

РАБОТА НАД ОШИБКАМИ
Неверно отвеченные вопросы собираются автоматически. Вопросы можно сохранять.

СЛОЖНЫЕ ВОПРОСЫ
Отдельный тест из тем, где чаще всего ошибаются.

ПОЯСНЕНИЯ
К каждому вопросу — почему ответ верный и на какой пункт правил он опирается.

НА ТРЁХ ЯЗЫКАХ
Узбекский (латиница и кириллица) и русский. Язык можно сменить в любой момент.

PRO
Тесты по темам, все 64 варианта и пояснения к каждому вопросу — по подписке PRO.

• Без рекламы
• Интернет не обязателен
• Результаты привязаны к аккаунту
• Тёмная тема

Вопросы и предложения: Telegram @avtotestu_ad
Сайт: https://www.avtotestu.uz
```
