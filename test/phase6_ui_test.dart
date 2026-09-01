import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studentplanner/features/more/more_screen.dart';
import 'package:studentplanner/features/more/privacy_screen.dart';
import 'package:studentplanner/features/onboarding/onboarding_screen.dart';
import 'package:studentplanner/features/settings/data_backup_screen.dart';

Widget app(Widget child, {double textScale = 1}) => MaterialApp(
    home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: child));

void smallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('onboarding remains usable at 200 percent text on 320 width',
      (tester) async {
    smallScreen(tester);
    await tester.pumpWidget(app(const OnboardingScreen(), textScale: 2));
    await tester.pump();
    expect(find.text('Plan your semester'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('privacy explains local storage and permissions semantically',
      (tester) async {
    await tester.pumpWidget(app(const PrivacyScreen()));
    expect(find.text('Local-first by design'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Permissions'), 300);
    expect(find.text('Permissions'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
  });

  testWidgets('More uses grouped final product navigation', (tester) async {
    await tester.pumpWidget(app(const MoreScreen()));
    expect(find.text('Account and academic'), findsOneWidget);
    expect(find.text('Study'), findsOneWidget);
    expect(find.text('Application'), findsOneWidget);
    expect(find.byTooltip('Search StudyMate'), findsOneWidget);
  });

  testWidgets('full data deletion requires confirmation', (tester) async {
    await tester.pumpWidget(app(const DataBackupScreen()));
    await tester.tap(find.text('Delete all StudyMate data'));
    await tester.pumpAndSettle();
    expect(find.text('Delete all StudyMate data?'), findsOneWidget);
    expect(find.textContaining('cannot be undone'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });
}
