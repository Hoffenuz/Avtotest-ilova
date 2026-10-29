import 'package:avtotest_app/services/anim_demo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bepul foydalanuvchining animatsiya namunasi: 2 ta, savol kaliti bo'yicha,
/// takror savol yangi namuna sarflamaydi. Bu biznes qoidasi — ko'p bo'lsa
/// PRO bekor, kam bo'lsa namuna ma'nosini yo'qotadi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    AnimDemo.resetForTest();
    SharedPreferences.setMockInitialValues({});
    await AnimDemo.load();
  });

  test('limit 2 ta', () {
    expect(AnimDemo.limit, 2);
  });

  test('birinchi ikki savol — namuna 1 va 2, uchinchisi — yo\'q', () {
    expect(AnimDemo.allowed('u1uz'), isTrue);
    expect(AnimDemo.consume('u1uz'), 1);
    expect(AnimDemo.allowed('u2uz'), isTrue);
    expect(AnimDemo.consume('u2uz'), 2);
    expect(AnimDemo.allowed('u3uz'), isFalse);
    expect(AnimDemo.consume('u3uz'), 0);
  });

  test('o\'sha savol qayta ochilsa yangi namuna sarflanmaydi', () {
    expect(AnimDemo.consume('u1uz'), 1);
    expect(AnimDemo.consume('u1uz'), 1);
    expect(AnimDemo.used, 1);
    expect(AnimDemo.allowed('u1uz'), isTrue);
    // Ikkinchi o'rin hali bo'sh
    expect(AnimDemo.allowed('u2uz'), isTrue);
  });

  test('limit to\'lgandan keyin ham ko\'rilgan savollar ochiq qoladi', () {
    AnimDemo.consume('u1uz');
    AnimDemo.consume('u2uz');
    expect(AnimDemo.allowed('u1uz'), isTrue);
    expect(AnimDemo.allowed('u2uz'), isTrue);
    expect(AnimDemo.allowed('u3uz'), isFalse);
  });

  test('bo\'sh kalit — namuna emas', () {
    expect(AnimDemo.allowed(null), isFalse);
    expect(AnimDemo.allowed(''), isFalse);
    expect(AnimDemo.consume(null), 0);
    expect(AnimDemo.used, 0);
  });

  test('hisob qurilmada saqlanadi va qayta yuklanadi', () async {
    AnimDemo.consume('u1uz');
    // SharedPreferences yozuvi fon rejimida — bir aylanish kutamiz
    await Future<void>.delayed(Duration.zero);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(AnimDemo.prefsKey), ['u1uz']);

    AnimDemo.resetForTest();
    await AnimDemo.load();
    expect(AnimDemo.used, 1);
    expect(AnimDemo.consume('u1uz'), 1);
  });
}
