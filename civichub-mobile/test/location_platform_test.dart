import 'package:civichub_mobile/core/location/location_point.dart';
import 'package:civichub_mobile/core/location/report_map_projection.dart';
import 'package:civichub_mobile/core/location/location_service.dart';
import 'package:civichub_mobile/core/widgets/location_picker.dart';
import 'package:civichub_mobile/core/widgets/location_preview_card.dart';
import 'package:civichub_mobile/core/widgets/spatial_report_map.dart';
import 'package:civichub_mobile/features/reports/domain/models/report_status.dart';
import 'package:civichub_mobile/features/reports/domain/models/report_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('LocationPoint validates coordinate bounds and fallback address', () {
    const point = LocationPoint(latitude: 10.77689, longitude: 106.7009);

    expect(point.isValid, isTrue);
    expect(point.coordinatesLabel, '10.77689, 106.70090');
    expect(point.fallbackAddress, 'Pinned location at 10.77689, 106.70090');
    expect(
      const LocationPoint(latitude: 91, longitude: 106.7).isValid,
      isFalse,
    );
    expect(
      const LocationPoint(latitude: 10.7, longitude: 181).isValid,
      isFalse,
    );
  });

  test(
    'ReportMapProjection excludes null and invalid coordinates without 0,0 fallback',
    () {
      final result = ReportMapProjection.fromSummaries([
        _summary(1, latitude: 10.7, longitude: 106.7),
        _summary(2),
        _summary(3, latitude: 91, longitude: 106.7),
        _summary(4, latitude: 0, longitude: 0),
      ]);

      expect(result.points.map((point) => point.reportId), [1, 4]);
      expect(result.points.last.point.coordinatesLabel, '0.00000, 0.00000');
      expect(result.excluded, 2);
    },
  );

  testWidgets('LocationPicker writes current-location coordinates', (
    tester,
  ) async {
    final address = TextEditingController();
    final latitude = TextEditingController();
    final longitude = TextEditingController();
    addTearDown(address.dispose);
    addTearDown(latitude.dispose);
    addTearDown(longitude.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            child: LocationPicker(
              addressController: address,
              latitudeController: latitude,
              longitudeController: longitude,
              locationService: _FakeLocationService(
                point: const LocationPoint(
                  latitude: 10.77689,
                  longitude: 106.7009,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Use Current Location'));
    await tester.pumpAndSettle();

    expect(latitude.text, '10.7768900');
    expect(longitude.text, '106.7009000');
    expect(address.text, 'Pinned location at 10.77689, 106.70090');
  });

  testWidgets('LocationPicker preserves an existing address', (tester) async {
    final address = TextEditingController(text: 'City Hall');
    final latitude = TextEditingController();
    final longitude = TextEditingController();
    addTearDown(address.dispose);
    addTearDown(latitude.dispose);
    addTearDown(longitude.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LocationPicker(
            addressController: address,
            latitudeController: latitude,
            longitudeController: longitude,
            locationService: _FakeLocationService(
              point: const LocationPoint(latitude: 10.1, longitude: 106.2),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Use Current Location'));
    await tester.pumpAndSettle();

    expect(address.text, 'City Hall');
    expect(latitude.text, '10.1000000');
    expect(longitude.text, '106.2000000');
  });

  testWidgets('LocationPicker shows permission-denied fallback guidance', (
    tester,
  ) async {
    final address = TextEditingController();
    final latitude = TextEditingController();
    final longitude = TextEditingController();
    addTearDown(address.dispose);
    addTearDown(latitude.dispose);
    addTearDown(longitude.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LocationPicker(
            addressController: address,
            latitudeController: latitude,
            longitudeController: longitude,
            locationService: _FakeLocationService(
              error: const CivicLocationException(
                CivicLocationFailure.permissionDenied,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Use Current Location'));
    await tester.pumpAndSettle();

    expect(find.textContaining('permission was denied'), findsOneWidget);
    expect(latitude.text, isEmpty);
    expect(longitude.text, isEmpty);
  });

  testWidgets('LocationPreviewCard renders address and coordinates', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LocationPreviewCard(
            address: 'Ward 1',
            point: LocationPoint(latitude: 10.77689, longitude: 106.7009),
          ),
        ),
      ),
    );

    expect(find.text('Ward 1'), findsOneWidget);
    expect(find.text('10.77689, 106.70090'), findsOneWidget);
  });

  testWidgets('SpatialReportMap renders markers, summary, and fallback list', (
    tester,
  ) async {
    var openedId = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SpatialReportMap(
              points: ReportMapProjection.fromSummaries([
                _summary(7, latitude: 10.77689, longitude: 106.7009),
              ]).points,
              excludedCount: 2,
              scopeLabel: 'My reports, current loaded results',
              onOpenReport: (id) => openedId = id,
              height: 260,
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('1 loaded on map'), findsOneWidget);
    expect(find.text('2 excluded coordinates'), findsOneWidget);
    expect(find.text('Accessible mapped report list'), findsOneWidget);

    await tester.tap(find.text('Accessible mapped report list'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Mapped report 7'));
    await tester.tap(find.text('Mapped report 7'));

    expect(openedId, 7);
  });
}

CitizenReportSummary _summary(int id, {double? latitude, double? longitude}) {
  return CitizenReportSummary(
    id: id,
    title: 'Mapped report $id',
    address: 'Address $id',
    status: ReportStatus.pending,
    latitude: latitude,
    longitude: longitude,
    categoryName: 'Roads',
    departmentName: 'Public Works',
  );
}

class _FakeLocationService extends CivicLocationService {
  const _FakeLocationService({this.point, this.error});

  final LocationPoint? point;
  final CivicLocationException? error;

  @override
  Future<LocationPoint> currentLocation() async {
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return point!;
  }
}
