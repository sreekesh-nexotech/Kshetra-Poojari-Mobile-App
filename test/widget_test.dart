// Smoke test: the app boots to the home tab without throwing.
import 'package:flutter_test/flutter_test.dart';
import 'package:kshetra_poojari/app/bootstrap/app_bootstrap.dart';

void main() {
  testWidgets('App boots without exceptions', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });
}
