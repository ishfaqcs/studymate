import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studentplanner/app/theme/app_theme.dart';
import 'package:studentplanner/features/more/more_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final width in <double>[320, 360, 390, 412, 480, 840]) {
    for (final brightness in Brightness.values) {
      testWidgets(
          'More is responsive at ${width.toInt()} in ${brightness.name}',
          (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 900);
        addTearDown(tester.view.reset);

        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode:
              brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
          home: const MoreScreen(),
        ));
        await tester.pumpAndSettle();

        expect(find.text('More'), findsOneWidget);
        expect(find.text('Account and academic'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
