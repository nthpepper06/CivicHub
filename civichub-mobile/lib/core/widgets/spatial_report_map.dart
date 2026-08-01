import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../location/map_tile_config.dart';
import '../location/report_map_point.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../../features/reports/domain/models/report_status.dart';
import '../../features/reports/presentation/widgets/report_status_chip.dart';

class SpatialReportMap extends StatefulWidget {
  const SpatialReportMap({
    required this.points,
    required this.excludedCount,
    required this.scopeLabel,
    required this.onOpenReport,
    this.height = 380,
    this.tileConfig = MapTileConfig.openStreetMap,
    super.key,
  });

  final List<ReportMapPoint> points;
  final int excludedCount;
  final String scopeLabel;
  final ValueChanged<int> onOpenReport;
  final double height;
  final MapTileConfig tileConfig;

  @override
  State<SpatialReportMap> createState() => _SpatialReportMapState();
}

class _SpatialReportMapState extends State<SpatialReportMap> {
  late final MapController _controller;
  int? _selectedReportId;
  String _cameraSignature = '';

  static const _defaultCenter = LatLng(10.7769, 106.7009);

  ReportMapPoint? get _selectedPoint {
    final id = _selectedReportId;
    if (id == null) {
      return null;
    }
    for (final point in widget.points) {
      if (point.reportId == id) {
        return point;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _controller = MapController();
  }

  @override
  void didUpdateWidget(covariant SpatialReportMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedReportId != null &&
        !widget.points.any((point) => point.reportId == _selectedReportId)) {
      _selectedReportId = null;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitCameraOnce());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedPoint;
    final center = widget.points.isEmpty
        ? _defaultCenter
        : _toLatLng(widget.points.first);
    return Semantics(
      label:
          'Spatial report map. ${widget.points.length} loaded reports are mapped.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MapSummary(
            scopeLabel: widget.scopeLabel,
            mappedCount: widget.points.length,
            excludedCount: widget.excludedCount,
            points: widget.points,
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: SizedBox(
              height: widget.height,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _controller,
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: widget.points.length == 1 ? 15 : 11,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: widget.tileConfig.urlTemplate,
                        userAgentPackageName:
                            widget.tileConfig.userAgentPackageName,
                      ),
                      MarkerLayer(
                        markers: [
                          for (final point in widget.points)
                            Marker(
                              point: _toLatLng(point),
                              width: 68,
                              height: 68,
                              child: _ReportMapMarker(
                                point: point,
                                selected: point.reportId == _selectedReportId,
                                onTap: () {
                                  setState(() {
                                    _selectedReportId = point.reportId;
                                  });
                                },
                              ),
                            ),
                        ],
                      ),
                      RichAttributionWidget(
                        attributions: [
                          TextSourceAttribution(widget.tileConfig.attribution),
                        ],
                      ),
                    ],
                  ),
                  if (widget.points.isEmpty)
                    const Positioned.fill(child: _NoMappedReportsOverlay()),
                  if (selected != null)
                    Positioned(
                      left: AppSpacing.md,
                      right: AppSpacing.md,
                      bottom: AppSpacing.md,
                      child: _SelectedReportCard(
                        point: selected,
                        onOpen: () => widget.onOpenReport(selected.reportId),
                        onClose: () {
                          setState(() => _selectedReportId = null);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _ReportMapLegend(points: widget.points),
          const SizedBox(height: AppSpacing.md),
          _AccessibleReportFallback(
            points: widget.points,
            onOpenReport: widget.onOpenReport,
          ),
        ],
      ),
    );
  }

  void _fitCameraOnce() {
    if (!mounted || widget.points.isEmpty) {
      return;
    }
    final signature = widget.points.map((point) => point.reportId).join(',');
    if (signature == _cameraSignature) {
      return;
    }
    _cameraSignature = signature;
    if (widget.points.length == 1) {
      _controller.move(_toLatLng(widget.points.first), 15);
      return;
    }
    _controller.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(widget.points.map(_toLatLng).toList()),
        padding: const EdgeInsets.all(48),
      ),
    );
  }

  LatLng _toLatLng(ReportMapPoint point) {
    return LatLng(point.point.latitude, point.point.longitude);
  }
}

class _ReportMapMarker extends StatelessWidget {
  const _ReportMapMarker({
    required this.point,
    required this.selected,
    required this.onTap,
  });

  final ReportMapPoint point;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = _statusStyle(point.statusKey);
    return Semantics(
      button: true,
      label: point.semanticLabel,
      child: Tooltip(
        message: '${point.title} - ${point.statusLabel}',
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 160),
            scale: selected ? 1.12 : 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: style.color.withValues(alpha: 0.16),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? style.color : AppColors.surface,
                  width: selected ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: style.color.withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(7),
                    child: Icon(style.icon, size: 24, color: style.color),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedReportCard extends StatelessWidget {
  const _SelectedReportCard({
    required this.point,
    required this.onOpen,
    required this.onClose,
  });

  final ReportMapPoint point;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Selected mapped report ${point.title}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      point.title.isEmpty ? 'Untitled report' : point.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close selected report',
                    onPressed: onClose,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ReportStatusChip(
                    status: ReportStatus.fromApiValue(point.statusKey),
                    compact: true,
                  ),
                  if (point.category != null)
                    _MapInfoPill(
                      icon: Icons.category_outlined,
                      label: point.category!,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _MapInfoLine(
                icon: Icons.place_outlined,
                label: point.locationLabel,
              ),
              if (point.department != null) ...[
                const SizedBox(height: AppSpacing.xs),
                _MapInfoLine(
                  icon: Icons.apartment_outlined,
                  label: point.department!,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open detail'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapSummary extends StatelessWidget {
  const _MapSummary({
    required this.scopeLabel,
    required this.mappedCount,
    required this.excludedCount,
    required this.points,
  });

  final String scopeLabel;
  final int mappedCount;
  final int excludedCount;
  final List<ReportMapPoint> points;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _MapInfoPill(
              icon: Icons.map_outlined,
              label: '$mappedCount loaded on map',
            ),
            _MapInfoPill(
              icon: Icons.location_off_outlined,
              label: '$excludedCount excluded coordinates',
            ),
            _MapInfoPill(icon: Icons.filter_alt_outlined, label: scopeLabel),
          ],
        ),
      ),
    );
  }
}

class _ReportMapLegend extends StatelessWidget {
  const _ReportMapLegend({required this.points});

  final List<ReportMapPoint> points;

  @override
  Widget build(BuildContext context) {
    final keys = <String>{for (final point in points) point.statusKey}.toList()
      ..sort();
    if (keys.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final key in keys)
          Tooltip(
            message: 'Marker shape and icon indicate ${_statusLabel(key)}',
            child: _MapInfoPill(
              icon: _statusStyle(key).icon,
              label: _statusLabel(key),
              color: _statusStyle(key).color,
            ),
          ),
      ],
    );
  }
}

class _AccessibleReportFallback extends StatelessWidget {
  const _AccessibleReportFallback({
    required this.points,
    required this.onOpenReport,
  });

  final List<ReportMapPoint> points;
  final ValueChanged<int> onOpenReport;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox.shrink();
    }
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: const Text('Accessible mapped report list'),
      subtitle: const Text('Use this list if the map is difficult to operate.'),
      children: [
        for (final point in points)
          ListTile(
            leading: Icon(_statusStyle(point.statusKey).icon),
            title: Text(point.title.isEmpty ? 'Untitled report' : point.title),
            subtitle: Text(point.locationLabel),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => onOpenReport(point.reportId),
          ),
      ],
    );
  }
}

class _NoMappedReportsOverlay extends StatelessWidget {
  const _NoMappedReportsOverlay();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface.withValues(alpha: 0.84),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.line),
          ),
          child: const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_off_outlined, color: AppColors.muted),
                SizedBox(height: AppSpacing.sm),
                Text('No mapped reports in the current result set.'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MapInfoLine extends StatelessWidget {
  const _MapInfoLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.muted),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.inkSoft,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _MapInfoPill extends StatelessWidget {
  const _MapInfoPill({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? AppColors.inkSoft;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: (color ?? AppColors.primary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: (color ?? AppColors.primary).withValues(alpha: 0.18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

ReportStatusStyle _statusStyle(String key) {
  return ReportStatusStyle.of(ReportStatus.fromApiValue(key));
}

String _statusLabel(String key) => ReportStatus.fromApiValue(key).label;
