import 'package:avtotest_app/services/animation_index_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Animatsiya indeksi: kalit, URL va kesh muddati. Indeks tuzilmasi yoki
/// kalit qoidasi buzilsa video hech bir savolga ulanmaydi — jim, xatosiz,
/// shuning uchun testda ushlanadi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sample =
      '{"version":1,"videos":{"u1003uz":"u1003uz.8a77af85.mp4","u60uz":"u60uz.afb56bba.mp4"}}';

  setUp(() {
    AnimationIndexService.resetForTest();
    SharedPreferences.setMockInitialValues({});
  });

  group('kalit', () {
    test('rasm nomidan kengaytma olinadi', () {
      expect(AnimationIndexService.keyFor('u1003uz.webp'), 'u1003uz');
      expect(AnimationIndexService.keyFor('u63-11.webp'), 'u63-11');
    });

    test('papka va so\'rov qismi tashlanadi', () {
      expect(
        AnimationIndexService.keyFor('images/u1003uz.webp?v=2'),
        'u1003uz',
      );
    });

    test('bo\'sh yoki null — null', () {
      expect(AnimationIndexService.keyFor(null), isNull);
      expect(AnimationIndexService.keyFor('  '), isNull);
    });
  });

  group('URL', () {
    test('indeks yo\'q — hech qanday URL yo\'q (funksiya o\'chiq)', () {
      expect(AnimationIndexService.isReady, isFalse);
      expect(AnimationIndexService.urlFor('u1003uz.webp'), isNull);
    });

    test('indeksdagi savol — to\'liq manzil, boshqasi — null', () {
      AnimationIndexService.setForTest(AnimationIndexService.parse(sample));
      expect(
        AnimationIndexService.urlFor('u1003uz.webp'),
        'https://media.avtotestu.uz/animatsiya/u1003uz.8a77af85.mp4',
      );
      expect(AnimationIndexService.urlFor('u999uz.webp'), isNull);
      expect(AnimationIndexService.urlFor(null), isNull);
    });

    test('tuzilmasi boshqa JSON (SPA fallback) — null', () {
      expect(AnimationIndexService.parse('<html></html>'), isNull);
      expect(AnimationIndexService.parse('{"version":1}'), isNull);
      expect(AnimationIndexService.parse('[]'), isNull);
    });
  });

  group('kesh muddati', () {
    final now = DateTime(2026, 10, 29, 12);

    test('24 soatdan yangi — eski emas', () {
      final at = now.subtract(const Duration(hours: 23)).millisecondsSinceEpoch;
      expect(AnimationIndexService.isStale(at, now: now), isFalse);
    });

    test('24 soatdan eski yoki yo\'q — qayta so\'raladi', () {
      final at = now.subtract(const Duration(hours: 25)).millisecondsSinceEpoch;
      expect(AnimationIndexService.isStale(at, now: now), isTrue);
      expect(AnimationIndexService.isStale(null, now: now), isTrue);
    });

    test('yangi kesh bo\'lsa tarmoqqa chiqilmaydi', () async {
      SharedPreferences.setMockInitialValues({
        AnimationIndexService.prefsJsonKey: sample,
        AnimationIndexService.prefsFetchedAtKey: now
            .subtract(const Duration(hours: 1))
            .millisecondsSinceEpoch,
      });
      var fetched = 0;
      await AnimationIndexService.load(
        fetch: () async {
          fetched++;
          return null;
        },
        now: () => now,
      );
      expect(fetched, 0);
      expect(AnimationIndexService.count, 2);
    });

    test('eski kesh — avval eskisi ishlaydi, keyin yangisi saqlanadi', () async {
      SharedPreferences.setMockInitialValues({
        AnimationIndexService.prefsJsonKey: sample,
        AnimationIndexService.prefsFetchedAtKey: now
            .subtract(const Duration(days: 2))
            .millisecondsSinceEpoch,
      });
      await AnimationIndexService.load(
        fetch: () async => '{"version":2,"videos":{"u1uz":"u1uz.aa.mp4"}}',
        now: () => now,
      );
      expect(AnimationIndexService.count, 1);
      expect(AnimationIndexService.urlFor('u1uz.webp'), endsWith('u1uz.aa.mp4'));
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getInt(AnimationIndexService.prefsFetchedAtKey),
        now.millisecondsSinceEpoch,
      );
    });

    test('tarmoq xatosi — eski indeks qoladi, xato otilmaydi', () async {
      SharedPreferences.setMockInitialValues({
        AnimationIndexService.prefsJsonKey: sample,
        AnimationIndexService.prefsFetchedAtKey: now
            .subtract(const Duration(days: 2))
            .millisecondsSinceEpoch,
      });
      await AnimationIndexService.load(
        fetch: () async => throw Exception('offline'),
        now: () => now,
      );
      expect(AnimationIndexService.count, 2);
    });

    test('kesh ham, tarmoq ham yo\'q — funksiya jim o\'chiq', () async {
      await AnimationIndexService.load(
        fetch: () async => null,
        now: () => now,
      );
      expect(AnimationIndexService.isReady, isFalse);
      expect(AnimationIndexService.urlFor('u1003uz.webp'), isNull);
    });
  });
}
