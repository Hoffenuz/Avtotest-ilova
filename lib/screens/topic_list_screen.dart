import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/free_access.dart';
import '../models/question.dart';
import '../providers/language_provider.dart';
import '../services/app_strings.dart';
import '../services/question_service.dart';
import '../services/test_session_service.dart';
import '../theme/app_theme.dart';
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
    'asosiy': Icons.menu_book_rounded,
    'belgilar': Icons.signpost_rounded,
    'chorrahalar': Icons.alt_route_rounded,
    'chiziqlar': Icons.horizontal_rule_rounded,
    'ishoralar': Icons.traffic_rounded,
    'harakat': Icons.directions_car_filled_rounded,
    'maxsus': Icons.warning_amber_rounded,
    'xavfsizlik': Icons.medical_services_rounded,
  };

  void _openTopic(BuildContext context, Topic topic, String lang) {
    final testKey = topic.isAllQuestions
        ? topic.id
        : topic.filename.replaceAll('.json', '');
    final title = topic.getName(lang);

    void start(String? sessionId) {
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
    TestSessionService.startSession(
      variant: TestSessionService.deriveVariant(
        type: 'topic',
        testKey: testKey,
      ),
      questionSource: testKey,
      isPremium: false,
    ).then((session) {
      if (context.mounted) start(session.sessionId);
    });
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
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: AppTheme.glassDeco(context),
                  child: const Icon(Icons.arrow_back_ios_new, size: 16),
                ),
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: ListView.builder(
        physics: const BouncingScrollPhysics(),
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

          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10, left: 4),
                  child: Text(
                    entry.value[lang] ?? entry.value['uz_lat']!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: AppTheme.textM(context),
                    ),
                  ),
                ),
                ...categoryTopics.map(
                  (topic) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _TopicTile(
                      topic: topic,
                      lang: lang,
                      icon:
                          _categoryIcons[topic.category] ??
                          Icons.menu_book_rounded,
                      isUnlocked: hasPro || FreeAccess.isTopicFree(topic.id),
                      onTap: () => _openTopic(context, topic, lang),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TopicTile extends StatelessWidget {
  final Topic topic;
  final String lang;
  final IconData icon;

  /// Whether THIS USER may open it — a free topic or an active subscription —
  /// as opposed to whether the topic is free for everyone.
  final bool isUnlocked;

  final VoidCallback onTap;

  const _TopicTile({
    required this.topic,
    required this.lang,
    required this.icon,
    required this.isUnlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: AppTheme.cardDeco(context),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  // A locked topic gets a flat, muted square instead of the
                  // brand gradient — visibly the same list, visibly not yet
                  // yours.
                  gradient: isUnlocked ? AppTheme.blueGradient : null,
                  color: isUnlocked
                      ? null
                      : AppTheme.textM(context).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(
                  icon,
                  color: isUnlocked ? Colors.white : AppTheme.textM(context),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  topic.getName(lang),
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: AppTheme.textP(context),
                  ),
                ),
              ),
              if (!isUnlocked) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppTheme.orangeGradient,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'PRO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Icon(
                Icons.chevron_right,
                color: AppTheme.textM(context),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
