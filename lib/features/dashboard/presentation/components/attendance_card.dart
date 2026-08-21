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
import 'slide_to_confirm.dart';

/// Collapsible attendance card: header status + (when expanded) check-in/out
/// times and the slide-to-confirm control, gated on location + premises.
class AttendanceCard extends ConsumerWidget {
  const AttendanceCard({super.key});

  void _confirm(BuildContext context, WidgetRef ref) {
    final block = ref.read(locationGateProvider.notifier).checkGate();
    if (block == GateBlock.locationOff) {
      showKsBlockDialog(
        context,
        title: GateCopy.locationOffTitle,
        message: GateCopy.locationOffMessage,
      );
      return;
    }
    if (block == GateBlock.outsidePremises) {
      showKsBlockDialog(
        context,
        title: GateCopy.outsideTitle,
        message: GateCopy.outsideMessage,
      );
      return;
    }
    final now = AppTime.clockLabel();
    final controller = ref.read(attendanceControllerProvider.notifier);
    if (!ref.read(attendanceControllerProvider).started) {
      controller.checkIn(now);
      ref.read(toastProvider.notifier).show('ചെക്ക്-ഇൻ മാർക്ക് ചെയ്തു ✓');
    } else {
      controller.checkOut(now);
      ref.read(toastProvider.notifier).show('ചെക്ക്-ഔട്ട് മാർക്ക് ചെയ്തു ✓');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final att = ref.watch(attendanceControllerProvider);

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
          if (att.expanded) ...[
            SizedBox(height: 12.h),
            if (att.started) ...[
              Row(
                children: [
                  _TimeColumn(label: 'ചെക്ക്-ഇൻ', time: att.checkInAt ?? '—'),
                  SizedBox(width: 32.w),
                  _TimeColumn(
                    label: 'ചെക്ക്-ഔട്ട്',
                    time: att.checkOutAt ?? '—',
                  ),
                ],
              ),
              SizedBox(height: 12.h),
            ],
            if (att.notDone)
              SlideToConfirm(
                label: att.slideLabel,
                onConfirmed: () => _confirm(context, ref),
              ),
            if (att.done)
              Text(
                '✓ ഇന്നത്തെ ഹാജർ പൂർത്തിയായി',
                style: AppText.malayalam(
                  size: 14,
                  weight: FontWeight.w700,
                  color: AppColors.maroon,
                ),
              ),
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
