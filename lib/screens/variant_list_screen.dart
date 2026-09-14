import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/free_access.dart';
import '../providers/language_provider.dart';
import '../services/app_strings.dart';
import '../services/question_service.dart';
import '../services/test_session_service.dart';
import '../theme/app_theme.dart';
import '../widgets/guarded_test_launcher.dart';
import '../widgets/premium_access_gate.dart';
import 'pro_screen.dart';
import 'test_screen.dart';

/// The 63 exam tickets.
///
/// THE LIST ITSELF IS NOT GATED. It used to sit behind a full-screen paywall,
/// so someone without an account saw a locked door and no idea what was behind
/// it. Now every ticket is visible: the first [FreeAccess.freeVariantCount]
/// open to anyone, the rest carrying a lock. The value is on display, and the
/// price is attached to it.
class VariantListScreen extends StatelessWidget {
  const VariantListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    final variants = QuestionService.getVariantFiles();

    // A subscriber sees no locks and no notice: everything is theirs, and
    // padlocks on paid-for content read as a bug.
    final hasPro = watchHasPro(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('variants', lang)),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: AppTheme.glassDeco(context),
            child: const Icon(Icons.arrow_back_ios_new, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          if (!hasPro)
            FreeAccessNotice(
              text: AppStrings.get('free_variants_notice', lang),
            ),
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: variants.length,
              itemBuilder: (context, index) {
                final number = index + 1;
                return _VariantTile(
                  number: number,
                  lang: lang,
                  isUnlocked: hasPro || FreeAccess.isVariantFree(number),
                  onTap: () => _open(context, variants[index], number, lang),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, String filename, int number, String lang) {
    final label = '${AppStrings.get('variant', lang)} $number';
    final testKey = filename.replaceAll('.json', '');

    void start(String? sessionId) {
      Navigator.push(
        context,
        AppTheme.slideRoute(
          TestScreen(
            title: label,
            loadQuestions: () => QuestionService.loadVariantQuestions(filename),
            testType: 'variant',
            testLabel: label,
            testKey: testKey,
            timeLimitMinutes: 25,
            questionLang: lang,
            sessionId: sessionId,
          ),
        ),
      );
    }

    if (!FreeAccess.isVariantFree(number)) {
      launchGuardedTest(
        context,
        testType: 'variant',
        testKey: testKey,
        onGranted: start,
        onDenied: () =>
            Navigator.push(context, AppTheme.slideRoute(const ProScreen())),
      );
      return;
    }

    // A free ticket opens offline, and for a guest. The session is still asked
    // for, so the attempt reaches the user's history when there is a network
    // and an account — but failing to get one must not block the test.
    TestSessionService.startSession(
      variant: TestSessionService.deriveVariant(
        type: 'variant',
        testKey: testKey,
      ),
      questionSource: testKey,
      isPremium: false,
    ).then((session) {
      if (context.mounted) start(session.sessionId);
    });
  }
}

/// One line above a partly-locked list saying which part is free, so a lock
/// icon never has to be guessed at.
class FreeAccessNotice extends StatelessWidget {
  final String text;
  const FreeAccessNotice({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppTheme.textM(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: AppTheme.textM(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VariantTile extends StatelessWidget {
  final int number;
  final String lang;

  /// Whether THIS USER may open it — free ticket or active subscription — as
  /// opposed to whether the ticket is free for everyone.
  final bool isUnlocked;

  final VoidCallback onTap;

  const _VariantTile({
    required this.number,
    required this.lang,
    required this.isUnlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isUnlocked ? AppTheme.orange : AppTheme.textM(context);

    return Semantics(
      button: true,
      label:
          '${AppStrings.get('variant', lang)} $number'
          '${isUnlocked ? '' : ', ${AppStrings.get('pro_badge', lang)}'}',
      excludeSemantics: true,
      child: Material(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: accent.withValues(alpha: 0.2)),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$number',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          // Locked tickets are dimmed, not hidden: seeing how
                          // much more there is, is the argument for PRO.
                          color: isUnlocked
                              ? AppTheme.orange
                              : AppTheme.textM(context),
                        ),
                      ),
                      Text(
                        AppStrings.get('variant', lang),
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textM(context),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isUnlocked)
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Icon(
                      Icons.lock_rounded,
                      size: 13,
                      color: AppTheme.textM(context).withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
