import 'package:avtotest_app/models/question.dart';
import 'package:avtotest_app/services/test_results_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// `test_results` is shared with avtotestu.uz, and the two clients write
/// `question_source` in different shapes. Every shape has to come back out as
/// something a person can read — the bug these cover is a result list showing
/// `v27.json` where it should say "Variant 27".
String label(String source, {String lang = 'uz_lat'}) {
  return TestResultsService.resolveLabel(
    type: 'topic', // deliberately the wrong guess: the resolver must recover
    testKey: source,
    fallback: '',
    lang: lang,
  );
}

void main() {
  group('website-written sources', () {
    test('an exam ticket resolves to its number', () {
      expect(label('v27.json'), 'Variant 27');
      expect(label('v1.json'), 'Variant 1');
      expect(label('v63.json'), 'Variant 63');
    });

    test('a topic resolves to its name, in the asked-for language', () {
      // The site prefixes topic ids with `t`.
      expect(label('t31.json'), 'Barcha savollar');
      expect(label('t31.json', lang: 'ru'), 'Все вопросы');
      expect(label('t35a.json'), 'Yangi savollar');
      expect(label('t1.json'), 'Umumiy qoidalar');
    });

    test('the mistakes drill resolves', () {
      expect(label('mistakes'), 'Xatolarim');
      expect(label('mistakes', lang: 'ru'), 'Мои ошибки');
    });
  });

  group('app-written sources', () {
    test('the app\'s own bare keys still resolve', () {
      expect(label('v27'), 'Variant 27');
      expect(label('31'), 'Barcha savollar');
      expect(label('35a'), 'Yangi savollar');
      // The one topic whose file is named, not numbered.
      expect(label('34tengaxamiyatli'), 'Teng ahamiyatli chorrahalar');
    });
  });

  group('never leaks a file name', () {
    test('an unrecognised source becomes a plain word', () {
      expect(label('something-else.json'), 'Test');
      expect(label('barcha-uz-lat.json'), 'Test');
      expect(label(''), 'Test');
    });

    test('no resolved label ever ends in .json', () {
      const sources = [
        'v27.json',
        't31.json',
        't35a.json',
        'mistakes',
        '34tengaxamiyatli',
        'free-ru.json',
        'unknown.json',
      ];
      for (final source in sources) {
        for (final lang in ['uz_lat', 'uz_cyr', 'ru']) {
          final resolved = label(source, lang: lang);
          expect(resolved, isNotEmpty, reason: source);
          expect(
            resolved.endsWith('.json'),
            isFalse,
            reason: '$source [$lang] leaked a file name: $resolved',
          );
        }
      }
    });

    test('a real title passed as the fallback is kept', () {
      expect(
        TestResultsService.resolveLabel(
          type: 'practice',
          testKey: 'unknown',
          fallback: '20 savollik test',
          lang: 'uz_lat',
        ),
        '20 savollik test',
      );
    });
  });

  group('the exam', () {
    test('is named, whichever bank it drew from', () {
      for (final source in ['barcha-uz-lat.json', 'free-ru.json']) {
        expect(
          TestResultsService.resolveLabel(
            type: 'exam',
            testKey: source,
            fallback: '',
            lang: 'uz_lat',
          ),
          'Real imtihon',
        );
      }
    });
  });

  group('displayLabel', () {
    TestResult result(String type, String key) => TestResult(
      type: type,
      testKey: key,
      label: key,
      totalQuestions: 20,
      correctAnswers: 18,
      timeSpentSeconds: 300,
      date: DateTime(2026, 1, 1),
    );

    test('re-resolves in the user\'s current language', () {
      expect(result('variant', 'v27.json').displayLabel('ru'), 'Вариант 27');
      expect(result('topic', 't1.json').displayLabel('ru'), 'Общие правила');
    });
  });
}
