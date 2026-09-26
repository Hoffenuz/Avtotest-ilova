import 'dart:convert';

import 'package:avtotest_app/models/question.dart';
import 'package:avtotest_app/services/question_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the asset layout: topic and variant files ship as lists of global
/// ids that must resolve against barcha.json. A broken id silently shortens a
/// test, so this walks every bundled file.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('barcha.json holds the full bank', () async {
    final all = await QuestionService.loadAllQuestions();
    expect(all.length, greaterThan(1000));
    expect(
      all.map((q) => q.globalId).toSet().length,
      all.length,
      reason: 'global ids must be unique',
    );
    for (final q in all.take(50)) {
      expect(q.getText('uz_lat'), isNotEmpty);
      expect(q.getOptions('uz_lat'), isNotEmpty);
    }
  });

  test('every topic file resolves to real questions', () async {
    for (final topic in QuestionService.getTopics()) {
      final questions = topic.isAllQuestions
          ? await QuestionService.loadAllQuestions()
          : await QuestionService.loadTopicQuestions(topic.filename);

      expect(
        questions,
        isNotEmpty,
        reason: 'topic ${topic.id} (${topic.filename}) resolved to nothing',
      );
      expect(questions.every((q) => q.globalId.isNotEmpty), isTrue);
    }
  });

  test('every variant resolves and keeps its exam length', () async {
    final files = QuestionService.getVariantFiles();
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final bundled = manifest
        .listAssets()
        .where((a) => RegExp(r'^assets/tests-json/variants/v\d+\.json$').hasMatch(a))
        .length;
    expect(
      files.length,
      bundled,
      reason: 'QuestionService.variantCount must list every bundled ticket',
    );

    for (final file in files) {
      final questions = await QuestionService.loadVariantQuestions(file);
      expect(questions, isNotEmpty, reason: '$file resolved to nothing');
      // An exam ticket is 20 questions. The last one is the ticket the
      // website is still filling in (v64 has 15 today), so it is bounded
      // rather than pinned. Pinning it is what made the generator refuse to
      // run and left the app three months behind the site.
      if (file == files.last) {
        expect(
          questions.length,
          inInclusiveRange(1, 20),
          reason: '$file is the partial ticket; 1..20 expected',
        );
      } else {
        expect(
          questions.length,
          20,
          reason: '$file has the wrong question count',
        );
      }
      for (final q in questions) {
        expect(
          q.getOptions('uz_lat'),
          isNotEmpty,
          reason: '${q.globalId} in $file has no options',
        );
      }
    }
  });

  test('answer keys survive the id indirection', () async {
    final questions = await QuestionService.loadVariantQuestions('v1.json');
    for (final q in questions) {
      for (final lang in ['uz_lat', 'uz_cyr', 'ru']) {
        final options = q.getOptions(lang);
        if (options.isEmpty) continue;
        expect(
          options.where((Option o) => o.isCorrect).length,
          1,
          reason: '${q.globalId} [$lang] must have exactly one correct answer',
        );
      }
    }
  });

  // ─────────────────────────────────── whole-bank integrity (VAZIFA C §6.1)

  test('every question is complete in all three languages', () async {
    final all = await QuestionService.loadAllQuestions();
    final problems = <String>[];

    for (final q in all) {
      final counts = <int>{};
      for (final lang in ['uz_lat', 'uz_cyr', 'ru']) {
        final text = q.getText(lang);
        final options = q.getOptions(lang);

        if (text.trim().isEmpty) problems.add('${q.globalId} [$lang]: no text');
        if (options.isEmpty) {
          problems.add('${q.globalId} [$lang]: no options');
          continue;
        }
        counts.add(options.length);

        final correct = options.where((o) => o.isCorrect).length;
        if (correct != 1) {
          problems.add('${q.globalId} [$lang]: $correct correct answers');
        }
      }
      if (counts.length > 1) {
        problems.add(
          '${q.globalId}: option count differs per language $counts',
        );
      }
    }

    expect(problems, isEmpty, reason: problems.take(20).join('\n'));
  });

  // NOTE ON WHAT IS *NOT* ASSERTED HERE: the correct option's `id` is allowed
  // to differ between languages. The three translations list their options in
  // different orders — 268 questions do — so the Russian version of a question
  // can have the right answer at id 2 where the Latin one has it at id 4. The
  // flag is what carries the answer, never the position, and every screen
  // resolves it inside a single pinned language.

  test('every referenced picture is bundled', () async {
    final all = await QuestionService.loadAllQuestions();
    final missing = <String>[];

    for (final q in all) {
      final media = q.mediaUrl;
      if (media == null || media.isEmpty) continue;
      try {
        await rootBundle.load('assets/tests-json/images/$media');
      } catch (_) {
        missing.add('${q.globalId} → $media');
      }
    }

    expect(missing, isEmpty, reason: missing.take(20).join('\n'));
  });

  test('the newest questions reached every place that serves them', () async {
    final newIds = [for (var n = 11; n <= 19; n++) 't_63_q_$n'];

    final all = await QuestionService.loadAllQuestions();
    final bank = {for (final q in all) q.globalId};
    for (final id in newIds) {
      expect(bank, contains(id), reason: '$id missing from barcha.json');
    }

    final v63 = await QuestionService.loadVariantQuestions('v63.json');
    final inVariant = v63.map((q) => q.globalId).toSet();
    for (final id in newIds) {
      expect(inVariant, contains(id), reason: '$id missing from v63.json');
    }

    // "Yangi savollar" is the topic that exists to surface them.
    final fresh = await QuestionService.loadTopicQuestions('35a.json');
    expect(
      fresh.map((q) => q.globalId).where(newIds.contains),
      isNotEmpty,
      reason: 'none of the new questions appear in the "new questions" topic',
    );
  });

  test('the free pool is a real subset of the bank', () async {
    final ids = await QuestionService.loadFreeQuestionIds();
    expect(ids, isNotEmpty, reason: 'free_ids.json did not load');

    final all = await QuestionService.loadAllQuestions();
    final bank = {for (final q in all) q.globalId};
    final unknown = ids.where((id) => !bank.contains(id)).toList();

    expect(unknown, isEmpty, reason: 'free ids not in the bank: $unknown');
    expect(
      ids.length,
      lessThan(all.length),
      reason: 'the free pool must be smaller than the full bank',
    );
  });

  test('a free exam draws only from the free pool', () async {
    final freeIds = (await QuestionService.loadFreeQuestionIds()).toSet();
    final drawn = await QuestionService.loadExamQuestions(
      isPro: false,
      count: 20,
    );

    expect(drawn.length, 20);
    expect(
      drawn.every((q) => freeIds.contains(q.globalId)),
      isTrue,
      reason: 'a free user was served a PRO-only question',
    );
  });

  test('image-sizes manifest covers the pictures in use', () async {
    final raw = await rootBundle.loadString(
      'assets/tests-json/image-sizes.json',
    );
    final manifest = json.decode(raw) as Map<String, dynamic>;
    expect(manifest['numbered'], isA<Map<String, dynamic>>());
    expect(manifest['other'], isA<Map<String, dynamic>>());

    final numbered = (manifest['numbered'] as Map<String, dynamic>).length;
    final other = (manifest['other'] as Map<String, dynamic>).length;
    expect(
      numbered + other,
      greaterThan(700),
      reason: 'manifest looks truncated — reserved image space would be lost',
    );
  });
}
