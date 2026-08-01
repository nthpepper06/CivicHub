import 'package:flutter/material.dart';

import '../location/location_point.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'location_map.dart';
import 'premium_surface.dart';

class LocationPreviewCard extends StatelessWidget {
  const LocationPreviewCard({
    required this.address,
    required this.point,
    this.onOpen,
    this.title = 'Location',
    super.key,
  });

  final String? address;
  final LocationPoint? point;
  final VoidCallback? onOpen;
  final String title;

  @override
  Widget build(BuildContext context) {
    final hasPoint = point != null;
    return PremiumSurface(
      padding: EdgeInsets.zero,
      onTap: hasPoint ? onOpen : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasPoint)
            LocationMap(point: point, height: 180, interactive: false)
          else
            const SizedBox(
              height: 124,
              child: Center(
                child: Icon(
                  Icons.location_off_outlined,
                  color: AppColors.muted,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (hasPoint && onOpen != null)
                      const Icon(Icons.open_in_full, color: AppColors.primary),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _LocationLine(
                  icon: Icons.place_outlined,
                  text: _valueOrDash(address),
                ),
                const SizedBox(height: AppSpacing.xs),
                _LocationLine(
                  icon: Icons.explore_outlined,
                  text: hasPoint ? point!.coordinatesLabel : '-',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _valueOrDash(String? value) {
    final normalized = value?.trim() ?? '';
    return normalized.isEmpty ? '-' : normalized;
  }
}

class _LocationLine extends StatelessWidget {
  const _LocationLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.muted),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
          ),
        ),
      ],
    );
  }
}
