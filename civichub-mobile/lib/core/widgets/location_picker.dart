import 'package:flutter/material.dart';

import '../location/location_point.dart';
import '../location/location_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_button.dart';
import 'app_text_field.dart';
import 'location_map.dart';

class LocationPicker extends StatefulWidget {
  const LocationPicker({
    required this.addressController,
    required this.latitudeController,
    required this.longitudeController,
    this.enabled = true,
    this.locationService = const CivicLocationService(),
    super.key,
  });

  final TextEditingController addressController;
  final TextEditingController latitudeController;
  final TextEditingController longitudeController;
  final bool enabled;
  final CivicLocationService locationService;

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  bool _loading = false;
  String? _message;

  LocationPoint? get _point {
    final latitude = double.tryParse(widget.latitudeController.text.trim());
    final longitude = double.tryParse(widget.longitudeController.text.trim());
    if (latitude == null || longitude == null) {
      return null;
    }
    final point = LocationPoint(latitude: latitude, longitude: longitude);
    return point.isValid ? point : null;
  }

  @override
  Widget build(BuildContext context) {
    final point = _point;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          label: 'Address',
          controller: widget.addressController,
          hintText: 'Street address, nearby landmark, or pinned coordinate',
          textInputAction: TextInputAction.next,
          enabled: widget.enabled,
          validator: (value) => _requiredMax(
            value,
            requiredMessage: 'Address is required',
            maxLength: 500,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        LocationMap(
          point: point,
          selectable: widget.enabled,
          interactive: widget.enabled,
          onPointChanged: _applyPoint,
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 520;
            final latitudeField = AppTextField(
              label: 'Latitude',
              controller: widget.latitudeController,
              hintText: 'Optional',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              enabled: widget.enabled,
              validator: (value) =>
                  coordinateValidator(value, min: -90, max: 90),
              onChanged: (_) => setState(() {}),
            );
            final longitudeField = AppTextField(
              label: 'Longitude',
              controller: widget.longitudeController,
              hintText: 'Optional',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              enabled: widget.enabled,
              validator: (value) =>
                  coordinateValidator(value, min: -180, max: 180),
              onChanged: (_) => setState(() {}),
            );
            if (stacked) {
              return Column(
                children: [
                  latitudeField,
                  const SizedBox(height: AppSpacing.md),
                  longitudeField,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: latitudeField),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: longitudeField),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: _loading ? 'Getting Location...' : 'Use Current Location',
          icon: Icons.my_location_outlined,
          variant: AppButtonVariant.outline,
          onPressed: widget.enabled && !_loading ? _useCurrentLocation : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _message ??
              'Tap the map or drag the marker to set the report coordinates.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: _message == null ? AppColors.muted : AppColors.danger,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final point = await widget.locationService.currentLocation();
      if (!mounted) {
        return;
      }
      _applyPoint(point);
    } on CivicLocationException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _message = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _applyPoint(LocationPoint point) {
    widget.latitudeController.text = point.latitude.toStringAsFixed(7);
    widget.longitudeController.text = point.longitude.toStringAsFixed(7);
    if (widget.addressController.text.trim().isEmpty) {
      widget.addressController.text = point.fallbackAddress;
    }
    setState(() {
      _message = null;
    });
  }

  String? _requiredMax(
    String? value, {
    required String requiredMessage,
    required int maxLength,
  }) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return requiredMessage;
    }
    if (normalized.length > maxLength) {
      return 'Must be $maxLength characters or fewer';
    }
    return null;
  }

  static String? coordinateValidator(
    String? value, {
    required double min,
    required double max,
  }) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return null;
    }
    final parsed = double.tryParse(normalized);
    if (parsed == null) {
      return 'Enter a valid number';
    }
    if (parsed < min || parsed > max) {
      return 'Must be between $min and $max';
    }
    return null;
  }
}
