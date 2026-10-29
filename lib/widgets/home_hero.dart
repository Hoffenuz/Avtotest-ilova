import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/app_strings.dart';
import '../services/question_service.dart';
import '../services/road_sign_service.dart';
import '../theme/app_theme.dart';

/// Bosh ekran hero'sining bezaklari — saytning bosh sahifasi (src/pages/Home.tsx)
/// bilan bir xil g'oya: nozik katak naqsh tepada ko'rinib pastga qarab yo'qoladi,
/// o'ng yuqorida ko'k-zangori yorug'lik. Matn va tugmalar ustida turadi, shuning
/// uchun juda yengil: o'qilishiga xalaqit bermasligi kerak.
class HeroBackdrop extends StatelessWidget {
  const HeroBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);
    return IgnorePointer(
      child: ExcludeSemantics(
        child: CustomPaint(
          painter: _HeroBackdropPainter(
            line: AppTheme.hairline(
              context,
            ).withValues(alpha: dark ? 0.55 : 0.9),
            glow: dark
                ? AppTheme.indigo.withValues(alpha: 0.22)
                : AppTheme.blue600.withValues(alpha: 0.10),
            glowEdge: AppTheme.cyan.withValues(alpha: dark ? 0.06 : 0.05),
          ),
        ),
      ),
    );
  }
}

class _HeroBackdropPainter extends CustomPainter {
  final Color line;
  final Color glow;
  final Color glowEdge;

  _HeroBackdropPainter({
    required this.line,
    required this.glow,
    required this.glowEdge,
  });

  static const double _cell = 34;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    // 1. Yorug'lik — o'ng yuqori burchakdan
    final glowCenter = Offset(size.width * 0.92, size.height * 0.04);
    final glowRadius = math.max(size.width, 320.0) * 0.85;
    canvas.drawCircle(
      glowCenter,
      glowRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [glow, glowEdge, glowEdge.withValues(alpha: 0)],
          stops: const [0, 0.55, 1],
        ).createShader(Rect.fromCircle(center: glowCenter, radius: glowRadius)),
    );

    // 2. Katak naqsh — yuqorida aniq, pastga va chetlarga qarab yo'qoladi
    final gridRect = Offset.zero & size;
    canvas.saveLayer(gridRect, Paint());
    final p = Paint()
      ..color = line
      ..strokeWidth = 1;
    for (double x = 0.5; x <= size.width; x += _cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0.5; y <= size.height; y += _cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
    final maskCenter = Offset(size.width / 2, 0);
    final maskRadius = math.max(size.width, size.height * 0.9);
    canvas.drawRect(
      gridRect,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = const RadialGradient(
          colors: [Colors.black, Colors.black, Colors.transparent],
          stops: [0, 0.3, 0.85],
        ).createShader(Rect.fromCircle(center: maskCenter, radius: maskRadius)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HeroBackdropPainter old) =>
      old.line != line || old.glow != glow || old.glowEdge != glowEdge;
}

/// Uchta haqiqiy yo'l belgisi (ilova ichidagi rasmlar) — nishon yonidagi bezak.
/// Biroz qiyshaygan, bir-birining ustiga tushgan: "yo'l belgilari va testlar"
/// degan mavzuni so'zsiz aytadi.
class HeroSignCluster extends StatelessWidget {
  const HeroSignCluster({super.key});

  static const _base = 'assets/tests-json/belgilar_images/';
  // belgilar.json: 3.24 "Yuqori tezlik cheklangan", 1.20 "Piyodalar o'tish joyi", 2.5 "STOP"
  static const _speed = '${_base}0bf7b8ee40de51f674a5973145ebc5f7.gif';
  static const _crossing = '${_base}e6fcea8ed20a3f1aebaffa7517c0a1d2.gif';
  static const _stop = '${_base}0e37af0ce40967f045f243d800743850.gif';

  @override
  Widget build(BuildContext context) {
    return const ExcludeSemantics(
      child: SizedBox(
        width: 112,
        height: 62,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              top: 12,
              child: _Sign(path: _speed, size: 44, angle: -0.16),
            ),
            Positioned(
              left: 32,
              top: 2,
              child: _Sign(path: _crossing, size: 50, angle: 0.06),
            ),
            Positioned(
              right: 0,
              top: 14,
              child: _Sign(path: _stop, size: 44, angle: 0.18),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sign extends StatelessWidget {
  final String path;
  final double size;
  final double angle;

  const _Sign({required this.path, required this.size, required this.angle});

  @override
  Widget build(BuildContext context) {
    // Soyasiz: belgilar shakli har xil (doira, uchburchak, sakkizburchak),
    // dumaloq soya uchburchak orqasida kulrang disk bo'lib ko'rinardi.
    // Rasmlarning o'z oq hoshiyasi qorong'i fonda ham ajratib turadi.
    return Transform.rotate(
      angle: angle,
      child: Image.asset(
        path,
        width: size,
        height: size,
        // 600×600 manba — kichik o'lchamda dekodlash xotirani tejaydi
        cacheWidth: (size * 3).round(),
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => SizedBox(width: size, height: size),
      ),
    );
  }
}

/// Bazadagi haqiqiy sonlar: savollar, variantlar, yo'l belgilari.
/// Qattiq yozilmaydi — baza yangilansa raqam o'zi o'zgaradi.
class _HeroCounts {
  final int questions;
  final int variants;
  final int signs;
  const _HeroCounts(this.questions, this.variants, this.signs);
}

Future<_HeroCounts>? _countsFuture;

Future<_HeroCounts> _loadCounts() {
  // Ikkala yuklash ham o'z keshidan o'tadi (QuestionService.warmUp bosh
  // ekranda bazani allaqachon o'qiydi), shuning uchun qo'shimcha xarajat yo'q.
  return _countsFuture ??= () async {
    try {
      final all = await QuestionService.loadAllQuestions();
      final groups = await RoadSignService.loadGroups();
      final signs = groups.fold<int>(0, (n, g) => n + g.items.length);
      return _HeroCounts(all.length, QuestionService.variantCount, signs);
    } catch (_) {
      // Xato keshda qolmasin — keyingi safar qayta uriniladi
      _countsFuture = null;
      rethrow;
    }
  }();
}

/// Hero'dagi uchta ko'rsatkich. Har biri bosiladi va tegishli bo'limga olib boradi.
class HeroStatsRow extends StatelessWidget {
  final String lang;
  final VoidCallback onQuestions;
  final VoidCallback onVariants;
  final VoidCallback onSigns;

  const HeroStatsRow({
    super.key,
    required this.lang,
    required this.onQuestions,
    required this.onVariants,
    required this.onSigns,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HeroCounts>(
      future: _loadCounts(),
      builder: (context, snap) {
        final c = snap.data;
        // Ma'lumot kelguncha ham xuddi shu balandlik — pastdagi tugmalar sakramaydi
        return Row(
          children: [
            Expanded(
              child: _StatTile(
                value: c?.questions,
                label: AppStrings.countNoun(
                  'questions',
                  c?.questions ?? 5,
                  lang,
                ),
                color: AppTheme.blue600,
                icon: Icons.quiz_outlined,
                onTap: onQuestions,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                value: c?.variants,
                label: AppStrings.countNoun('variants', c?.variants ?? 5, lang),
                color: AppTheme.indigo,
                icon: Icons.grid_view_rounded,
                onTap: onVariants,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                value: c?.signs,
                label: AppStrings.countNoun('signs', c?.signs ?? 5, lang),
                color: AppTheme.error,
                icon: Icons.traffic_rounded,
                onTap: onSigns,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  final int? value;
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _StatTile({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);
    final number = value == null ? '—' : AppStrings.groupDigits(value!);
    return Semantics(
      button: true,
      label: '$number $label',
      excludeSemantics: true,
      child: Material(
        color: AppTheme.card(context).withValues(alpha: dark ? 0.92 : 0.96),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            constraints: const BoxConstraints(minHeight: 84),
            padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.hairline(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: dark ? 0.22 : 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: dark ? Color.lerp(color, Colors.white, 0.35) : color,
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    number,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      letterSpacing: -0.3,
                      color: AppTheme.textP(context),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.2,
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
