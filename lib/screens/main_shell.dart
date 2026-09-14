import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/tab_visibility.dart';
import 'home_screen.dart';
import 'practice_setup_screen.dart';
import 'sections_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  /// Home · Bo'limlar · Test ishlash · Sozlamalar.
  ///
  /// Practice is a tab of its own because it is the thing people open the app
  /// to do; reaching it only through a card on the home screen put the app's
  /// main action one tap further away than its settings.
  static const _tabCount = 4;
  static const int sectionsTab = 1;
  static const int practiceTab = 2;
  static const int profileTab = 3;

  /// Tabs the user has actually opened. An [IndexedStack] builds every child
  /// eagerly, so start-up used to construct every screen (and run its
  /// initState work) before the first frame; unopened tabs are now a cheap
  /// placeholder until they are needed.
  final Set<int> _visited = {0};

  void switchTab(int index) {
    if (index < 0 || index >= _tabCount || index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
      _visited.add(index);
    });
  }

  Widget _buildTab(int index) {
    if (!_visited.contains(index)) return const SizedBox.shrink();
    switch (index) {
      case 0:
        return const HomeScreen();
      case sectionsTab:
        return const SectionsScreen();
      case practiceTab:
        return const PracticeSetupScreen(embedded: true);
      default:
        return const ProfileScreen(embedded: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    final selectedColor = AppTheme.primary(context);
    final unselectedColor = AppTheme.textM(context);
    final dark = AppTheme.isDark(context);
    final navBg = dark ? AppTheme.surfaceBg : Colors.white;

    return TabVisibility(
      activeIndex: _currentIndex,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [for (var i = 0; i < _tabCount; i++) _buildTab(i)],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: navBg,
            border: Border(top: BorderSide(color: AppTheme.border(context))),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.home_rounded,
                    label: AppStrings.get('nav_home', lang),
                    selected: _currentIndex == 0,
                    selectedColor: selectedColor,
                    unselectedColor: unselectedColor,
                    onTap: () => switchTab(0),
                  ),
                  _NavItem(
                    icon: Icons.apps_rounded,
                    label: AppStrings.get('nav_sections', lang),
                    selected: _currentIndex == sectionsTab,
                    selectedColor: selectedColor,
                    unselectedColor: unselectedColor,
                    onTap: () => switchTab(sectionsTab),
                  ),
                  _NavItem(
                    icon: Icons.play_circle_fill_rounded,
                    label: AppStrings.get('menu_test', lang),
                    selected: _currentIndex == practiceTab,
                    selectedColor: selectedColor,
                    unselectedColor: unselectedColor,
                    onTap: () => switchTab(practiceTab),
                  ),
                  _NavItem(
                    icon: Icons.settings_rounded,
                    label: AppStrings.get('nav_settings', lang),
                    selected: _currentIndex == profileTab,
                    selectedColor: selectedColor,
                    unselectedColor: unselectedColor,
                    onTap: () => switchTab(profileTab),
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color selectedColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? selectedColor : unselectedColor;
    // Expanded, not a fixed width: four tabs at 72 dp each left no room for a
    // Russian label on a 320 dp phone.
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: selected ? 24 : 0,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: selectedColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
