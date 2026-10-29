import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';
import '../providers/readiness_provider.dart';
import '../services/app_strings.dart';
import '../services/readiness_service.dart';
import '../theme/app_theme.dart';

/// Readiness UI — the app's copies of the website's ReadinessStrip (home) and
/// ReadinessCard (results page), and the levels sheet behind the level chip.
///
/// Rules carried over from the site:
/// * the LEVEL NAME is the headline, the percent comes second — no "not
///   ready" / "weak" verdicts;
/// * colour follows the PERCENT (red < 40, amber < 65, green < 85, emerald),
///   not the level, so it never jumps colour at a level boundary;
/// * nothing that cannot be measured is shown as "0%";
/// * the home strip keeps ONE height in every state — skeleton, invitation,
///   data — so nothing below it moves when the answer arrives.

/// Colours for a percent (src/lib/readinessLevels.ts `toneOf`).
class ReadinessTone {
  final Color ring;
  final Color text;
  const ReadinessTone(this.ring, this.text);

  factory ReadinessTone.of(int percent, {required bool dark}) {
    if (percent >= 85) {
      return ReadinessTone(
        const Color(0xFF10B981),
        dark ? const Color(0xFF34D399) : const Color(0xFF047857),
      );
    }
    if (percent >= 65) {
      return ReadinessTone(
        const Color(0xFF22C55E),
        dark ? const Color(0xFF4ADE80) : const Color(0xFF15803D),
      );
    }
    if (percent >= 40) {
      return ReadinessTone(
        const Color(0xFFF59E0B),
        dark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
      );
    }
    return ReadinessTone(
      const Color(0xFFEF4444),
      dark ? const Color(0xFFF87171) : const Color(0xFFB91C1C),
    );
  }
}

String _levelName(int index, String lang) =>
    AppStrings.get('readiness_level${index.clamp(1, 6)}', lang);

String _toNextText(Readiness data, String lang) {
  final left = data.percentToNext;
  if (left == null || left <= 0) return AppStrings.get('readiness_title', lang);
  return AppStrings.get('readiness_to_next_level', lang)
      .replaceAll('{n}', '$left')
      .replaceAll('{name}', _levelName(data.levelIndex + 1, lang));
}

// ───────────────────────── Building blocks ─────────────────────────

class _Ring extends StatelessWidget {
  final int percent;
  final Color color;
  final double size;
  final double stroke;
  final double fontSize;

  const _Ring({
    required this.percent,
    required this.color,
    required this.size,
    required this.stroke,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: percent / 100),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOut,
        builder: (context, value, _) => CustomPaint(
          painter: _RingPainter(
            value: value,
            color: color,
            track: AppTheme.hairline(context),
            stroke: stroke,
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: EdgeInsets.all(stroke + 1),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '$percent'),
                      TextSpan(
                        text: '%',
                        style: TextStyle(
                          fontSize: fontSize * 0.62,
                          color: AppTheme.mutedText(context),
                        ),
                      ),
                    ],
                  ),
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textP(context),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final Color color;
  final Color track;
  final double stroke;

  _RingPainter({
    required this.value,
    required this.color,
    required this.track,
    required this.stroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arc = rect.deflate(stroke / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawArc(arc, 0, math.pi * 2, false, base);
    if (value <= 0) return;
    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(arc, -math.pi / 2, math.pi * 2 * value, false, fill);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color || old.track != track;
}

class _Bar extends StatelessWidget {
  final double value;
  final Color color;
  final double height;
  const _Bar({required this.value, required this.color, this.height = 6});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOut,
          builder: (context, v, _) => LinearProgressIndicator(
            value: v,
            minHeight: height,
            backgroundColor: AppTheme.hairline(context),
            color: color,
          ),
        ),
      ),
    );
  }
}

/// Small rounded label: the level name, a streak, an exam date.
class _Chip extends StatelessWidget {
  final String text;
  final Color color;
  final Color? textColor;
  final IconData? icon;
  final VoidCallback? onTap;

  const _Chip({
    required this.text,
    required this.color,
    this.textColor,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = textColor ?? color;
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.2,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return chip;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: chip,
    );
  }
}

Widget? _streakChip(Readiness data, String lang, {required bool dark}) {
  if (data.streakDays <= 1) return null;
  return _Chip(
    text: AppStrings.get(
      'readiness_streak',
      lang,
    ).replaceAll('{n}', '${data.streakDays}'),
    color: AppTheme.orange,
    // Tun rejimida to'q zarg'aldoq matn shaffof zarg'aldoq fonda o'qilmasdi
    textColor: dark ? const Color(0xFFFDBA74) : const Color(0xFFC2410C),
    icon: Icons.local_fire_department_rounded,
  );
}

/// A grey placeholder bar that breathes while the score is on its way.
class _Pulse extends StatefulWidget {
  final double width;
  final double height;
  const _Pulse({required this.width, required this.height});

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.45, end: 1.0).animate(_c),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppTheme.hairline(context),
          borderRadius: BorderRadius.circular(widget.height),
        ),
      ),
    );
  }
}

// ───────────────────────── Home strip ─────────────────────────

/// The readiness strip on the home screen, with the gap below it — or
/// nothing at all for a guest (the score needs an account). Whether it is
/// there is known from the first frame, so it never pops in.
class ReadinessStripSlot extends StatelessWidget {
  /// Opens the full card (results page).
  final VoidCallback onOpen;

  /// "Boshlash" when no test has been taken yet.
  final VoidCallback onStart;
  final double gap;

  const ReadinessStripSlot({
    super.key,
    required this.onOpen,
    required this.onStart,
    this.gap = 20,
  });

  @override
  Widget build(BuildContext context) {
    final readiness = context.watch<ReadinessProvider?>();
    if (readiness == null || !readiness.active) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: gap),
      child: ReadinessStrip(
        readiness: readiness,
        onOpen: onOpen,
        onStart: onStart,
      ),
    );
  }
}

class ReadinessStrip extends StatelessWidget {
  final ReadinessProvider readiness;
  final VoidCallback onOpen;
  final VoidCallback onStart;

  const ReadinessStrip({
    super.key,
    required this.readiness,
    required this.onOpen,
    required this.onStart,
  });

  /// The one height of the strip in every state. Text lines are sized by the
  /// user's font scale, so it grows with a large font but never with data.
  static double heightFor(BuildContext context) {
    final line = MediaQuery.textScalerOf(context).scale(17);
    // chip row (line + 6) · gap · bar · gap · hint line
    return 24 + math.max(44.0, 24 + 2 * line);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    final height = heightFor(context);
    final line = MediaQuery.textScalerOf(context).scale(17);
    final data = readiness.data;

    final Widget content;
    VoidCallback? onTap = onOpen;
    if (readiness.loading) {
      onTap = null;
      content = Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.hairline(context), width: 4),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Pulse(width: 120, height: 12),
                SizedBox(height: 10),
                _Pulse(width: 180, height: 6),
              ],
            ),
          ),
        ],
      );
    } else if (data == null || !data.hasData) {
      final invite = data != null; // no test yet — vs. nothing came back
      if (invite) onTap = onStart;
      content = Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.brandAccent(context).withValues(alpha: 0.12),
            ),
            child: Icon(
              Icons.track_changes_rounded,
              color: AppTheme.brandAccent(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.get('readiness_title', lang),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textP(context),
                  ),
                ),
                if (invite) ...[
                  const SizedBox(height: 2),
                  Text(
                    AppStrings.get('readiness_empty_hint', lang),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.25,
                      color: AppTheme.mutedText(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (invite)
            _SmallCta(
              label: AppStrings.get('readiness_empty_cta', lang),
              onTap: onStart,
            )
          else
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.mutedText(context),
            ),
        ],
      );
    } else {
      final tone = ReadinessTone.of(
        data.readinessPercent,
        dark: AppTheme.isDark(context),
      );
      final streak = _streakChip(data, lang, dark: AppTheme.isDark(context));
      content = Row(
        children: [
          _Ring(
            percent: data.readinessPercent,
            color: tone.ring,
            size: 44,
            stroke: 4,
            fontSize: 13,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: line + 6,
                  child: Row(
                    children: [
                      Flexible(
                        child: _Chip(
                          text: _levelName(data.levelIndex, lang),
                          color: tone.ring,
                          textColor: tone.text,
                        ),
                      ),
                      if (streak != null) ...[const SizedBox(width: 6), streak],
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // Progress INSIDE the current level, not the overall percent.
                _Bar(value: data.progressWithinLevel, color: tone.ring),
                const SizedBox(height: 6),
                SizedBox(
                  height: line,
                  child: Text(
                    _toNextText(data, lang),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.3,
                      color: AppTheme.mutedText(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, color: AppTheme.mutedText(context)),
        ],
      );
    }

    return Semantics(
      button: onTap != null,
      label: data != null && data.hasData
          ? '${AppStrings.get('readiness_title', lang)}: '
                '${_levelName(data.levelIndex, lang)}, ${data.readinessPercent}%'
          : null,
      child: Material(
        color: AppTheme.card(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          side: BorderSide(color: AppTheme.hairline(context)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

class _SmallCta extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SmallCta({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTheme.radiusSm);
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: radius,
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 15,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Full card ─────────────────────────

/// The full readiness card at the top of "Natijalarim". Nothing for a guest.
class ReadinessCard extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onReview;
  final double gap;

  const ReadinessCard({
    super.key,
    required this.onStart,
    required this.onReview,
    this.gap = 12,
  });

  @override
  Widget build(BuildContext context) {
    final readiness = context.watch<ReadinessProvider?>();
    if (readiness == null || !readiness.active) return const SizedBox.shrink();
    final lang = context.watch<LanguageProvider>().lang;
    String s(String k) => AppStrings.get(k, lang);
    final data = readiness.data;

    Widget shell(Widget child) => Container(
      margin: EdgeInsets.only(bottom: gap),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.hairline(context)),
      ),
      child: child,
    );

    if (readiness.loading) {
      return shell(
        const SizedBox(
          height: 150,
          child: Row(
            children: [
              _Pulse(width: 84, height: 84),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Pulse(width: 120, height: 16),
                    SizedBox(height: 12),
                    _Pulse(width: 160, height: 8),
                    SizedBox(height: 12),
                    _Pulse(width: 100, height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (data == null) {
      // Nothing came back and nothing is cached: a calm line, a retry.
      return shell(
        Row(
          children: [
            Icon(Icons.cloud_off_rounded, color: AppTheme.mutedText(context)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                s('readiness_unavailable'),
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppTheme.mutedText(context),
                ),
              ),
            ),
            TextButton(onPressed: readiness.refresh, child: Text(s('retry'))),
          ],
        ),
      );
    }

    if (!data.hasData) {
      return shell(
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.brandAccent(context).withValues(alpha: 0.12),
              ),
              child: Icon(
                Icons.track_changes_rounded,
                size: 28,
                color: AppTheme.brandAccent(context),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s('readiness_title'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textP(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s('readiness_empty_hint'),
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: AppTheme.mutedText(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _SmallCta(label: s('readiness_empty_cta'), onTap: onStart),
          ],
        ),
      );
    }

    final dark = AppTheme.isDark(context);
    final tone = ReadinessTone.of(data.readinessPercent, dark: dark);
    final streak = _streakChip(data, lang, dark: AppTheme.isDark(context));
    final measuredQuestions = data.questionsSeen > 0;

    return shell(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Ring(
                percent: data.readinessPercent,
                color: tone.ring,
                size: 84,
                stroke: 8,
                fontSize: 22,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The level name is the headline; the percent is in the
                    // ring. No verdict words.
                    Text(
                      _levelName(data.levelIndex, lang),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        color: tone.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s('readiness_title'),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.mutedText(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Chip(
                          text: s('readiness_levels_open'),
                          color: AppTheme.brandAccent(context),
                          icon: Icons.stairs_rounded,
                          onTap: () => showReadinessLevels(context, data),
                        ),
                        ?streak,
                        _ExamDateChip(data: data, lang: lang),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (data.percentToNext != null && data.percentToNext! > 0) ...[
            const SizedBox(height: 12),
            Text(
              _toNextText(data, lang),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textS(context),
              ),
            ),
            const SizedBox(height: 6),
            _Bar(value: data.progressWithinLevel, color: tone.ring),
          ],
          const SizedBox(height: 16),
          // Weight order, as on the site: variants, tests, accuracy,
          // coverage, mastery.
          _Metric(
            label: s('readiness_variants'),
            percent: data.variantsPercent,
            detail: '${data.variantsPassed}/${data.variantsTotal}',
            color: tone.ring,
          ),
          _Metric(
            label: s('readiness_tests'),
            percent: data.testsPercent,
            detail: '${data.testsTotal}/${data.testsTarget}',
            color: tone.ring,
          ),
          _Metric(
            label: s('readiness_accuracy'),
            percent: data.accuracyPercent,
            detail: s('readiness_accuracy_detail'),
            color: tone.ring,
          ),
          // Not measurable before any question has been answered: hidden,
          // never shown as a false "0%".
          if (measuredQuestions) ...[
            _Metric(
              label: s('readiness_coverage'),
              percent: data.coveragePercent,
              detail: '${data.questionsSeen}/${data.questionsTotal}',
              color: tone.ring,
            ),
            _Metric(
              label: s('readiness_mastery'),
              percent: data.masteryPercent,
              detail: '${data.questionsMastered}/${data.questionsSeen}',
              color: tone.ring,
            ),
          ],
          if (data.questionsToReview > 0) ...[
            const SizedBox(height: 6),
            _ReviewButton(
              count: data.questionsToReview,
              lang: lang,
              onTap: onReview,
            ),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final int percent;
  final String detail;
  final Color color;

  const _Metric({
    required this.label,
    required this.percent,
    required this.detail,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: label,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textP(context),
                        ),
                      ),
                      TextSpan(
                        text: '  $detail',
                        style: TextStyle(color: AppTheme.mutedText(context)),
                      ),
                    ],
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              Text(
                '$percent%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textP(context),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          _Bar(value: percent / 100, color: color, height: 5),
        ],
      ),
    );
  }
}

class _ReviewButton extends StatelessWidget {
  final int count;
  final String lang;
  final VoidCallback onTap;

  const _ReviewButton({
    required this.count,
    required this.lang,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);
    return Material(
      color: AppTheme.error.withValues(alpha: dark ? 0.14 : 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          child: Row(
            children: [
              const Icon(Icons.cancel_outlined, color: AppTheme.error),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.get('my_errors', lang),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textP(context),
                      ),
                    ),
                    Text(
                      AppStrings.get(
                        'readiness_review_hint',
                        lang,
                      ).replaceAll('{n}', '$count'),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.mutedText(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                AppStrings.get('readiness_review_cta', lang),
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.error,
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppTheme.error,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Optional exam date: a small button until one is set, then "Imtihonga N
/// kun". Never asked for.
class _ExamDateChip extends StatelessWidget {
  final Readiness data;
  final String lang;
  const _ExamDateChip({required this.data, required this.lang});

  Future<void> _pick(BuildContext context) async {
    final readiness = context.read<ReadinessProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = data.examDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current != null && !current.isBefore(today)
          ? current
          : today.add(const Duration(days: 14)),
      firstDate: today,
      lastDate: today.add(const Duration(days: 366)),
      helpText: AppStrings.get('readiness_exam_date_label', lang),
    );
    if (picked == null) return;
    final ok = await readiness.saveExamDate(picked);
    if (!ok) {
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.get('sync_failed', lang))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = data.daysToExam;
    final String text;
    if (data.examDate == null || days == null) {
      text = AppStrings.get('readiness_exam_date_add', lang);
    } else if (days < 0) {
      text = AppStrings.get('readiness_exam_date_past', lang);
    } else if (days == 0) {
      text = AppStrings.get('readiness_exam_today', lang);
    } else {
      text = AppStrings.get(
        'readiness_exam_in_days',
        lang,
      ).replaceAll('{n}', '$days');
    }
    return _Chip(
      text: text,
      color: AppTheme.textM(context),
      textColor: AppTheme.textS(context),
      icon: Icons.event_rounded,
      onTap: () => _pick(context),
    );
  }
}

// ───────────────────────── Levels sheet ─────────────────────────

/// All six levels, the current one marked, the reached ones ticked, and how
/// the percent is made up — opened from the "Darajalar" chip.
Future<void> showReadinessLevels(BuildContext context, Readiness data) {
  final lang = context.read<LanguageProvider>().lang;
  String s(String k) => AppStrings.get(k, lang);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.card(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final dark = AppTheme.isDark(ctx);
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.hairline(ctx),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  s('readiness_levels_title'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textP(ctx),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s('readiness_levels_subtitle'),
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.mutedText(ctx),
                  ),
                ),
                const SizedBox(height: 14),
                for (final level in readinessLevels) ...[
                  _LevelRow(
                    level: level,
                    lang: lang,
                    current: level.index == data.levelIndex,
                    reached: data.readinessPercent >= level.minPercent,
                    dark: dark,
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 8),
                Text(
                  s('readiness_levels_how_title'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textP(ctx),
                  ),
                ),
                const SizedBox(height: 6),
                // Weight order: variants, tests, accuracy, coverage, mastery.
                for (final k in const [
                  'readiness_levels_how3',
                  'readiness_levels_how5',
                  'readiness_levels_how1',
                  'readiness_levels_how2',
                  'readiness_levels_how4',
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '· ${s(k)}',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: AppTheme.mutedText(ctx),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _LevelRow extends StatelessWidget {
  final ReadinessLevel level;
  final String lang;
  final bool current;
  final bool reached;
  final bool dark;

  const _LevelRow({
    required this.level,
    required this.lang,
    required this.current,
    required this.reached,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    final tone = ReadinessTone.of(level.minPercent, dark: dark);
    final accent = AppTheme.brandAccent(context);
    final range = level.maxPercent >= 100
        ? AppStrings.get(
            'readiness_levels_from',
            lang,
          ).replaceAll('{n}', '${level.minPercent}')
        : AppStrings.get('readiness_levels_range', lang)
              .replaceAll('{a}', '${level.minPercent}')
              .replaceAll('{b}', '${level.maxPercent}');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: current
            ? accent.withValues(alpha: dark ? 0.14 : 0.05)
            : AppTheme.card(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: current
              ? accent.withValues(alpha: 0.45)
              : AppTheme.hairline(context),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tone.ring.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(color: tone.ring.withValues(alpha: 0.3)),
            ),
            child: Text(
              '${level.index}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: tone.text,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _levelName(level.index, lang),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textP(context),
                        ),
                      ),
                    ),
                    if (current) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          AppStrings.get('readiness_levels_current', lang),
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  range,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.mutedText(context),
                  ),
                ),
              ],
            ),
          ),
          if (reached)
            const Icon(
              Icons.check_circle_rounded,
              size: 20,
              color: AppTheme.success,
            ),
        ],
      ),
    );
  }
}
