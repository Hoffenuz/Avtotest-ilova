import 'package:avtotest_app/services/auto_advance_scheduler.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

/// Avto-o'tish video ustidan «sakrab» ketmasligi kerak: video bor savolda
/// amal video tugaguncha kutadi, keyin 0,7 s dan so'ng bajariladi. Video
/// bo'lmasa — oddiy kechikish.
void main() {
  test('video yo\'q — oddiy kechikish bilan o\'tadi', () {
    fakeAsync((async) {
      final s = AutoAdvanceScheduler();
      var fired = 0;
      s.schedule(
        () => fired++,
        delay: const Duration(milliseconds: 1200),
        waitForAnimation: false,
      );
      async.elapse(const Duration(milliseconds: 1199));
      expect(fired, 0);
      async.elapse(const Duration(milliseconds: 1));
      expect(fired, 1);
      expect(s.isScheduled, isFalse);
    });
  });

  test('video bor — tugaguncha kutadi, keyin +0,7 s', () {
    fakeAsync((async) {
      final s = AutoAdvanceScheduler();
      var fired = 0;
      s.schedule(
        () => fired++,
        delay: const Duration(milliseconds: 1200),
        waitForAnimation: true,
      );
      // Kechikish o'tib ketsa ham video tugamaguncha o'tmaydi
      async.elapse(const Duration(seconds: 30));
      expect(fired, 0);
      expect(s.isWaitingForAnimation, isTrue);

      s.onAnimationDone();
      expect(s.isWaitingForAnimation, isFalse);
      async.elapse(AutoAdvanceScheduler.afterAnimationDelay -
          const Duration(milliseconds: 1));
      expect(fired, 0);
      async.elapse(const Duration(milliseconds: 1));
      expect(fired, 1);
    });
  });

  test('kutish yo\'q bo\'lsa onAnimationDone hech narsa qilmaydi', () {
    fakeAsync((async) {
      final s = AutoAdvanceScheduler();
      s.onAnimationDone();
      async.elapse(const Duration(seconds: 5));
      expect(s.isScheduled, isFalse);
    });
  });

  test('cancel — kutish ham, taymer ham bekor', () {
    fakeAsync((async) {
      final s = AutoAdvanceScheduler();
      var fired = 0;
      s.schedule(
        () => fired++,
        delay: const Duration(milliseconds: 500),
        waitForAnimation: true,
      );
      s.cancel();
      s.onAnimationDone();
      async.elapse(const Duration(seconds: 5));
      expect(fired, 0);

      s.schedule(
        () => fired++,
        delay: const Duration(milliseconds: 500),
        waitForAnimation: false,
      );
      s.cancel();
      async.elapse(const Duration(seconds: 5));
      expect(fired, 0);
    });
  });

  test('yangi reja eskisini almashtiradi', () {
    fakeAsync((async) {
      final s = AutoAdvanceScheduler();
      var first = 0, second = 0;
      s.schedule(
        () => first++,
        delay: const Duration(milliseconds: 500),
        waitForAnimation: true,
      );
      s.schedule(
        () => second++,
        delay: const Duration(milliseconds: 500),
        waitForAnimation: false,
      );
      s.onAnimationDone();
      async.elapse(const Duration(seconds: 5));
      expect(first, 0);
      expect(second, 1);
    });
  });

  test('onAnimationDone faqat bir marta ishlaydi', () {
    fakeAsync((async) {
      final s = AutoAdvanceScheduler();
      var fired = 0;
      s.schedule(
        () => fired++,
        delay: Duration.zero,
        waitForAnimation: true,
      );
      s.onAnimationDone();
      s.onAnimationDone();
      async.elapse(const Duration(seconds: 5));
      expect(fired, 1);
    });
  });
}
