import 'package:civichub_mobile/app/app.dart';
import 'package:civichub_mobile/app/routing/app_router.dart';
import 'package:civichub_mobile/app/routing/app_routes.dart';
import 'package:civichub_mobile/core/config/mock_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpApp(WidgetTester tester) async {
  AppRouter.router.go(AppRoutes.splash);
  await tester.pumpWidget(const CivicHubApp());
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Login render', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Log In').first);
    await tester.pumpAndSettle();

    expect(find.text('Citizen Login'), findsOneWidget);
    expect(find.text('citizen@civichub.vn'), findsOneWidget);
  });

  testWidgets('Home render', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Log In').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log In').last);
    await tester.pumpAndSettle();

    expect(find.text('Create Report'), findsOneWidget);
    expect(find.text('My Reports'), findsOneWidget);
    expect(find.text('Recent Reports'), findsOneWidget);
  });

  testWidgets('Profile render', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Log In').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log In').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();

    expect(find.text(MockCitizen.name), findsOneWidget);
    expect(find.text('Edit Profile'), findsOneWidget);
  });

  testWidgets('Bottom navigation changes tab', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Log In').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log In').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.assignment_outlined));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Reports'), findsWidgets);
    expect(find.text('Search reports'), findsOneWidget);
  });

  testWidgets('Password toggle', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Log In').first);
    await tester.pumpAndSettle();

    expect(find.byTooltip('Show password'), findsOneWidget);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Hide password'), findsOneWidget);
  });

  testWidgets('Reports placeholder', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Log In').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log In').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reports').last);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Search reports'), findsOneWidget);
    expect(find.text('Mock states'), findsOneWidget);
    expect(find.text('Loading reports'), findsWidgets);
  });
}
