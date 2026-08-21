import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kshetra_poojari/app/theme/theme.dart';

/// The design frame size — all goldens render at this surface.
const Size kFrame = Size(375, 812);

/// Pumps [screen] inside the same ProviderScope + ScreenUtilInit + theme the
/// app uses, at a fixed 375×812 surface, with optional provider [overrides]
/// (e.g. to force a checked-in / checked-out state for a golden variant).
Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  List<Override> overrides = const [],
  Size size = kFrame,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: ScreenUtilInit(
        designSize: kFrame,
        minTextAdapt: true,
        builder: (context, child) => MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          home: child,
        ),
        child: screen,
      ),
    ),
  );
  // Settle layout + the temple-bg image frame without waiting on toasts.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}
