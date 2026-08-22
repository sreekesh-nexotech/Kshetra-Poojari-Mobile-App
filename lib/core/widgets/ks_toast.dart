import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/config/constants.dart';
import '../../app/theme/colors.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/typography.dart';

/// A transient toast message. [raised] lifts it above the pooja selection bar
/// (design: bottom 216 vs 94) so the two never overlap.
class ToastData {
  const ToastData(this.message, {this.raised = false});
  final String message;
  final bool raised;
}

/// App-wide toast state. Lives in `core` because it is cross-cutting UI feedback
/// used by every feature (login success, check-in, bulk complete, undo…).
class ToastController extends StateNotifier<ToastData?> {
  ToastController() : super(null);

  Timer? _timer;

  /// Show [message]; auto-dismisses after [AppConstants.toastDuration].
  void show(String message, {bool raised = false}) {
    _timer?.cancel();
    state = ToastData(message, raised: raised);
    _timer = Timer(AppConstants.toastDuration, () => state = null);
  }

  void clear() {
    _timer?.cancel();
    state = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final toastProvider = StateNotifierProvider<ToastController, ToastData?>(
  (ref) => ToastController(),
);

/// Overlay host for [toastProvider], mounted once at the app root above all
/// screens and the navbar. Renders the maroon pill with the design's slide-up
/// fade-in.
class KsToastHost extends ConsumerWidget {
  const KsToastHost({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.watch(toastProvider);
    if (toast == null) return const SizedBox.shrink();

    return Positioned(
      left: 0,
      right: 0,
      bottom: (toast.raised ? 216 : 94).h,
      child: IgnorePointer(
        child: Center(
          child: TweenAnimationBuilder<double>(
            // Key by message so the animation replays on each new toast.
            key: ValueKey(toast.message),
            tween: Tween(begin: 0, end: 1),
            duration: AppConstants.shortAnim,
            curve: Curves.easeOut,
            builder: (context, t, child) => Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, (1 - t) * 8.h),
                child: child,
              ),
            ),
            // The host is mounted outside the Scaffold (see KsNavShell), so it
            // has no Material ancestor — without one Flutter paints the debug
            // yellow underline under the toast text.
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.maroon,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: AppShadows.poster(),
                ),
                child: Text(
                  toast.message,
                  style: AppText.malayalam(
                    size: 13,
                    weight: FontWeight.w700,
                    color: AppColors.offWhite,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
