import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    required this.url,
    required this.fallback,
    this.fit = BoxFit.cover,
    this.semanticLabel,
    this.logicalWidth,
    this.logicalHeight,
    this.loading,
    super.key,
  });

  final String url;
  final Widget fallback;
  final BoxFit fit;
  final String? semanticLabel;
  final double? logicalWidth;
  final double? logicalHeight;
  final Widget? loading;

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    return Image.network(
      url,
      fit: fit,
      semanticLabel: semanticLabel,
      cacheWidth: _cacheDimension(logicalWidth, pixelRatio),
      cacheHeight: _cacheDimension(logicalHeight, pixelRatio),
      gaplessPlayback: true,
      filterQuality: FilterQuality.low,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return loading ?? const _DefaultLoading();
      },
      errorBuilder: (_, _, _) => fallback,
    );
  }

  int? _cacheDimension(double? logicalSize, double pixelRatio) {
    if (logicalSize == null || logicalSize <= 0) {
      return null;
    }
    return (logicalSize * pixelRatio).round();
  }
}

class _DefaultLoading extends StatelessWidget {
  const _DefaultLoading();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.softIcon,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
