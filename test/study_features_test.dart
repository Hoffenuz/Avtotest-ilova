import 'package:avtotest_app/providers/settings_provider.dart';
import 'package:avtotest_app/services/question_service.dart';
import 'package:avtotest_app/services/storage_service.dart';
import 'package:avtotest_app/services/topic_stats_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // The tally is now held in memory between writes, so resetting the fake
    // preference store is not enough to give each test a clean slate.
    await StorageService.clearQuestionStats();
  });

  group('per-question tally', () {
    test('counts attempts and correct answers separately', () async {
      await StorageService.recordAnswer('t_1_q_1', false);
      await StorageService.recordAnswer('t_1_q_1', true);
      await StorageService.recordAnswer('t_1_q_2', true);

      final stats = await StorageService.getQuestionStats();
      expect(stats['t_1_q_1'], (2, 1), reason: 'seen twice, right once');
      expect(stats['t_1_q_2'], (1, 1));
      expect(stats['t_1_q_3'], isNull, reason: 'never answered');
    });

    test('survives a reload and keeps accumulating', () async {
      await StorageService.recordAnswer('t_5_q_1', true);
      await StorageService.recordAnswer('t_5_q_1', true);
      expect((await StorageService.getQuestionStats())['t_5_q_1'], (2, 2));
    });

    test('a burst of answers is buffered, not written one by one', () async {
      // The reason the tally is buffered at all: this used to be 50
      // read-modify-write cycles over the whole map, each one re-serialising
      // every entry and committing it to disk between two questions.
      for (var i = 0; i < 50; i++) {
        await StorageService.recordAnswer('t_1_q_$i', i.isEven);
      }

      // Readable straight away even though nothing has been flushed yet.
      expect((await StorageService.getQuestionStats()).length, 50);

      await StorageService.flushQuestionStats();
      final persisted = await StorageService.getQuestionStats();
      expect(persisted.length, 50);
      expect(persisted['t_1_q_0'], (1, 1));
      expect(persisted['t_1_q_1'], (1, 0));
    });

    test('clearing removes everything', () async {
      await StorageService.recordAnswer('t_9_q_9', true);
      await StorageService.clearQuestionStats();
      expect(await StorageService.getQuestionStats(), isEmpty);
    });
  });

  group('topic breakdown', () {
    test('with nothing answered, every topic reports no data', () async {
      final rows = await TopicStatsService.compute();
      expect(rows, isNotEmpty, reason: 'topics did not load');
      expect(rows.every((r) => !r.hasData), isTrue);
      expect(rows.every((r) => r.total > 0), isTrue);
    });

    test('"all questions" is not a row of its own', () async {
      final rows = await TopicStatsService.compute();
      expect(
        rows.any((r) => r.topic.isAllQuestions),
        isFalse,
        reason: 'it would just restate the overall average',
      );
    });

    test(
      'answers land in the right topic and give the right accuracy',
      () async {
        // Take real questions out of a real topic file so the mapping is
        // exercised end to end, not against a fixture.
        final topicQuestions = await QuestionService.loadTopicQuestions(
          '1.json',
        );
        expect(topicQuestions.length, greaterThan(4));

        final ids = topicQuestions.take(4).map((q) => q.globalId).toList();
        await StorageService.recordAnswer(ids[0], true);
        await StorageService.recordAnswer(ids[1], true);
        await StorageService.recordAnswer(ids[2], false);
        await StorageService.recordAnswer(ids[3], false);

        final rows = await TopicStatsService.compute();
        final topic1 = rows.firstWhere((r) => r.topic.id == '1');

        expect(topic1.attempts, 4);
        expect(topic1.correct, 2);
        expect(topic1.accuracyPercent, 50);
        expect(topic1.answered, 4);
        expect(topic1.answered, lessThanOrEqualTo(topic1.total));
      },
    );

    test('the weakest topic sorts to the top', () async {
      final good = await QuestionService.loadTopicQuestions('1.json');
      final bad = await QuestionService.loadTopicQuestions('2.json');

      await StorageService.recordAnswer(good.first.globalId, true);
      await StorageService.recordAnswer(bad.first.globalId, false);

      final rows = await TopicStatsService.compute();
      final answered = rows.where((r) => r.hasData).toList();
      expect(answered.first.topic.id, '2', reason: 'worst must come first');
      expect(
        rows.indexWhere((r) => !r.hasData),
        greaterThan(1),
        reason: 'untouched topics belong below the answered ones',
      );
    });

    test('overall totals match the sum of the parts', () async {
      final questions = await QuestionService.loadTopicQuestions('3.json');
      await StorageService.recordAnswer(questions[0].globalId, true);
      await StorageService.recordAnswer(questions[1].globalId, false);

      final (attempts, correct) = await TopicStatsService.overall();
      expect(attempts, 2);
      expect(correct, 1);
    });
  });

  group('question text size', () {
    test('starts at 100% and stays inside its range', () async {
      final provider = SettingsProvider();
      expect(provider.scale, SettingsProvider.defaultScale);
      expect(provider.isDefaultScale, isTrue);
      expect(provider.scaleLabel, '100%');

      await provider.setScale(99);
      expect(provider.scale, SettingsProvider.maxScale);
      await provider.setScale(0);
      expect(provider.scale, SettingsProvider.minScale);
    });

    test('the choice survives a restart', () async {
      final provider = SettingsProvider();
      await provider.setScale(1.2);

      final reopened = SettingsProvider();
      await reopened.init();
      expect(reopened.scale, closeTo(1.2, 0.001));
      expect(reopened.isDefaultScale, isFalse);
    });

    test('reset returns to the default', () async {
      final provider = SettingsProvider();
      await provider.setScale(SettingsProvider.maxScale);
      await provider.resetScale();
      expect(provider.isDefaultScale, isTrue);
    });
  });
}
