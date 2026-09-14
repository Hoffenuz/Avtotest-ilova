import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/question.dart';
import '../providers/subscription_provider.dart';
import '../screens/pro_screen.dart';
import '../services/app_strings.dart';
import '../services/connectivity_service.dart';
import '../theme/app_theme.dart';

/// A question's explanation (`izoh`) — PRO only, everywhere, always.
///
/// THE GATE LIVES IN HERE ON PURPOSE (docs/MOBILE-CONTENT-PROMPT.md §4).
/// The explanation is the single most valuable thing PRO buys, and it is
/// reachable from several places — a running test, saved questions, the
/// mistakes list, search. If each of those decided for itself whether to show
/// it, the day someone adds a fifth entry point and forgets the check is the
/// day the paywall has a hole. So no caller is trusted with that decision:
/// they hand over a [Question], this widget decides what may be rendered.
/// The website learned the same lesson and moved its check into
/// `QuestionReviewCard`.
///
/// The check is deliberately TWO checks:
///   * a live `SubscriptionProvider` read, not a cached boolean, and
///   * a connectivity probe — otherwise switching to airplane mode after PRO
///     had been cached once would keep the explanations readable forever.
class ExplanationPanel extends StatefulWidget {
  final Question question;

  /// Language of the explanation text (`uz_lat` | `uz_cyr` | `ru`).
  final String lang;

  /// Language of the surrounding interface copy.
  final String uiLang;

  const ExplanationPanel({
    super.key,
    required this.question,
    required this.lang,
    required this.uiLang,
  });

  @override
  State<ExplanationPanel> createState() => _ExplanationPanelState();
}

class _ExplanationPanelState extends State<ExplanationPanel> {
  bool _checking = true;
  bool _online = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() => _checking = true);
    final online = await ConnectivityService.isOnline();
    if (!mounted) return;
    setState(() {
      _online = online;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sub = context.watch<SubscriptionProvider>();
    String s(String k) => AppStrings.get(k, widget.uiLang);

    // "Not asked yet" is not "no PRO". Showing the upsell during that window
    // told subscribers their explanation was locked, every time they opened
    // one before the access RPC had answered.
    if (sub.loading || (sub.isUnknown && sub.error == null)) {
      return const Padding(
        padding: EdgeInsets.only(top: 14),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.blue,
            ),
          ),
        ),
      );
    }

    if (!sub.isPro) {
      return ExplanationNotice(
        icon: Icons.workspace_premium_rounded,
        color: AppTheme.orange,
        message: s('explanation_pro_message'),
        actionLabel: s('pro_badge'),
        onAction: () =>
            Navigator.push(context, AppTheme.slideRoute(const ProScreen())),
      );
    }

    if (_checking) {
      return const Padding(
        padding: EdgeInsets.only(top: 14),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.blue,
            ),
          ),
        ),
      );
    }

    if (!_online) {
      return ExplanationNotice(
        icon: Icons.wifi_off_rounded,
        color: AppTheme.textM(context),
        message: s('explanation_offline_message'),
        actionLabel: s('explanation_offline_retry'),
        onAction: _check,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        widget.question.getIzoh(widget.lang),
        style: TextStyle(
          fontSize: 15,
          height: 1.6,
          color: AppTheme.textP(context),
        ),
      ),
    );
  }
}

/// The "why you can't read this" strip, shared by both refusal cases.
class ExplanationNotice extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const ExplanationNotice({
    super.key,
    required this.icon,
    required this.color,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13.5, color: color, height: 1.35),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
