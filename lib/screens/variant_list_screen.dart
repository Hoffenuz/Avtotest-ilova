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

/// The exam tickets ([QuestionService.variantCount]).
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
          icon: const Icon(Icons.arrow_back_rounded),
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
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              // Five across, as on the site's variant picker: every ticket
              // is one tap, and 64 of them fit in under three screens.
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: variants.length,
              itemBuilder: (context, index) {
                final number = index + 1;
                return _VariantTile(
                  number: number,
                  lang: lang,
                  isUnlocked: hasPro || FreeAccess.isVariantFree(number),
                  // The free ones are marked out only for someone who does
                  // not have everything anyway.
                  isFreeHighlight: !hasPro && FreeAccess.isVariantFree(number),
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
            color: AppTheme.mutedText(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: AppTheme.mutedText(context),
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

  /// Light-blue "free" tile, as on the site.
  final bool isFreeHighlight;

  final VoidCallback onTap;

  const _VariantTile({
    required this.number,
    required this.lang,
    required this.isUnlocked,
    required this.isFreeHighlight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);
    final Color bg;
    final Color border;
    final Color fg;
    if (isFreeHighlight) {
      bg = dark ? const Color(0x66172554) : const Color(0xFFEFF6FF);
      border = dark ? const Color(0xFF1E40AF) : const Color(0xFF93C5FD);
      fg = dark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8);
    } else {
      bg = AppTheme.card(context);
      border = AppTheme.hairline(context);
      fg = AppTheme.textP(context);
    }

    // Locked tickets are dimmed, not hidden: seeing how much more there is,
    // is the argument for PRO.
    return Opacity(
      opacity: isUnlocked ? 1 : 0.5,
      child: Semantics(
        button: true,
        label:
            '${AppStrings.get('variant', lang)} $number'
            '${isUnlocked ? '' : ', ${AppStrings.get('pro_badge', lang)}'}',
        excludeSemantics: true,
        child: Material(
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            side: BorderSide(color: border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                Center(
                  child: Text(
                    '$number',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isUnlocked ? fg : AppTheme.mutedText(context),
                    ),
                  ),
                ),
                if (!isUnlocked)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Icon(
                      Icons.lock_rounded,
                      size: 11,
                      color: AppTheme.mutedText(context),
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
