import 'package:flutter/material.dart';

import '../screens/avtodrom_sim_screen.dart';
import '../services/app_strings.dart';
import '../theme/app_theme.dart';

/// Bosh ekrandagi «Avtodrom» kartasi: ko'k brend foni, chapda nom va izoh,
/// o'ngda qora Gentra (simulyatordagi mashina, `assets/branding/avtodrom_gentra.webp`).
///
/// Doimiy joy — hero tugmalaridan keyin, bo'lim plitkalaridan oldin: har
/// ochilishda bir xil joyda, lekin testga yo'lni to'smaydi.
///
/// Tor ekran (320 dp): matn ustuni `Expanded`, mashina qat'iy 104 px —
/// sarlavha 2 qatorga bo'linadi, hech narsa toshmaydi (`narrow_screen_test`).
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
            // Qat'iy balandlik: Row ichidagi rasm o'z balandligini chegaradan
            // oladi (cheksiz balandlikda Image.contain o'lchanmaydi).
            child: SizedBox(
              height: 132,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
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
                          const SizedBox(height: 6),
                          Text(
                            AppStrings.get('avtodrom_sim', lang),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppStrings.get('avtodrom_sim_sub', lang),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Mashina — qat'iy kenglik, pastki o'ng burchakka «o'tirgan».
                  SizedBox(
                    width: 104,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10, right: 2),
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: Image.asset(
                          'assets/branding/avtodrom_gentra.webp',
                          fit: BoxFit.contain,
                          // Rasm bo'lmasa (eski build) karta baribir ishlaydi.
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
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
