import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'config/constants.dart';
import 'router/app_router.dart';
import 'theme/theme.dart';

/// Root app widget: initialises ScreenUtil against the 375×812 design baseline
/// and wires the GoRouter + theme. Kept thin per the architecture.
class KshetraApp extends ConsumerWidget {
  const KshetraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScreenUtilInit(
      designSize: AppConstants.designSize,
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        final router = ref.watch(routerProvider);
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Kshetra Poojari',
          theme: buildAppTheme(),
          routerConfig: router,
          // Lock text scaling to 1.0 so the pixel-accurate layout is stable
          // across device font-size settings (per the coding standards).
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            minScaleFactor: 1,
            maxScaleFactor: 1,
            child: child!,
          ),
        );
      },
    );
  }
}
