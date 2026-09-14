import 'package:avtotest_app/config/free_access.dart';
import 'package:avtotest_app/providers/theme_provider.dart';
import 'package:avtotest_app/services/question_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The free/PRO line is a business rule, not a layout detail: if it drifts,
/// either paying users were charged for nothing or the whole bank leaked.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('exam tickets', () {
    test('the first five are free, the rest are not', () {
      for (var n = 1; n <= 5; n++) {
        expect(FreeAccess.isVariantFree(n), isTrue, reason: 'variant $n');
      }
      for (var n = 6; n <= 63; n++) {
        expect(FreeAccess.isVariantFree(n), isFalse, reason: 'variant $n');
      }
    });

    test('nonsense ticket numbers are not free', () {
      expect(FreeAccess.isVariantFree(0), isFalse);
      expect(FreeAccess.isVariantFree(-1), isFalse);
    });

    test('the free tickets actually exist in the bundle', () {
      final files = QuestionService.getVariantFiles();
      for (var n = 1; n <= FreeAccess.freeVariantCount; n++) {
        expect(files, contains('v$n.json'));
      }
    });
  });

  group('topics', () {
    test('exactly the two starter topics are free', () {
      expect(FreeAccess.isTopicFree('1'), isTrue);
      expect(FreeAccess.isTopicFree('2'), isTrue);
      expect(FreeAccess.freeTopicIds.length, 2);
    });

    test('everything else needs PRO — including "all questions"', () {
      final locked = QuestionService.getTopics()
          .where((t) => !FreeAccess.isTopicFree(t.id))
          .map((t) => t.id)
          .toList();

      expect(locked, contains('31'), reason: 'the whole bank must stay PRO');
      expect(locked, contains('35a'));
      expect(locked.length, QuestionService.getTopics().length - 2);
    });

    test('the free ids match real topics', () {
      final ids = QuestionService.getTopics().map((t) => t.id).toSet();
      for (final id in FreeAccess.freeTopicIds) {
        expect(
          ids,
          contains(id),
          reason: 'free topic "$id" is not in the topic list',
        );
      }
    });

    test('they are the two the labels promise', () {
      final topics = QuestionService.getTopics();
      final free = topics.where((t) => FreeAccess.isTopicFree(t.id)).toList();
      expect(free.map((t) => t.getName('uz_lat')), [
        'Umumiy qoidalar',
        'Haydovchining umumiy vazifalari',
      ]);
    });
  });

  group('ThemeProvider', () {
    test('defaults to dark when nothing was ever chosen', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = ThemeProvider();
      expect(provider.isDark, isTrue, reason: 'before init');
      await provider.init();
      expect(provider.mode, ThemeMode.dark);
    });

    test('an explicit light choice survives a restart', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
      final provider = ThemeProvider();
      await provider.init();
      expect(provider.isDark, isFalse);
    });

    test('toggling persists the new choice', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = ThemeProvider();
      await provider.init();
      await provider.toggle();
      expect(provider.isDark, isFalse);

      final reopened = ThemeProvider();
      await reopened.init();
      expect(
        reopened.isDark,
        isFalse,
        reason: 'the light choice did not survive',
      );
    });
  });
}
