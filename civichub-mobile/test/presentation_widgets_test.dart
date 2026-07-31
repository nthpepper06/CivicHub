import 'package:civichub_mobile/features/profile/presentation/widgets/profile_content.dart';
import 'package:civichub_mobile/features/reports/presentation/cubit/reports_cubit.dart';
import 'package:civichub_mobile/features/reports/presentation/cubit/reports_state.dart';
import 'package:civichub_mobile/features/reports/presentation/widgets/reports_header.dart';
import 'package:civichub_mobile/features/reports/presentation/widgets/reports_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  testWidgets(
    'ReportsHeader renders search, status, category, and sort state',
    (tester) async {
      final repository = FakeReportsRepository();
      final cubit = ReportsCubit(reportsRepository: repository);
      final searchController = TextEditingController();
      addTearDown(cubit.close);
      addTearDown(searchController.dispose);

      await tester.pumpWidget(
        BlocProvider.value(
          value: cubit,
          child: MaterialApp(
            home: Scaffold(
              body: ReportsHeader(
                state: ReportsState(
                  categories: [sampleCategory()],
                  sortOption: ReportsSortOption.titleAsc,
                  search: 'sidewalk',
                ),
                searchController: searchController,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('Title A-Z'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'sidewalk'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Roads'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'All'), findsOneWidget);
    },
  );

  testWidgets('ReportCard renders report summary without route chrome', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ReportCard(report: sampleReport())),
      ),
    );

    expect(find.text('Broken sidewalk'), findsOneWidget);
    expect(find.text('12 Nguyen Hue'), findsOneWidget);
    expect(find.text('Roads'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
  });

  testWidgets('ProfileContent renders header, account rows, and actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProfileContent(
              user: sampleUser(),
              isLoggingOut: false,
              onLogout: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Nguyen Minh Anh'), findsOneWidget);
    expect(find.text('minh.anh@civichub.vn'), findsWidgets);
    expect(find.text('+84 912 345 678'), findsOneWidget);
    expect(find.text('Citizen'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('2026-07-01'), findsOneWidget);
    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);
  });
}
