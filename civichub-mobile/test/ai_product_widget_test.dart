import 'package:civichub_mobile/features/ai/domain/repositories/ai_assist_repository.dart';
import 'package:civichub_mobile/features/reports/domain/repositories/reports_repository.dart';
import 'package:civichub_mobile/features/reports/presentation/screens/create_report_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  testWidgets('canceling AI description suggestion preserves typed text', (
    tester,
  ) async {
    final aiRepository = FakeAiAssistRepository();

    await _pumpCreateReport(tester, aiRepository);
    await _enterDescription(tester, 'Original field notes');
    await _requestSuggestion(tester);

    expect(find.text('Improve description?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Original field notes'), findsOneWidget);
    expect(aiRepository.improveDescriptionCalls, 1);
  });

  testWidgets('accepting AI description suggestion updates description field', (
    tester,
  ) async {
    final aiRepository = FakeAiAssistRepository();

    await _pumpCreateReport(tester, aiRepository);
    await _enterDescription(tester, 'Original field notes');
    await _requestSuggestion(tester);

    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();

    expect(find.text('Improved AI suggestion.'), findsOneWidget);
    expect(find.text('Original field notes'), findsNothing);
  });
}

Future<void> _pumpCreateReport(
  WidgetTester tester,
  FakeAiAssistRepository aiRepository,
) async {
  tester.view.physicalSize = const Size(1080, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ReportsRepository>.value(
          value: FakeReportsRepository(),
        ),
        RepositoryProvider<AiAssistRepository>.value(value: aiRepository),
      ],
      child: const MaterialApp(home: CreateReportScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _enterDescription(WidgetTester tester, String description) async {
  await tester.ensureVisible(find.byType(TextFormField).at(3));
  await tester.enterText(find.byType(TextFormField).at(3), 'Broken sidewalk');
  await tester.enterText(find.byType(TextFormField).at(4), description);
}

Future<void> _requestSuggestion(WidgetTester tester) async {
  final button = find.widgetWithText(OutlinedButton, 'Improve Description');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}
