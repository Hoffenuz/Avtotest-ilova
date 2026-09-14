import 'package:avtotest_app/models/site_content.dart';
import 'package:avtotest_app/services/question_image_sizes.dart';
import 'package:avtotest_app/services/site_content_service.dart';
import 'package:avtotest_app/utils/text_search.dart';
import 'package:flutter_test/flutter_test.dart';

/// The two reference sections are generated from the website's TypeScript by
/// `tools/gen_sections.mjs`. These assertions are the contract that generator
/// has to keep: the key translation (`oz`/`uz` → `uz_lat`/`uz_cyr`) is easy to
/// get backwards, and it fails silently — the screen just shows the wrong
/// alphabet to half the users.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Yodlash kerak', () {
    test('all nine topics load with content in three languages', () async {
      final topics = await SiteContentService.loadFactTopics();
      expect(topics.length, 9);

      for (final topic in topics) {
        expect(topic.id, isNotEmpty);
        for (final lang in ['uz_lat', 'uz_cyr', 'ru']) {
          expect(
            topic.title.get(lang),
            isNotEmpty,
            reason: '${topic.id} title',
          );
          expect(
            topic.subtitle.get(lang),
            isNotEmpty,
            reason: '${topic.id} subtitle',
          );
        }
        expect(topic.groups, isNotEmpty);
        expect(topic.rowCount, greaterThan(0));
      }
    });

    test(
      'every row keeps its label, value and unit in all languages',
      () async {
        final topics = await SiteContentService.loadFactTopics();
        for (final topic in topics) {
          for (final group in topic.groups) {
            for (final row in group.rows) {
              expect(row.value.trim(), isNotEmpty);
              for (final lang in ['uz_lat', 'uz_cyr', 'ru']) {
                expect(row.label.get(lang), isNotEmpty);
                expect(row.unit.get(lang), isNotEmpty);
              }
            }
          }
        }
      },
    );

    test('the Latin and Cyrillic columns are not the same string', () async {
      // Guards the `oz`/`uz` mapping: if it were wired straight through, both
      // would carry whichever alphabet happened to win.
      final topics = await SiteContentService.loadFactTopics();
      final speed = topics.firstWhere((t) => t.id == 'tezlik');
      expect(speed.title.get('uz_lat'), isNot(speed.title.get('uz_cyr')));
      expect(speed.title.get('uz_lat'), contains('Tezlik'));
      expect(speed.title.get('uz_cyr'), contains('Тезлик'));
    });
  });

  group('Avtodrom', () {
    test('the official table arrives whole', () async {
      final groups = await SiteContentService.loadPenaltyGroups();
      expect(groups.length, 3);
      expect(
        groups.map((g) => g.level),
        containsAll(PenaltyLevel.values),
        reason: 'all three severity levels must be present',
      );

      final numbers = groups.expand((g) => g.items).map((i) => i.no).toList()
        ..sort();
      expect(numbers.length, 32, reason: 'the table is numbered 1..32');
      expect(numbers.first, 1);
      expect(numbers.last, 32);
      expect(
        numbers.toSet().length,
        numbers.length,
        reason: 'no penalty number may repeat',
      );
    });

    test('every penalty carries points and text in three languages', () async {
      final groups = await SiteContentService.loadPenaltyGroups();
      for (final group in groups) {
        for (final item in group.items) {
          expect(item.points, greaterThan(0));
          for (final lang in ['uz_lat', 'uz_cyr', 'ru']) {
            expect(item.text.get(lang), isNotEmpty, reason: 'item ${item.no}');
          }
        }
      }
    });

    test('the optional condition is present where the table has one', () async {
      final groups = await SiteContentService.loadPenaltyGroups();
      final withNote = groups
          .expand((g) => g.items)
          .where((i) => i.note != null);
      expect(
        withNote,
        isNotEmpty,
        reason: '"per 5 seconds" / "per mistake" conditions were dropped',
      );
    });
  });

  group('QuestionImageSizes', () {
    setUp(QuestionImageSizes.resetForTest);

    test('reports a usable ratio before the manifest is loaded', () {
      final ratio = QuestionImageSizes.aspectRatioFor('u63-11.webp');
      expect(ratio, QuestionImageSizes.fallbackAspectRatio);
      expect(ratio, greaterThan(0));
    });

    test('resolves both the numbered and the named form', () async {
      await QuestionImageSizes.load();
      expect(QuestionImageSizes.isLoaded, isTrue);

      // `u<number>uz.webp` is keyed by the bare number in the manifest.
      final numbered = QuestionImageSizes.aspectRatioFor('u1uz.webp');
      expect(numbered, isNot(QuestionImageSizes.fallbackAspectRatio));

      // Everything else is keyed by file name; the newest pictures are.
      final named = QuestionImageSizes.aspectRatioFor('u63-11.webp');
      expect(named, greaterThan(0));
    });

    test('never returns zero for an unknown or empty name', () async {
      await QuestionImageSizes.load();
      expect(QuestionImageSizes.aspectRatioFor(null), greaterThan(0));
      expect(QuestionImageSizes.aspectRatioFor(''), greaterThan(0));
      expect(QuestionImageSizes.aspectRatioFor('nope.webp'), greaterThan(0));
    });
  });

  group('foldForSearch', () {
    // Both halves of the mixed-apostrophe problem the bank actually has
    // (docs/MOBILE-CONTENT-PROMPT.md §6.3).
    test('every apostrophe variant folds to the straight one', () {
      const straight = "o'q";
      expect(foldForSearch('o‘q'), straight);
      expect(foldForSearch('o’q'), straight);
      expect(foldForSearch('oʻq'), straight);
      expect(foldForSearch('oʼq'), straight);
      expect(foldForSearch(straight), straight);
    });

    test('a query in one form matches text in the other', () {
      final text = foldForSearch("Yo’lning o‘ng tomoni");
      expect(text.contains(foldForSearch("yo'l")), isTrue);
      expect(text.contains(foldForSearch("o‘ng")), isTrue);
    });

    test('case is folded too', () {
      expect(foldForSearch('QUVIB'), 'quvib');
    });
  });
}
