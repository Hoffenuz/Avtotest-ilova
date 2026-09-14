import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';
import '../services/app_strings.dart';
import '../services/difficult_questions_service.dart';
import '../theme/app_theme.dart';
import '../widgets/guarded_test_launcher.dart';
import '../widgets/premium_access_gate.dart';
import 'test_screen.dart';

/// Pro-gated test drawn from a pool weighted toward intersections, sign/term
/// meanings, first aid, and long questions — the categories users most often
/// get wrong. See [DifficultQuestionsService] for the sampling algorithm.
class DifficultQuestionsScreen extends StatelessWidget {
  const DifficultQuestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    return PremiumAccessGate(
      featureTitle: AppStrings.get('difficult_questions', lang),
      child: const _DifficultQuestionsContent(),
    );
  }
}

class _DifficultQuestionsContent extends StatelessWidget {
  const _DifficultQuestionsContent();

  void _start(BuildContext context, String lang) {
    final title = AppStrings.get('difficult_questions', lang);
    launchGuardedTest(
      context,
      testType: 'difficult',
      testKey: 'difficult',
      onGranted: (_) {
        Navigator.pushReplacement(
          context,
          AppTheme.slideRoute(
            TestScreen(
              title: title,
              loadQuestions: () => DifficultQuestionsService.buildPool(),
              testType: 'practice',
              testLabel: title,
              timeLimitMinutes: 25,
              questionLang: lang,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    String s(String k) => AppStrings.get(k, lang);

    return Scaffold(
      appBar: AppBar(title: Text(s('difficult_questions'))),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.blueGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.blue.withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.psychology_alt_rounded,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s('difficult_questions'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s('difficult_questions_sub'),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _CategoryRow(
              icon: Icons.turn_slight_right_rounded,
              label: s('difficulty_cat_intersections'),
            ),
            _CategoryRow(
              icon: Icons.signpost_rounded,
              label: s('difficulty_cat_signs'),
            ),
            _CategoryRow(
              icon: Icons.medical_services_rounded,
              label: s('difficulty_cat_first_aid'),
            ),
            _CategoryRow(
              icon: Icons.article_rounded,
              label: s('difficulty_cat_long'),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.orangeGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.orange.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    onTap: () => _start(context, lang),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          s('start_test'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CategoryRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: AppTheme.cardDeco(context),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textP(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
