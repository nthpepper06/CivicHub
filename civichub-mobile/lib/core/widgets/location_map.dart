import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../location/location_point.dart';
import '../location/map_tile_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

class LocationMap extends StatefulWidget {
  const LocationMap({
    required this.point,
    this.onPointChanged,
    this.height = 220,
    this.interactive = true,
    this.selectable = false,
    super.key,
  });

  final LocationPoint? point;
  final ValueChanged<LocationPoint>? onPointChanged;
  final double height;
  final bool interactive;
  final bool selectable;

  @override
  State<LocationMap> createState() => _LocationMapState();
}

class _LocationMapState extends State<LocationMap> {
  late final MapController _controller;

  static const _defaultCenter = LatLng(10.7769, 106.7009);

  @override
  void initState() {
    super.initState();
    _controller = MapController();
  }

  @override
  void didUpdateWidget(covariant LocationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final point = widget.point;
    if (point != null && point != oldWidget.point) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _controller.move(_toLatLng(point), _controller.camera.zoom);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final point = widget.point;
    final center = point == null ? _defaultCenter : _toLatLng(point);
    return Semantics(
      label: widget.selectable
          ? 'Interactive location map. Tap the map or drag the marker to choose a location.'
          : 'Report location map preview.',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: SizedBox(
          height: widget.height,
          child: FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: center,
              initialZoom: point == null ? 11 : 15,
              interactionOptions: InteractionOptions(
                flags: widget.interactive
                    ? InteractiveFlag.all
                    : InteractiveFlag.none,
              ),
              onTap: widget.selectable
                  ? (_, latLng) => _emit(latLng.latitude, latLng.longitude)
                  : null,
            ),
            children: [
              TileLayer(
                urlTemplate: MapTileConfig.openStreetMap.urlTemplate,
                userAgentPackageName:
                    MapTileConfig.openStreetMap.userAgentPackageName,
              ),
              if (point != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _toLatLng(point),
                      width: 56,
                      height: 56,
                      child: _LocationMarker(
                        draggable: widget.selectable,
                        onDragDelta: (delta) => _dragMarker(point, delta),
                      ),
                    ),
                  ],
                ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    MapTileConfig.openStreetMap.attribution,
                    onTap: null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _dragMarker(LocationPoint point, Offset delta) {
    if (!widget.selectable) {
      return;
    }
    final camera = _controller.camera;
    final projected = camera.projectAtZoom(_toLatLng(point));
    final moved = camera.unprojectAtZoom(projected + delta);
    _emit(moved.latitude, moved.longitude);
  }

  void _emit(double latitude, double longitude) {
    final next = LocationPoint(latitude: latitude, longitude: longitude);
    if (!next.isValid) {
      return;
    }
    widget.onPointChanged?.call(next);
  }

  LatLng _toLatLng(LocationPoint point) {
    return LatLng(point.latitude, point.longitude);
  }
}

class _LocationMarker extends StatelessWidget {
  const _LocationMarker({required this.draggable, required this.onDragDelta});

  final bool draggable;
  final ValueChanged<Offset> onDragDelta;

  @override
  Widget build(BuildContext context) {
    final marker = DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(Icons.location_pin, color: AppColors.primary, size: 42),
      ),
    );
    if (!draggable) {
      return marker;
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (details) => onDragDelta(details.delta),
      child: MouseRegion(cursor: SystemMouseCursors.grab, child: marker),
    );
  }
}
