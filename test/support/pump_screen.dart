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

  final tree = ProviderScope(
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
  );

  // Pump inside runAsync + precache so asset images (temple bg, deity
  // thumbnails) actually decode and appear in the golden — otherwise they
  // render blank and the pixel comparison is unfair.
  await tester.runAsync(() async {
    await tester.pumpWidget(tree);
    await tester.pump(const Duration(milliseconds: 100));
    for (final element in find.byType(Image).evaluate()) {
      final image = element.widget as Image;
      await precacheImage(image.image, element);
    }
  });

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}
