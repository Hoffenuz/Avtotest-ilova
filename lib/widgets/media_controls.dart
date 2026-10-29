import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Savol videosi ustidagi boshqaruv elementlari — ramka ichida ham,
/// kattalashtirilgan ekranda ham bitta sodda uslub: qora yarim shaffof
/// dumaloq tugma, oq ikonka, yozuvsiz. Rangli ramka va matn ataylab yo'q.

/// Dumaloq ikonka-tugma (⛶, 🖼, ▶, ↻, ✕).
class MediaRoundButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;

  const MediaRoundButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.size = 32,
    this.iconSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.black.withValues(alpha: 0.55),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: iconSize, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Pastdagi ingichka progress chizig'i (0..1).
class MediaProgressLine extends StatelessWidget {
  final ValueListenable<double> progress;
  final double height;

  const MediaProgressLine({
    super.key,
    required this.progress,
    this.height = 2,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        height: height,
        child: ValueListenableBuilder<double>(
          valueListenable: progress,
          builder: (context, value, _) => Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              child: Container(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kichik oltin «PRO» belgisi (saytdagi bilan bir xil).
class ProBadge extends StatelessWidget {
  const ProBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFBBF24),
        borderRadius: BorderRadius.circular(3),
      ),
      child: const Text(
        'PRO',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          height: 1.5,
          color: Color(0xFF78350F),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
