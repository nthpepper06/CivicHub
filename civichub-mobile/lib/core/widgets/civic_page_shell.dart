import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'app_responsive.dart';
import 'premium_surface.dart';

class CivicPageShell extends StatelessWidget {
  const CivicPageShell({
    required this.children,
    this.maxWidth = 920,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    super.key,
  });

  final List<Widget> children;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  @override
  Widget build(BuildContext context) {
    return ListView(
      keyboardDismissBehavior: keyboardDismissBehavior,
      padding: padding,
      children: [
        AppResponsive(
          maxWidth: maxWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    );
  }
}

class CivicHeroPanel extends StatelessWidget {
  const CivicHeroPanel({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      gradient: AppGradients.cityHero,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: AppColors.surface.withValues(alpha: 0.2),
              ),
            ),
            child: SizedBox(
              width: 54,
              height: 54,
              child: Icon(icon, color: AppColors.surface),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.surface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.surface.withValues(alpha: 0.76),
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.md),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class CivicFormSection extends StatelessWidget {
  const CivicFormSection({
    required this.title,
    required this.icon,
    required this.children,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ...children,
        ],
      ),
    );
  }
}
