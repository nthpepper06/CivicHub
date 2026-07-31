import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class CivicBackground extends StatelessWidget {
  const CivicBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF6F9FD), AppColors.background, Color(0xFFFDFEFF)],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -120,
            right: -90,
            child: _CivicGlow(color: AppColors.cyan, size: 260),
          ),
          const Positioned(
            bottom: -140,
            left: -110,
            child: _CivicGlow(color: AppColors.violet, size: 280),
          ),
          Positioned.fill(child: CustomPaint(painter: _CivicGridPainter())),
          child,
        ],
      ),
    );
  }
}

class _CivicGlow extends StatelessWidget {
  const _CivicGlow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.12), Colors.transparent],
          ),
        ),
      ),
    );
  }
}

class _CivicGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.035)
      ..strokeWidth = 1;
    const step = 42.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
