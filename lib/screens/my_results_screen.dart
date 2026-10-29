import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/question.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../providers/subscription_provider.dart';
import '../screens/auth_screen.dart';
import '../services/app_strings.dart';
import '../services/test_results_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ha_yo_dialog.dart';
import '../widgets/readiness_widgets.dart';
import 'errors_screen.dart';

/// «Natijalarim» ekrani va uning kartalari.
///
/// Ilgari profile_screen.dart ichida edi (2 100+ qator). Sozlamalar ekrani
/// sozlamalarni, bu fayl natijalarni ko'rsatadi — har biri o'z joyida.
/// The headline numbers, in a 2x2 grid at the top of the screen.
///
/// These are the one thing on this screen worth seeing without tapping
/// anything, so they are the one thing that does not collapse.
class _StatsCard extends StatelessWidget {
  final List<TestResult> results;
  final String lang;

  const _StatsCard({required this.results, required this.lang});

  @override
  Widget build(BuildContext context) {
    String s(String k) => AppStrings.get(k, lang);

    // Unfinished attempts are excluded on purpose: a test abandoned after two
    // questions would otherwise sink the "wrong answers" count and make the
    // numbers look like the user is doing far worse than they are.
    final completed = results.where((r) => r.isCompleted).toList();
    final correct = completed.fold<int>(0, (sum, r) => sum + r.correctAnswers);
    final wrong = completed.fold<int>(
      0,
      (sum, r) => sum + (r.totalQuestions - r.correctAnswers),
    );
    final passed = completed.where((r) => r.isPassed).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDeco(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _StatTile(
                icon: Icons.emoji_events_outlined,
                value: '${completed.length}',
                label: s('total_tests'),
                color: AppTheme.brandAccent(context),
              ),
              const SizedBox(width: 10),
              _StatTile(
                icon: Icons.workspace_premium_outlined,
                value: '$passed',
                label: s('passed_tests'),
                color: AppTheme.brandAccent(context),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _StatTile(
                icon: Icons.check_circle_outline_rounded,
                value: '$correct',
                label: s('correct'),
                color: AppTheme.success,
              ),
              const SizedBox(width: 10),
              _StatTile(
                icon: Icons.cancel_outlined,
                value: '$wrong',
                label: s('incorrect'),
                color: AppTheme.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.card(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.hairline(context)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textP(context),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: AppTheme.textM(context)),
            ),
          ],
        ),
      ),
    );
  }
}


// ───────────────────────── Results ─────────────────────────

class _LocalResultsCard extends StatelessWidget {
  final List<TestResult> results;
  final String lang;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onClear;

  const _LocalResultsCard({
    required this.results,
    required this.lang,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    String s(String k) => AppStrings.get(k, lang);

    final completed = results.where((r) => r.isCompleted).toList();
    final total = completed.length;
    final passed = completed.where((r) => r.isPassed).length;
    final avg = total > 0
        ? (completed.fold<double>(0, (sum, r) => sum + r.percentage) /
                  total *
                  100)
              .round()
        : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDeco(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardHeader(
            icon: Icons.bar_chart_rounded,
            color: AppTheme.brandAccent(context),
            title: s('local_statistics'),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MiniStat(
                label: s('total_tests'),
                value: '$total',
                color: AppTheme.brandAccent(context),
              ),
              const SizedBox(width: 10),
              _MiniStat(
                label: s('passed_tests'),
                value: '$passed',
                color: AppTheme.success,
              ),
              const SizedBox(width: 10),
              _MiniStat(
                label: s('average'),
                value: '$avg%',
                color: AppTheme.brandAccent(context),
              ),
            ],
          ),
          if (results.isNotEmpty) ...[
            const SizedBox(height: 14),
            _ResultsAccordion(
              title: s('recent_results'),
              count: results.length,
              expanded: expanded,
              onToggle: onToggleExpanded,
              child: _ResultList(
                results: expanded
                    ? results.take(20).toList()
                    : results.take(3).toList(),
                lang: lang,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: Text(s('clear_results')),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.error,
                side: BorderSide(color: AppTheme.error.withValues(alpha: 0.4)),
                minimumSize: const Size(0, 44),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Text(
              s('no_local_results'),
              style: TextStyle(fontSize: 13, color: AppTheme.textM(context)),
            ),
          ],
        ],
      ),
    );
  }
}

class _CloudResultsCard extends StatelessWidget {
  final List<TestResult> results;
  final String lang;
  final bool isLoggedIn;
  final bool syncing;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onSync;
  final VoidCallback onSignIn;

  const _CloudResultsCard({
    required this.results,
    required this.lang,
    required this.isLoggedIn,
    required this.syncing,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onSync,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    String s(String k) => AppStrings.get(k, lang);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDeco(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardHeader(
            icon: Icons.cloud_outlined,
            color: AppTheme.brandAccent(context),
            title: s('cloud_results'),
          ),
          const SizedBox(height: 14),
          if (!isLoggedIn) ...[
            Text(
              s('login_for_cloud_results'),
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textM(context),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onSignIn,
              icon: const Icon(Icons.login_rounded, size: 18),
              label: Text(s('sign_in')),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: syncing ? null : onSync,
              icon: syncing
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    )
                  : const Icon(Icons.sync_rounded, size: 18),
              label: Text(s('refresh_results')),
              style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
            ),
            if (results.isNotEmpty) ...[
              const SizedBox(height: 14),
              _ResultsAccordion(
                title: s('recent_results'),
                count: results.length,
                expanded: expanded,
                onToggle: onToggleExpanded,
                embedded: true,
                child: _ResultList(
                  results: expanded
                      ? results.take(20).toList()
                      : results.take(3).toList(),
                  lang: lang,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;

  const _CardHeader({
    required this.icon,
    required this.color,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 19, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15.5,
              color: AppTheme.textP(context),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultList extends StatelessWidget {
  final List<TestResult> results;
  final String lang;

  const _ResultList({required this.results, required this.lang});

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: results.map((r) {
        final pct = (r.percentage * 100).round();
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.border(context)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: r.isPassed
                      ? AppTheme.success.withValues(alpha: 0.12)
                      : AppTheme.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Center(
                  child: Text(
                    '$pct%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: r.isPassed ? AppTheme.success : AppTheme.error,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.displayLabel(lang),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textP(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${r.correctAnswers}/${r.totalQuestions} · ${_formatDate(r.date)}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.textM(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                r.isPassed ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: r.isPassed ? AppTheme.success : AppTheme.error,
                size: 20,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ResultsAccordion extends StatelessWidget {
  final String title;
  final int count;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;
  final bool embedded;

  const _ResultsAccordion({
    required this.title,
    required this.count,
    required this.expanded,
    required this.onToggle,
    required this.child,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            onTap: onToggle,
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: AppTheme.surface(context),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.border(context)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 18,
                    color: AppTheme.brandAccent(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.textP(context),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.brandAccent(
                        context,
                      ).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brandAccent(context),
                      ),
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.textM(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (expanded) ...[const SizedBox(height: 10), child],
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(fontSize: 10.5, color: AppTheme.textM(context)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}


// ───────────────────────── Natijalarim ─────────────────────────

/// "Natijalarim": the headline numbers and both result lists on a page of
/// their own, so the settings tab holds settings and nothing else.
class MyResultsScreen extends StatefulWidget {
  /// "Boshlash" on the readiness card: back to the tabs, on "Test ishlash".
  final VoidCallback? onStartTest;

  const MyResultsScreen({super.key, this.onStartTest});

  @override
  State<MyResultsScreen> createState() => _MyResultsScreenState();
}

class _MyResultsScreenState extends State<MyResultsScreen> {
  List<TestResult> _practiceResults = [];
  List<TestResult> _cloudResults = [];
  bool _syncingCloud = false;
  bool _showAllPracticeResults = false;
  bool _showAllCloudResults = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    TestResultsService.revision.addListener(_loadData);
  }

  @override
  void dispose() {
    TestResultsService.revision.removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    final practice = await TestResultsService.getPracticeResults();
    final cloud = await TestResultsService.getCloudResults();
    if (!mounted) return;
    setState(() {
      _practiceResults = practice;
      _cloudResults = cloud;
    });
  }

  Future<void> _refreshCloudResults() async {
    if (_syncingCloud) return;
    final lang = context.read<LanguageProvider>().lang;
    String s(String k) => AppStrings.get(k, lang);

    setState(() => _syncingCloud = true);
    try {
      final cloud = await TestResultsService.refreshCloud();
      if (!mounted) return;
      setState(() {
        _cloudResults = cloud;
        _syncingCloud = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s('sync_success')),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _syncingCloud = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s('sync_failed')),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _clearResults(String lang) async {
    String s(String k) => AppStrings.get(k, lang);

    final ok = await showHaYoDialog(
      context,
      title: s('clear_results'),
      message: s('clear_practice_results_msg'),
      lang: lang,
      yesLabel: s('yes'),
      noLabel: s('no'),
      destructive: true,
    );
    if (ok != true || !mounted) return;

    await TestResultsService.clearPracticeResults();
    if (!mounted) return;
    setState(() {
      _practiceResults = [];
      _showAllPracticeResults = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s('results_cleared')),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openAuth() async {
    final sub = context.read<SubscriptionProvider>();
    final ok = await Navigator.push<bool>(
      context,
      AppTheme.slideRoute(const AuthScreen(isModal: true)),
    );
    if (ok == true && mounted) await sub.refresh(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    final auth = context.watch<AuthProvider>();
    String s(String k) => AppStrings.get(k, lang);

    return Scaffold(
      appBar: AppBar(title: Text(s('my_results'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          // The same score as the website's profile, from the same RPC.
          ReadinessCard(
            onStart:
                widget.onStartTest ??
                () => Navigator.of(context).popUntil((r) => r.isFirst),
            onReview: () => Navigator.push(
              context,
              AppTheme.slideRoute(const ErrorsScreen()),
            ),
          ),
          _StatsCard(
            results: [..._practiceResults, ..._cloudResults],
            lang: lang,
          ),
          const SizedBox(height: 12),
          _LocalResultsCard(
            results: _practiceResults,
            lang: lang,
            expanded: _showAllPracticeResults,
            onToggleExpanded: () => setState(
              () => _showAllPracticeResults = !_showAllPracticeResults,
            ),
            onClear: () => _clearResults(lang),
          ),
          const SizedBox(height: 12),
          _CloudResultsCard(
            results: _cloudResults,
            lang: lang,
            isLoggedIn: auth.isLoggedIn,
            syncing: _syncingCloud,
            expanded: _showAllCloudResults,
            onToggleExpanded: () =>
                setState(() => _showAllCloudResults = !_showAllCloudResults),
            onSync: _refreshCloudResults,
            onSignIn: _openAuth,
          ),
        ],
      ),
    );
  }
}
