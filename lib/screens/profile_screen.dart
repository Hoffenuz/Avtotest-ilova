import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/question.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/auth_screen.dart';
import '../screens/pro_screen.dart';
import '../screens/topic_stats_screen.dart';
import '../services/app_strings.dart';
import '../services/daily_question_service.dart';
import '../services/test_results_service.dart';
import '../theme/app_theme.dart';
import '../widgets/brand.dart';
import '../widgets/update_banner.dart';
import '../utils/phone.dart';
import '../widgets/ha_yo_dialog.dart';

/// Settings tab.
///
/// Laid out as four clearly separated blocks — account, PRO, preferences,
/// results — instead of the previous single stack where the subscription card,
/// the name field and the app settings sat interleaved.
class ProfileScreen extends StatefulWidget {
  final bool embedded;
  const ProfileScreen({super.key, this.embedded = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  List<TestResult> _practiceResults = [];
  List<TestResult> _cloudResults = [];
  bool _loading = true;
  String? _syncedUserId;
  String? _cloudSyncedUserId;

  @override
  bool get wantKeepAlive => true;

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
      _loading = false;
    });
  }

  /// Keeps the cloud-results list in step with whoever is signed in, so one
  /// account never sees another's history on a shared device.
  void _syncStateFromAuth(AuthProvider auth) {
    if (auth.isLoggedIn && auth.userId != _syncedUserId) {
      _syncedUserId = auth.userId;
    } else if (!auth.isLoggedIn && _syncedUserId != null) {
      _syncedUserId = null;
    }

    if (auth.isLoggedIn && auth.userId != _cloudSyncedUserId) {
      _cloudSyncedUserId = auth.userId;
      TestResultsService.refreshCloud()
          .then((cloud) {
            if (mounted) setState(() => _cloudResults = cloud);
          })
          .catchError((_) {});
    } else if (!auth.isLoggedIn && _cloudSyncedUserId != null) {
      _cloudSyncedUserId = null;
      if (mounted) setState(() => _cloudResults = []);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncStateFromAuth(context.read<AuthProvider>());
  }

  Future<void> _openAuth({required bool signUp}) async {
    final sub = context.read<SubscriptionProvider>();
    final ok = await Navigator.push<bool>(
      context,
      AppTheme.slideRoute(AuthScreen(isModal: true, startOnSignUp: signUp)),
    );
    if (ok == true && mounted) await sub.refresh(force: true);
  }

  /// Everything about "my account", behind the one pencil that says so:
  /// the display name, the password, signing out, and deletion.
  Future<void> _showAccountSheet(String lang) async {
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final action = await showModalBottomSheet<_AccountAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AccountSheet(lang: lang, auth: auth),
    );
    if (action == null || !mounted) return;

    // The follow-up runs AFTER the sheet is gone: a confirmation dialog opened
    // underneath an open sheet is unreachable.
    switch (action) {
      case _AccountAction.nameSaved:
      case _AccountAction.nameFailed:
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.get(
                action == _AccountAction.nameSaved
                    ? 'name_saved'
                    : 'auth_error_generic',
                lang,
              ),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      case _AccountAction.password:
        await _showChangePasswordSheet(lang);
      case _AccountAction.logout:
        await _confirmLogout(lang);
      case _AccountAction.delete:
        await _confirmDeleteAccount(lang);
    }
  }

  Future<void> _showChangePasswordSheet(String lang) async {
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ChangePasswordSheet(lang: lang, auth: auth),
    );

    if (changed != true) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(AppStrings.get('password_changed', lang)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Text size, in a sheet — so the settings row itself stays the same shape
  /// as every other row, and the slider gets the live sample it needs.
  Future<void> _showTextSizeSheet(String lang) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _TextSizeSheet(lang: lang),
    );
  }

  Future<void> _showLanguageSheet(String lang) {
    final provider = context.read<LanguageProvider>();
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _LanguageSheet(lang: lang, provider: provider),
    );
  }

  Future<void> _confirmLogout(String lang) async {
    String s(String k) => AppStrings.get(k, lang);
    final authProvider = context.read<AuthProvider>();
    final subProvider = context.read<SubscriptionProvider>();

    final ok = await showHaYoDialog(
      context,
      title: s('logout'),
      message: s('logout_confirm'),
      lang: lang,
      yesLabel: s('logout'),
      noLabel: s('cancel'),
      destructive: true,
    );
    if (ok != true) return;

    await authProvider.signOut();
    subProvider.clear();
  }

  /// Two-step confirmation: an explanation of exactly what disappears, then a
  /// second dialog, because the action cannot be undone.
  Future<void> _confirmDeleteAccount(String lang) async {
    String s(String k) => AppStrings.get(k, lang);
    final auth = context.read<AuthProvider>();
    final sub = context.read<SubscriptionProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final isPro = sub.isPro;

    final agreed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.person_remove_rounded,
          size: 40,
          color: AppTheme.error,
        ),
        title: Text(s('delete_account'), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s('delete_account_warning'),
              style: const TextStyle(height: 1.4),
            ),
            if (isPro) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(
                    color: AppTheme.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  s('delete_account_pro_warning'),
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: AppTheme.orange,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: Text(s('continue_action')),
          ),
        ],
      ),
    );
    if (agreed != true || !mounted) return;

    final confirmed = await showHaYoDialog(
      context,
      title: s('delete_account_final_title'),
      message: s('delete_account_final_msg'),
      lang: lang,
      yesLabel: s('delete_account_yes'),
      noLabel: s('cancel'),
      destructive: true,
    );
    if (confirmed != true || !mounted) return;

    final navigator = Navigator.of(context, rootNavigator: true);
    final loader = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(
          child: SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
    navigator.push(loader);

    final errKey = await auth.deleteAccount();
    navigator.removeRoute(loader);
    if (!mounted) return;

    if (errKey != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(AppStrings.get(errKey, lang)),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    sub.clear();
    setState(() {
      _practiceResults = [];
      _cloudResults = [];
      _syncedUserId = null;
      _cloudSyncedUserId = null;
    });
    messenger.showSnackBar(
      SnackBar(
        content: Text(s('account_deleted')),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// "12 ta test · 7 tasidan o'tilgan" — the one line of results that
  /// belongs on the settings list.
  String _resultsSummary(String lang) {
    final completed = [
      ..._practiceResults,
      ..._cloudResults,
    ].where((r) => r.isCompleted).toList();
    if (completed.isEmpty) return AppStrings.get('my_results_empty', lang);
    return AppStrings.get('my_results_sub', lang)
        .replaceAll('{n}', '${completed.length}')
        .replaceAll('{p}', '${completed.where((r) => r.isPassed).length}');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final lang = context.watch<LanguageProvider>().lang;
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();
    final isDark = context.watch<ThemeProvider>().isDark;
    String s(String k) => AppStrings.get(k, lang);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(s('settings'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      // No text field lives directly on this body (edit/password sheets
      // already pad themselves for the keyboard via `_SheetShell`), so
      // resizing this whole settings list on every keyboard animation frame
      // is wasted relayout work.
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(s('settings')),
        automaticallyImplyLeading: !widget.embedded,
        leading: widget.embedded
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          // ── 1. Account ──
          if (auth.isLoggedIn)
            _AccountCard(
              auth: auth,
              lang: lang,
              onEditAccount: () => _showAccountSheet(lang),
            )
          else
            _GuestCard(
              lang: lang,
              onSignUp: () => _openAuth(signUp: true),
              onSignIn: () => _openAuth(signUp: false),
            ),
          const SizedBox(height: 12),

          // A new version waiting on Play is worth interrupting for; it sits
          // above everything else so it cannot be missed.
          const UpdateBanner(),

          // One calm PRO card: the status for a subscriber, the offer for
          // everyone else. The only PRO message on this screen.
          _ProEntryCard(lang: lang),
          const SizedBox(height: 20),

          // ONE FLAT LIST, SETTINGS ONLY. Every row is the same row — icon,
          // name, current value, and a chevron or a switch. Results used to sit
          // in the middle of it as big cards; they have a page of their own
          // now, behind one row below.
          _SectionLabel(text: s('section_study')),
          SettingsGroup(
            children: [
              SettingsRow(
                icon: Icons.skip_next_rounded,
                color: AppTheme.violet,
                title: s('auto_advance_setting'),
                subtitle: s('auto_advance_sub'),
                showChevron: false,
                trailing: BrandSwitch(
                  value: settings.autoAdvance,
                  onChanged: settings.setAutoAdvance,
                ),
                onTap: () => settings.setAutoAdvance(!settings.autoAdvance),
              ),
              SettingsRow(
                icon: Icons.menu_book_rounded,
                color: AppTheme.blueDark,
                title: s('auto_explanation'),
                subtitle: s('auto_explanation_sub'),
                showChevron: false,
                trailing: BrandSwitch(
                  value: settings.autoExplanation,
                  onChanged: settings.setAutoExplanation,
                ),
                onTap: () =>
                    settings.setAutoExplanation(!settings.autoExplanation),
              ),
              _DailyQuestionTile(lang: lang),
              // The slider lives in a sheet so this row looks like its
              // neighbours; the sheet is also where the live preview belongs.
              SettingsRow(
                icon: Icons.format_size_rounded,
                color: AppTheme.teal,
                title: s('text_size'),
                subtitle: settings.scaleLabel,
                onTap: () => _showTextSizeSheet(lang),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _SectionLabel(text: s('section_preferences')),
          SettingsGroup(
            children: [
              SettingsRow(
                icon: Icons.language_rounded,
                color: AppTheme.blueDark,
                title: s('language'),
                subtitle: context.watch<LanguageProvider>().langLabel,
                onTap: () => _showLanguageSheet(lang),
              ),
              SettingsRow(
                color: AppTheme.orange,
                icon: isDark
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                title: s('theme'),
                subtitle: isDark ? s('dark_mode') : s('light_mode'),
                showChevron: false,
                trailing: BrandSwitch(
                  value: isDark,
                  onChanged: (_) => context.read<ThemeProvider>().toggle(),
                ),
                onTap: () => context.read<ThemeProvider>().toggle(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _SectionLabel(text: s('section_results')),
          SettingsGroup(
            children: [
              SettingsRow(
                icon: Icons.bar_chart_rounded,
                color: AppTheme.blueDark,
                title: s('my_results'),
                subtitle: _resultsSummary(lang),
                onTap: () => Navigator.push(
                  context,
                  AppTheme.slideRoute(const _MyResultsPage()),
                ),
              ),
              SettingsRow(
                icon: Icons.insights_rounded,
                color: AppTheme.success,
                title: s('topic_stats'),
                subtitle: s('topic_stats_sub'),
                onTap: () => Navigator.push(
                  context,
                  AppTheme.slideRoute(const TopicStatsScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          const AboutGroup(),
        ],
      ),
    );
  }
}

/// The question-text size slider, with a sample rendered at that size.
///
/// The number ("110%") means nothing on its own; people judge this setting by
/// whether they can read the line, so the line is right underneath it.
class _TextSizeSheet extends StatelessWidget {
  final String lang;
  const _TextSizeSheet({required this.lang});

  @override
  Widget build(BuildContext context) {
    String s(String k) => AppStrings.get(k, lang);
    final settings = context.watch<SettingsProvider>();

    return _SheetShell(
      title: s('text_size'),
      children: [
        Text(
          s('text_size_hint'),
          style: TextStyle(fontSize: 12.5, color: AppTheme.textM(context)),
        ),
        Row(
          children: [
            Icon(
              Icons.text_fields_rounded,
              size: 16,
              color: AppTheme.textM(context),
            ),
            Expanded(
              child: Slider(
                value: settings.scale,
                min: SettingsProvider.minScale,
                max: SettingsProvider.maxScale,
                divisions: SettingsProvider.scaleDivisions,
                label: settings.scaleLabel,
                onChanged: (value) =>
                    context.read<SettingsProvider>().setScale(value),
              ),
            ),
            Icon(
              Icons.text_fields_rounded,
              size: 24,
              color: AppTheme.textM(context),
            ),
          ],
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.border(context)),
          ),
          child: Text(
            s('text_size_preview'),
            style: TextStyle(
              // The same 17 the question card uses, through the same scale.
              fontSize: 17 * settings.scale,
              fontWeight: FontWeight.w600,
              height: 1.5,
              color: AppTheme.textP(context),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: settings.isDefaultScale
                    ? null
                    : () => context.read<SettingsProvider>().resetScale(),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46)),
                child: Text(s('reset')),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(minimumSize: const Size(0, 46)),
                child: Text(s('great')),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Small caps heading above a group of rows.
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: AppTheme.textM(context),
        ),
      ),
    );
  }
}

/// The daily-question reminder, as an ordinary settings row.
///
/// It used to be a card of its own with two stacked tiles inside it. Now it is
/// a switch row like every other switch row; the time is edited by tapping the
/// same row once the reminder is on.
class _DailyQuestionTile extends StatefulWidget {
  final String lang;
  const _DailyQuestionTile({required this.lang});

  @override
  State<_DailyQuestionTile> createState() => _DailyQuestionTileState();
}

class _DailyQuestionTileState extends State<_DailyQuestionTile> {
  bool _enabled = false;
  int _hour = DailyQuestionService.defaultHour;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await DailyQuestionService.isEnabled();
    final hour = await DailyQuestionService.hour();
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _hour = hour;
      _busy = false;
    });
  }

  Future<void> _toggle(bool value) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final granted = await DailyQuestionService.setEnabled(
      value,
      lang: widget.lang,
      atHour: _hour,
    );
    if (!mounted) return;
    setState(() {
      _enabled = granted;
      _busy = false;
    });

    // The switch springing back with no explanation looks like a bug; it is
    // actually the OS saying no.
    if (value && !granted) {
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text(AppStrings.get('daily_question_denied', widget.lang)),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _pickHour() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: 0),
      builder: (context, child) => MediaQuery(
        // 24-hour, because that is how the time is written everywhere else in
        // this app and on every Uzbek timetable.
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;

    setState(() => _hour = picked.hour);
    await DailyQuestionService.setHour(picked.hour, lang: widget.lang);
  }

  @override
  Widget build(BuildContext context) {
    String s(String k) => AppStrings.get(k, widget.lang);
    final hourLabel = '${_hour.toString().padLeft(2, '0')}:00';

    return SettingsRow(
      icon: Icons.notifications_active_rounded,
      color: AppTheme.orange,
      title: s('daily_question'),
      subtitle: _enabled
          ? '${s('daily_question_time')}: $hourLabel'
          : s('daily_question_sub'),
      showChevron: false,
      trailing: _busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : BrandSwitch(value: _enabled, onChanged: _toggle),
      // Tapping the row changes the time once the reminder is on, and turns it
      // on when it is off — the switch is still there for the direct action.
      onTap: _busy ? null : (_enabled ? _pickHour : () => _toggle(true)),
    );
  }
}

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

// ───────────────────────── Account ─────────────────────────

class _AccountCard extends StatelessWidget {
  final AuthProvider auth;
  final String lang;

  /// Opens the whole account sheet — name, password, sign-out, deletion.
  /// The pencil used to edit only the name while everything else lived in a
  /// separate collapsible group further down, so the one obvious control for
  /// "my account" did the least of the things people came for.
  final VoidCallback onEditAccount;

  const _AccountCard({
    required this.auth,
    required this.lang,
    required this.onEditAccount,
  });

  @override
  Widget build(BuildContext context) {
    String s(String k) => AppStrings.get(k, lang);
    final name = auth.userName.trim();
    final hasName = name.isNotEmpty;
    // Phone accounts have no name and their `@pro.com` address must never be
    // shown, so fall back to a neutral glyph rather than a synthetic letter.
    final avatarLetter = hasName
        ? name[0].toUpperCase()
        : (auth.isPhoneAccount || auth.userEmail.isEmpty
              ? null
              : auth.userEmail[0].toUpperCase());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDeco(context, radius: AppTheme.radiusMd),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppTheme.brandFill(context),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: avatarLetter == null
                  ? const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 26,
                    )
                  : Text(
                      avatarLetter,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasName ? name : s('user_default_name'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textP(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      auth.isPhoneAccount
                          ? Icons.phone_iphone_rounded
                          : Icons.mail_outline_rounded,
                      size: 14,
                      color: AppTheme.textM(context),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        auth.displayIdentity,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textM(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onEditAccount,
            tooltip: s('section_account'),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.brandAccent(
                context,
              ).withValues(alpha: 0.1),
              foregroundColor: AppTheme.brandAccent(context),
            ),
            icon: const Icon(Icons.edit_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class _GuestCard extends StatelessWidget {
  final String lang;
  final VoidCallback onSignUp;
  final VoidCallback onSignIn;

  const _GuestCard({
    required this.lang,
    required this.onSignUp,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    String s(String k) => AppStrings.get(k, lang);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.cardDeco(context, radius: AppTheme.radiusMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.brandFill(context),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  size: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s('guest_mode'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textP(context),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      s('guest_mode_hint'),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.textM(context),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Creating an account is the primary path for a new user; signing in
          // is for people who already registered here or on the website.
          BrandButton(
            onPressed: onSignUp,
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: s('create_account_cta'),
          ),
          const SizedBox(height: 10),
          BrandButton(
            kind: BrandButtonKind.secondary,
            onPressed: onSignIn,
            icon: const Icon(Icons.login_rounded),
            label: s('have_account_sign_in'),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Building blocks ─────────────────────────

// ───────────────────────── PRO ─────────────────────────

/// Entry point to [ProScreen]. Until this card existed the whole PRO /
/// subscription screen was only reachable from the explanation sheet inside
/// a running test, so users had no way to see or buy a subscription from the
/// app's own settings.
class _ProEntryCard extends StatelessWidget {
  final String lang;
  const _ProEntryCard({required this.lang});

  @override
  Widget build(BuildContext context) {
    final sub = context.watch<SubscriptionProvider>();
    String s(String k) => AppStrings.get(k, lang);

    final isPro = sub.isPro;
    final info = sub.info;
    final subtitle = isPro && info != null
        ? '${info.daysRemaining} ${s('pro_days_left')} · ${info.expiryDateTashkent}'
        : s('pro_entry_subtitle');

    void open() =>
        Navigator.push(context, AppTheme.slideRoute(const ProScreen()));

    if (!isPro) {
      return ProUpsellCard(
        title: s('pro_title'),
        description: subtitle,
        action: s('get_pro'),
        onTap: open,
      );
    }

    return Material(
      color: AppTheme.card(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(color: AppTheme.hairline(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: open,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  size: 22,
                  color: AppTheme.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s('pro_active_title'),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppTheme.textP(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.mutedText(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.mutedText(context),
              ),
            ],
          ),
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

// ───────────────────────── Sheets ─────────────────────────

/// Shared chrome for the bottom sheets below.
class _SheetShell extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SheetShell({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    // The keyboard inset is read by [_KeyboardInset] below, NOT here. A modal
    // sheet has no Scaffold to resize for it, so something must depend on the
    // inset — but reading it in this build method would rebuild the whole
    // sheet, fields and all, on every frame of the keyboard animation. The
    // wrapper takes the already-built subtree as a `child`, so re-running it
    // re-wraps one widget instance and rebuilds nothing inside it.
    return _KeyboardInset(
      base: const EdgeInsets.fromLTRB(20, 14, 20, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.border(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppTheme.textP(context),
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

/// Adds the on-screen keyboard's height to [base]'s bottom.
///
/// The point is the `child`: it is constructed by the caller and handed over
/// whole, so rebuilding this widget when the inset changes leaves the subtree
/// untouched. Flutter sees the same widget instance and skips it.
class _KeyboardInset extends StatelessWidget {
  final EdgeInsets base;
  final Widget child;

  const _KeyboardInset({required this.base, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: base.copyWith(
        bottom: base.bottom + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: child,
    );
  }
}

class _LanguageSheet extends StatelessWidget {
  final String lang;
  final LanguageProvider provider;

  const _LanguageSheet({required this.lang, required this.provider});

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: AppStrings.get('language', lang),
      children: LanguageProvider.languages.map((l) {
        final code = l['code']!;
        final selected = code == provider.lang;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              onTap: () {
                provider.setLanguage(code);
                Navigator.pop(context);
              },
              child: Ink(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.brandAccent(context).withValues(alpha: 0.1)
                      : AppTheme.surface(context),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: selected
                        ? AppTheme.brandAccent(context)
                        : AppTheme.border(context),
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      size: 20,
                      color: selected
                          ? AppTheme.brandAccent(context)
                          : AppTheme.textM(context),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l['label']!,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: selected
                            ? AppTheme.brandAccent(context)
                            : AppTheme.textP(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Display-name editor. Pops `true` on success, `false` on failure, `null`
/// when dismissed without saving.
/// What the account sheet was closed with, so the caller can act once it is
/// off screen.
enum _AccountAction { nameSaved, nameFailed, password, logout, delete }

class _AccountSheet extends StatefulWidget {
  final String lang;
  final AuthProvider auth;

  const _AccountSheet({required this.lang, required this.auth});

  @override
  State<_AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends State<_AccountSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.auth.userName,
  );
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final name = _controller.text.trim();
    if (name.isEmpty || _saving) return;
    setState(() => _saving = true);
    final ok = await widget.auth.updateFullName(name);
    if (!mounted) return;
    Navigator.pop(
      context,
      ok ? _AccountAction.nameSaved : _AccountAction.nameFailed,
    );
  }

  @override
  Widget build(BuildContext context) {
    String s(String k) => AppStrings.get(k, widget.lang);

    return _SheetShell(
      title: s('section_account'),
      children: [
        Text(
          s('full_name'),
          style: TextStyle(fontSize: 12.5, color: AppTheme.textM(context)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _controller,
          enabled: !_saving,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(hintText: s('full_name')),
          onSubmitted: (_) => _saveName(),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _saving ? null : _saveName,
          style: ElevatedButton.styleFrom(minimumSize: const Size(0, 48)),
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(s('save')),
        ),
        const SizedBox(height: 18),
        Divider(height: 1, color: AppTheme.border(context)),
        const SizedBox(height: 6),
        SettingsRow(
          icon: Icons.key_rounded,
          color: AppTheme.blueDark,
          title: s('change_password'),
          onTap: () => Navigator.pop(context, _AccountAction.password),
        ),
        SettingsRow(
          icon: Icons.logout_rounded,
          title: s('logout'),
          destructive: true,
          showChevron: false,
          onTap: () => Navigator.pop(context, _AccountAction.logout),
        ),
        // Google Play requires an in-app way to delete the account.
        SettingsRow(
          icon: Icons.person_remove_rounded,
          title: s('delete_account'),
          subtitle: s('delete_account_sub'),
          destructive: true,
          showChevron: false,
          onTap: () => Navigator.pop(context, _AccountAction.delete),
        ),
      ],
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  final String lang;
  final AuthProvider auth;

  const _ChangePasswordSheet({required this.lang, required this.auth});

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final errKey = await widget.auth.updatePassword(
      currentPassword: _current.text,
      newPassword: _next.text,
    );
    if (!mounted) return;

    if (errKey == null) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _saving = false;
      _error = AppStrings.get(errKey, widget.lang);
    });
  }

  @override
  Widget build(BuildContext context) {
    String s(String k) => AppStrings.get(k, widget.lang);

    return Form(
      key: _formKey,
      child: _SheetShell(
        title: s('change_password'),
        children: [
          TextFormField(
            controller: _current,
            obscureText: true,
            enabled: !_saving,
            decoration: InputDecoration(hintText: s('current_password')),
            validator: (v) =>
                (v == null || v.isEmpty) ? s('auth_password_required') : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _next,
            obscureText: true,
            enabled: !_saving,
            decoration: InputDecoration(hintText: s('new_password_min_8')),
            validator: (v) => (v ?? '').length < UzPhone.minPasswordLength
                ? s('auth_error_weak_password')
                : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _confirm,
            obscureText: true,
            enabled: !_saving,
            decoration: InputDecoration(hintText: s('password_repeat')),
            validator: (v) =>
                v != _next.text ? s('auth_error_password_mismatch') : null,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: AppTheme.error, fontSize: 13),
            ),
          ],
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _saving ? null : _submit,
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 48)),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(s('save')),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Natijalarim ─────────────────────────

/// "Natijalarim": the headline numbers and both result lists on a page of
/// their own, so the settings tab holds settings and nothing else.
class _MyResultsPage extends StatefulWidget {
  const _MyResultsPage();

  @override
  State<_MyResultsPage> createState() => _MyResultsPageState();
}

class _MyResultsPageState extends State<_MyResultsPage> {
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
