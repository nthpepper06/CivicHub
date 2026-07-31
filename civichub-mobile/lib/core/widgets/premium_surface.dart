import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_elevation.dart';
import '../theme/app_gradients.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class PremiumSurface extends StatefulWidget {
  const PremiumSurface({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.gradient,
    this.borderColor,
    this.hoverable = true,
    this.radius = AppRadius.md,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;
  final Color? borderColor;
  final bool hoverable;
  final double radius;

  @override
  State<PremiumSurface> createState() => _PremiumSurfaceState();
}

class _PremiumSurfaceState extends State<PremiumSurface> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(widget.radius);
    final decoration = BoxDecoration(
      color: widget.gradient == null ? AppColors.surface : null,
      gradient: widget.gradient ?? AppGradients.surfaceGlow,
      borderRadius: borderRadius,
      border: Border.all(
        color:
            widget.borderColor ??
            (_hovered
                ? AppColors.primary.withValues(alpha: 0.24)
                : AppColors.line),
      ),
      boxShadow: _hovered ? AppElevation.hover : AppElevation.soft,
    );
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
      padding: widget.padding,
      decoration: decoration,
      child: widget.child,
    );

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: borderRadius,
          child: content,
        ),
      ),
    );
  }

  void _setHovered(bool value) {
    if (!widget.hoverable || _hovered == value) {
      return;
    }
    setState(() {
      _hovered = value;
    });
  }
}
