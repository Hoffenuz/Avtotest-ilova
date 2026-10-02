# Google orqali kirish (Android) — sozlash

Ilova avval telefonning o'zidagi Google akkaunt oynasini ochadi (brauzersiz,
Credential Manager). Bu ishlashi uchun Google Cloud'da **Android OAuth mijozi**
bo'lishi shart. Bo'lmasa ilova avtomatik ravishda eski usulga — brauzer orqali
kirishga — o'tadi (u ayrim telefonlarda ilovaga qaytmaydi).

## Kerakli qiymatlar

| Nima | Qiymat |
|---|---|
| Google Cloud loyihasi | Supabase'dagi Google provider mijozi bilan BIR XIL loyiha (Web client: `272991925832-vithrtfh5iobm30fqkeb9dldvfvdnsvn.apps.googleusercontent.com`) |
| Package name | `com.hoffenuz.Avtotestu` |
| SHA-1 (yuklash kaliti — o'zimiz yig'gan APK/AAB) | `13:AC:37:47:4A:90:D8:35:22:46:9A:30:25:47:0D:8C:06:A4:46:96` |
| SHA-1 (Google Play imzo kaliti — Play'dan o'rnatilgan ilova) | Play Console → Test and release → **App integrity** → App signing → "App signing key certificate" → SHA-1 |

## Qadamlar

1. https://console.cloud.google.com → yuqoridagi loyihani tanlang.
2. **APIs & Services → Credentials → Create credentials → OAuth client ID**.
3. Application type: **Android**.
   - Name: `AvtoSmart Android (upload)`
   - Package name: `com.hoffenuz.Avtotestu`
   - SHA-1: yuklash kaliti qiymati (jadvaldagi).
   - **Create**.
4. 3-qadamni yana bir marta takrorlang, SHA-1 o'rniga **Play imzo kaliti**ning
   SHA-1 qiymatini kiriting (name: `AvtoSmart Android (Play)`).
5. Supabase'da hech narsa o'zgartirish kerak emas: ilova Web client ID bilan
   token so'raydi, Supabase aynan shu mijozni taniydi.

Android mijozlari yaratilgandan keyin bir necha daqiqada ishlay boshlaydi.
Ilovada "Google bilan davom etish" bosilganda telefonning akkauntlar ro'yxati
pastdan chiqadi — bitta bosish bilan kiriladi.
