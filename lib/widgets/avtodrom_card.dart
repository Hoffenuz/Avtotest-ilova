import 'package:flutter/material.dart';

import '../screens/avtodrom_sim_screen.dart';
import '../services/app_strings.dart';
import '../theme/app_theme.dart';

/// Bosh ekrandagi «Avtodrom» kartasi: ko'k brend foni, chapda nom va izoh,
/// o'ngda qora Gentra (simulyatordagi mashina, `assets/branding/avtodrom_gentra.webp`).
///
/// Doimiy joy — hero tugmalaridan keyin, bo'lim plitkalaridan oldin: har
/// ochilishda bir xil joyda, lekin testga yo'lni to'smaydi.
class AvtodromCard extends StatelessWidget {
  final String lang;
  const AvtodromCard({super.key, required this.lang});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTheme.radiusLg);
    return Semantics(
      button: true,
      label: AppStrings.get('avtodrom_sim', lang),
      child: Material(
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.blueDark, AppTheme.blue],
            ),
          ),
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              AppTheme.fadeRoute(const AvtodromSimScreen()),
            ),
            child: SizedBox(
              height: 112,
              child: Stack(
                children: [
                  // Mashina — o'ng tomonda, pastki chetga «o'tirgan».
                  Positioned(
                    right: -6,
                    bottom: 0,
                    top: 6,
                    child: Image.asset(
                      'assets/branding/avtodrom_gentra.webp',
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomRight,
                      // Rasm bo'lmasa (eski build) karta baribir ishlaydi.
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 150, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Text(
                              AppStrings.get('avtodrom_sim', lang),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                AppStrings.get('avtodrom_sim_new', lang),
                                style: const TextStyle(
                                  color: AppTheme.blueDark,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppStrings.get('avtodrom_sim_sub', lang),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
