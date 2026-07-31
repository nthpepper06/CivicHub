import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

class MainShell extends StatelessWidget {
  const MainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.line),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: BottomNavigationBar(
                currentIndex: currentIndex,
                onTap: (index) {
                  navigationShell.goBranch(
                    index,
                    initialLocation: index == currentIndex,
                  );
                },
                selectedFontSize: 12,
                unselectedFontSize: 12,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.assignment_outlined),
                    activeIcon: Icon(Icons.assignment_rounded),
                    label: 'Reports',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.notifications_none_outlined),
                    activeIcon: Icon(Icons.notifications_rounded),
                    label: 'Alerts',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    activeIcon: Icon(Icons.person_rounded),
                    label: 'Profile',
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
