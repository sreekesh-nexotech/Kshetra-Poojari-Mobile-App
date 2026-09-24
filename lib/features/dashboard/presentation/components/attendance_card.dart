import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/device/location_gate.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/ks_block_dialog.dart';
import '../../../../core/widgets/ks_chevron.dart';
import '../../../../core/widgets/ks_toast.dart';
import '../../application/providers/attendance_controller.dart';
import '../../application/providers/temple_location_controller.dart';
import '../../application/states/check_in_result.dart';
import 'slide_to_confirm.dart';

/// Collapsible attendance card: header status + (when expanded) the
/// check-in time, or the slide-to-confirm control before it's marked —
/// geofenced against the temple radius the server hands out. Check-out
/// isn't a thing the backend tracks, so there is nothing to offer once
/// checked in for the day.
class AttendanceCard extends ConsumerWidget {
  const AttendanceCard({super.key});

  /// The whole geofence lives in [AttendanceController.checkIn]; this only
  /// renders whichever way it said no. A block is a popup — it is a state the
  /// poojari has to do something about — while an ordinary failure (offline,
  /// server down) is a toast, because retrying is the only response to it.
  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    if (ref.read(attendanceControllerProvider).started) return;

    // Waits on the server (see AttendanceController.checkIn doc) — the
    // card only flips once the mark actually lands, and a failure shows
    // its real reason instead of a false "✓ marked" toast.
    final now = AppTime.clockLabel();
    final controller = ref.read(attendanceControllerProvider.notifier);
    final result = await controller.checkIn(now);

    if (result.ok) {
      ref.read(toastProvider.notifier).show('ചെക്ക്-ഇൻ മാർക്ക് ചെയ്തു ✓');
      return;
    }

    // Dropped because one was already running — that one will report.
    if (result.block == CheckInBlock.busy) return;

    if (result.block == CheckInBlock.failed) {
      ref.read(toastProvider.notifier).show(result.message);
      return;
    }

    if (!context.mounted) return;
    await showKsBlockDialog(
      context,
      title: result.title,
      message: result.message,
      actionLabel: result.opensSettings ? 'സെറ്റിങ്സ് തുറക്കുക' : null,
      onAction: result.opensSettings
          ? () => controller.openSettingsFor(result)
          : null,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final att = ref.watch(attendanceControllerProvider);
    // No site configured means every mark comes back 409 — grey the control
    // out rather than let the poojari drag into a guaranteed refusal.
    final unconfigured = ref.watch(templeLocationUnconfiguredProvider);

    return AppCard(
      elevated: true,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => ref
                .read(attendanceControllerProvider.notifier)
                .toggleExpanded(),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'ഇന്നത്തെ ഹാജർ',
                    style: AppText.malayalam(
                      size: 16,
                      weight: FontWeight.w700,
                      color: AppColors.maroon,
                    ),
                  ),
                ),
                Text(
                  att.statusLabel,
                  style: AppText.malayalam(
                    size: 12,
                    weight: FontWeight.w600,
                    color: att.started ? AppColors.maroon : AppColors.grayText,
                  ),
                ),
                SizedBox(width: 10.w),
                KsChevron(angleDeg: att.expanded ? -45 : 135),
              ],
            ),
          ),
          // Check-out isn't offered — the backend has no field for it at all
          // (attendance is one present/absent/leave mark per calendar day,
          // not a punch pair; poojari-app.md §5). Once checked in there is
          // nothing further to confirm, so the card just shows the mark.
          if (att.expanded) ...[
            SizedBox(height: 12.h),
            if (att.started)
              _TimeColumn(label: 'ചെക്ക്-ഇൻ', time: att.checkInAt ?? '—')
            else
              SlideToConfirm(
                label: att.slideLabel,
                enabled: !unconfigured,
                busy: att.checkingIn,
                onConfirmed: () => _confirm(context, ref),
              ),
            if (!att.started && unconfigured) ...[
              SizedBox(height: 8.h),
              Text(
                GateCopy.noTempleLocationMessage,
                style: AppText.malayalam(
                  size: 12,
                  color: AppColors.grayText,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _TimeColumn extends StatelessWidget {
  const _TimeColumn({required this.label, required this.time});

  final String label;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.malayalam(size: 12, color: AppColors.grayText),
        ),
        SizedBox(height: 2.h),
        Text(
          time,
          style: AppText.latin(
            size: 14,
            weight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}
