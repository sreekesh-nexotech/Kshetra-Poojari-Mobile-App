import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/theme.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/device/location_gate.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/ks_block_dialog.dart';
import '../../application/states/pooja_list_state.dart';
import '../../application/providers/pooja_list_controller.dart';

/// The maroon bulk-action bar that rises when tasks are selected.
class SelectionActionBar extends ConsumerWidget {
  const SelectionActionBar({super.key});

  void _startComplete(BuildContext context, WidgetRef ref) {
    // Completion is premises-gated.
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
    ref.read(poojaListControllerProvider.notifier).openBulk(BulkMode.done);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(
      poojaListControllerProvider.select((s) => s.selectedCount),
    );
    final controller = ref.read(poojaListControllerProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.maroon,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: AppShadows.selectionBar(),
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                count.toString().padLeft(2, '0'),
                style: AppText.latin(
                  size: 16,
                  weight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
              SizedBox(width: 6.w),
              Text(
                'സെലക്ട് ചെയ്തു',
                style: AppText.malayalam(
                  size: 13,
                  weight: FontWeight.w600,
                  color: AppColors.cream,
                ),
              ),
              const Spacer(),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: controller.clearSelection,
                child: Text(
                  'ക്ലിയർ',
                  style: AppText.malayalam(
                    size: 12,
                    weight: FontWeight.w600,
                    color: AppColors.cream,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'കാൻസൽ',
                  variant: AppButtonVariant.outline,
                  radius: AppRadii.input,
                  fontSize: 14,
                  expanded: true,
                  onTap: () => controller.openBulk(BulkMode.cancel),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                flex: 2,
                child: AppButton(
                  label: 'പൂർത്തിയായി ✓',
                  variant: AppButtonVariant.primary,
                  fillColor: AppColors.white,
                  labelColor: AppColors.maroon,
                  radius: AppRadii.input,
                  fontSize: 14,
                  expanded: true,
                  onTap: () => _startComplete(context, ref),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
