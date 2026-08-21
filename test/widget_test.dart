// Smoke test: the app boots to the home tab without throwing.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kshetra_poojari/app/bootstrap/app_bootstrap.dart';

void main() {
  testWidgets('App boots without exceptions', (tester) async {
    // Test at a real phone surface — ScreenUtil's .w/.h ratios only stay
    // matched near the 375×812 design aspect (the app is portrait-locked).
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(375, 812);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildApp());
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });
}
