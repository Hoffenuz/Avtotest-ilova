# AvtoSmart — Google Play uchun production app bundle (.aab) yig'ish.
#
# Loyiha ildizidan ishga tushiring:
#   powershell -ExecutionPolicy Bypass -File tools\build_release.ps1
#
# Toza qayta qurish uchun (kamdan-kam kerak, sekinroq):
#   powershell -ExecutionPolicy Bypass -File tools\build_release.ps1 -Clean
#
# NEGA SKRIPT: release yig'ishda tartib muhim. Versiya pubspec.yaml va
# lib/config/app_version.dart da bir xil bo'lishi shart (test buni tekshiradi),
# key.properties bo'lmasa build debug kalit bilan imzolanib Play tomonidan
# rad etiladi. Qadamlarni qo'lda terganda shulardan biri unutiladi.

param([switch]$Clean)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

function Step($name) {
    Write-Host ''
    Write-Host "==> $name" -ForegroundColor Cyan
}

function Fail($message) {
    Write-Host ''
    Write-Host "XATO: $message" -ForegroundColor Red
    exit 1
}

# --- 0. Imzolash kaliti -------------------------------------------------
# android/app/build.gradle.kts key.properties bo'lmasa release yig'ishni
# ataylab to'xtatadi. Buni shu yerda tekshirish Gradle 3 daqiqa ishlab
# turgandan keyin yiqilishidan yaxshiroq.
if (-not (Test-Path 'android\key.properties')) {
    Fail 'android\key.properties topilmadi. Usiz build debug kalit bilan imzolanadi va Play uni rad etadi.'
}

# --- 1. Versiya -----------------------------------------------------------
$pubspec = Get-Content 'pubspec.yaml' -Raw
if ($pubspec -notmatch '(?m)^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)\s*$') {
    Fail 'pubspec.yaml ichidan version: satrini o''qib bo''lmadi.'
}
$versionName = $Matches[1]
$versionCode = $Matches[2]
Write-Host "Versiya: $versionName ($versionCode)" -ForegroundColor Green

# --- 1b. local.properties versiyasini majburan moslash --------------------
# android/local.properties dagi flutter.versionCode / flutter.versionName ni
# faqat `flutter build` / `flutter run` yozadi — `pub get` tegmaydi. Bu skript
# gradle'ni TO'G'RIDAN-TO'G'RI chaqiradi (bosqich 6 dagi izohga qarang), shuning
# uchun oldingi bir `flutter build apk` dan qolgan ESKI versiya shu faylda
# tiqilib qolishi mumkin va Gradle undan foydalanadi (build.gradle.kts:
# `versionCode = flutter.versionCode`), pubspec.yaml dagi yangisidan emas.
# Play Console buni "version code allaqachon ishlatilgan" deb rad etadi —
# aab muvaffaqiyatli yig'ilgandan keyin ham. Shu ikki qatorni har build'da
# pubspec.yaml bilan tenglab qo'yish shu xatoni butunlay yo'q qiladi.
$localProps = 'android\local.properties'
if (-not (Test-Path $localProps)) {
    Fail "$localProps topilmadi. Avval bir marta 'flutter pub get' yoki 'flutter run' ishga tushiring."
}
$propLines = Get-Content $localProps | Where-Object {
    $_ -notmatch '^flutter\.versionCode=' -and $_ -notmatch '^flutter\.versionName='
}
$propLines += "flutter.versionCode=$versionCode"
$propLines += "flutter.versionName=$versionName"
Set-Content -Path $localProps -Value $propLines
Write-Host "local.properties -> flutter.versionCode=$versionCode, flutter.versionName=$versionName" -ForegroundColor DarkGray

# --- 2. Tozalash (ixtiyoriy) ---------------------------------------------
if ($Clean) {
    Step 'flutter clean'
    flutter clean
    if ($LASTEXITCODE -ne 0) { Fail 'flutter clean muvaffaqiyatsiz.' }
}

# --- 3. Paketlar ----------------------------------------------------------
Step 'flutter pub get'
flutter pub get
if ($LASTEXITCODE -ne 0) { Fail 'flutter pub get muvaffaqiyatsiz.' }

# --- 4. Statik tahlil -----------------------------------------------------
# Bu yerda to'xtatmaymiz: lint ogohlantirishi release chiqarishga to'sqinlik
# qilmasligi kerak. Lekin ko'rinmay qolmasligi ham kerak.
Step 'flutter analyze'
flutter analyze
if ($LASTEXITCODE -ne 0) {
    Write-Host 'DIQQAT: flutter analyze muammo topdi (yuqoriga qarang). Build davom etmoqda.' -ForegroundColor Yellow
}

# --- 5. Testlar -----------------------------------------------------------
# app_version_test.dart pubspec.yaml va lib/config/app_version.dart mosligini
# tekshiradi. Bu yerda yiqilsa — versiya raqami ikkala faylda bir xil emas.
Step 'flutter test'
flutter test
if ($LASTEXITCODE -ne 0) { Fail 'Testlar muvaffaqiyatsiz. Versiya raqami pubspec.yaml va lib/config/app_version.dart da mos kelmayotgan bo''lishi mumkin.' }

# --- 6. Bundle ------------------------------------------------------------
# `flutter build appbundle` emas, to'g'ridan-to'g'ri Gradle: shu mashinada
# Android SDK yo'lida bo'sh joy bor (...\Vosster PC\...), va Flutter'ning
# o'zi bajaradigan qo'shimcha native-library strip qadami shu bo'sh joyda
# yiqiladi ("failed to strip debug symbols"). Gradle'ning o'z bundleRelease
# vazifasi buni muammosiz bajaradi — natija bir xil .aab.
Step 'gradlew bundleRelease'
Push-Location android
& .\gradlew.bat bundleRelease
$gradleExit = $LASTEXITCODE
Pop-Location
if ($gradleExit -ne 0) { Fail 'Bundle yig''ilmadi.' }

$aab = 'build\app\outputs\bundle\release\app-release.aab'
if (-not (Test-Path $aab)) { Fail "Kutilgan fayl topilmadi: $aab" }

# --- 7. AAB ichidagi versiyani tekshirish ----------------------------------
# Play "Version code N has already been used" deb rad etadigan holat — fayl
# yig'ilgan, lekin ichida eski versiya — shu yerda ushlanadi, yuklashdan oldin.
# Manifest AAB ichida protobuf; `versionCode` atributidan keyin qiymat
# 0x1A <uzunlik> <raqamlar> ko'rinishida turadi.
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path $aab).Path)
try {
    $entry = $zip.GetEntry('base/manifest/AndroidManifest.xml')
    $ms = New-Object System.IO.MemoryStream
    $stream = $entry.Open(); $stream.CopyTo($ms); $stream.Close()
    $text = [System.Text.Encoding]::GetEncoding('ISO-8859-1').GetString($ms.ToArray())
} finally { $zip.Dispose() }
if ($text -notmatch 'versionCode\x1a.([0-9]+)') { Fail 'AAB manifestidan versionCode o''qib bo''lmadi.' }
$builtCode = $Matches[1]
if ($builtCode -ne $versionCode) {
    Fail "AAB ichida versionCode=$builtCode, pubspec.yaml da $versionCode. Bu fayl Play'ga yuklanmasin."
}
Write-Host "AAB tekshirildi: versionCode=$builtCode" -ForegroundColor Green

$sizeMb = [math]::Round((Get-Item $aab).Length / 1MB, 1)
$full = (Resolve-Path $aab).Path

Write-Host ''
Write-Host '=====================================================' -ForegroundColor Green
Write-Host " TAYYOR - AvtoSmart $versionName ($versionCode)" -ForegroundColor Green
Write-Host " $full" -ForegroundColor Green
Write-Host " Hajmi: $sizeMb MB" -ForegroundColor Green
Write-Host '=====================================================' -ForegroundColor Green
Write-Host ''
Write-Host 'Keyingi qadam: Play Console -> Production -> Create new release -> shu .aab faylni yuklang.'
