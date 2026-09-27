import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/free_access.dart';
import '../models/question.dart';
import '../providers/language_provider.dart';
import '../services/app_strings.dart';
import '../services/question_service.dart';
import '../services/test_session_service.dart';
import '../theme/app_theme.dart';
import '../widgets/brand.dart';
import '../widgets/guarded_test_launcher.dart';
import '../widgets/premium_access_gate.dart';
import 'pro_screen.dart';
import 'test_screen.dart';
import 'variant_list_screen.dart' show FreeAccessNotice;

/// Topic tests, grouped by category.
///
/// Like the ticket grid, the LIST is open to everyone — only starting a locked
/// topic asks for PRO. [FreeAccess.freeTopicIds] decides which are open.
class TopicListScreen extends StatelessWidget {
  final bool embedded;

  const TopicListScreen({super.key, this.embedded = false});

  /// One icon per category.
  ///
  /// This replaces the badge that used to print the topic's raw id — "31",
  /// "35a", "34tengaxamiyatli". Those are database keys the website and this
  /// app agree on; they are not a numbering the user can make sense of, and
  /// showing them next to "Barcha savollar" made the list look like a numbered
  /// syllabus that skips numbers.
  static const Map<String, IconData> _categoryIcons = {
    'asosiy': Icons.menu_book_outlined,
    'belgilar': Icons.signpost_outlined,
    'chorrahalar': Icons.alt_route_rounded,
    'chiziqlar': Icons.horizontal_rule_rounded,
    'ishoralar': Icons.traffic_outlined,
    'harakat': Icons.directions_car_outlined,
    'maxsus': Icons.warning_amber_rounded,
    'xavfsizlik': Icons.medical_services_outlined,
  };

  void _openTopic(BuildContext context, Topic topic, String lang) {
    final testKey = topic.isAllQuestions
        ? topic.id
        : topic.filename.replaceAll('.json', '');
    final title = topic.getName(lang);

    void start(String? sessionId, {Future<String?>? pending}) {
      Navigator.push(
        context,
        AppTheme.slideRoute(
          TestScreen(
            title: title,
            loadQuestions: () => topic.isAllQuestions
                ? QuestionService.loadAllQuestions()
                : QuestionService.loadTopicQuestions(topic.filename),
            testType: 'topic',
            testLabel: title,
            testKey: testKey,
            countUp: true,
            questionLang: lang,
            sessionId: sessionId,
            pendingSessionId: pending,
          ),
        ),
      );
    }

    if (!FreeAccess.isTopicFree(topic.id)) {
      launchGuardedTest(
        context,
        testType: 'topic',
        testKey: testKey,
        onGranted: start,
        onDenied: () =>
            Navigator.push(context, AppTheme.slideRoute(const ProScreen())),
      );
      return;
    }

    // Free topics work offline and without an account; the session is
    // best-effort, exactly as for the free exam tickets.
    // Opens at once — waiting on the network here was the pause after the
    // tap. The session request runs alongside and is needed only at the end.
    start(
      null,
      pending: TestSessionService.startSession(
        variant: TestSessionService.deriveVariant(
          type: 'topic',
          testKey: testKey,
        ),
        questionSource: testKey,
        isPremium: false,
      ).then((session) => session.sessionId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    final topics = QuestionService.getTopics();

    // Locks and the "which are free" notice are for people who do not have
    // PRO. A subscriber sees a plain, complete list.
    final hasPro = watchHasPro(context);
    final byCategory = <String, List<Topic>>{};
    for (final t in topics) {
      byCategory.putIfAbsent(t.category, () => []).add(t);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('topic_tests', lang)),
        automaticallyImplyLeading: !embedded,
        leading: embedded
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        // +1 for the notice that heads the list.
        itemCount: QuestionService.topicCategoryOrder.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return hasPro
                ? const SizedBox.shrink()
                : FreeAccessNotice(
                    text: AppStrings.get('free_topics_notice', lang),
                  );
          }

          final entry = QuestionService.topicCategoryOrder[index - 1];
          final categoryTopics = byCategory[entry.key] ?? const [];
          if (categoryTopics.isEmpty) return const SizedBox.shrink();

          // One card per category, one uniform row per topic — the same
          // rows as Settings; PRO sits at the end of a locked row.
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
                  child: Text(
                    entry.value[lang] ?? entry.value['uz_lat']!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textP(context),
                    ),
                  ),
                ),
                SettingsGroup(
                  children: [
                    for (final topic in categoryTopics)
                      SettingsRow(
                        icon:
                            _categoryIcons[topic.category] ??
                            Icons.menu_book_rounded,
                        title: topic.getName(lang),
                        trailing: hasPro || FreeAccess.isTopicFree(topic.id)
                            ? null
                            : const ProTag(),
                        onTap: () => _openTopic(context, topic, lang),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
