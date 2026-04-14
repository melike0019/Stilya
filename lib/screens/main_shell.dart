import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'home/home_screen.dart';
import 'wardrobe/wardrobe_screen.dart';
import 'outfit/outfit_screen.dart';
import 'planner/planner_screen.dart';
import 'profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    WardrobeScreen(),
    OutfitScreen(),
    PlannerScreen(),
    ProfileScreen(),
  ];

  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.home_outlined,    selectedIcon: Icons.home_rounded,        label: 'Ana Sayfa'),
    _NavItem(icon: Icons.checkroom_outlined, selectedIcon: Icons.checkroom,         label: 'Gardırop'),
    _NavItem(icon: Icons.style_outlined,   selectedIcon: Icons.style,               label: 'Kombin'),
    _NavItem(icon: Icons.calendar_month_outlined, selectedIcon: Icons.calendar_month, label: 'Ajanda'),
    _NavItem(icon: Icons.person_outline,   selectedIcon: Icons.person_rounded,      label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryRose.withAlpha(25),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        border: const Border(
          top: BorderSide(color: AppTheme.dividerColor, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_navItems.length, (i) {
              return _NavButton(
                item: _navItems[i],
                selected: _currentIndex == i,
                onTap: () => setState(() => _currentIndex = i),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: selected ? 44 : 36,
              height: selected ? 32 : 28,
              decoration: selected
                  ? BoxDecoration(
                      color: AppTheme.lightRose,
                      borderRadius: BorderRadius.circular(20),
                    )
                  : null,
              child: Icon(
                selected ? item.selectedIcon : item.icon,
                size: 20,
                color: selected ? AppTheme.primaryRose : AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 9,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppTheme.primaryRose : AppTheme.textLight,
                fontFamily: 'Poppins',
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}
