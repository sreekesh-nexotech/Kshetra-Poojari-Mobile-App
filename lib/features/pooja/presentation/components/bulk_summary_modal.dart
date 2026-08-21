import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/theme.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/ks_toast.dart';
import '../../application/providers/pooja_list_controller.dart';
import '../../application/states/pooja_list_state.dart';

/// Shows the bulk complete/cancel summary as a full-screen dialog (covers the
/// navbar, matching the design scrim). Selection is frozen while it is open, so
/// the summary is snapshotted from the current state.
Future<void> showBulkSummaryModal(BuildContext context, WidgetRef ref) async {
  final isCancel =
      ref.read(poojaListControllerProvider).bulkMode == BulkMode.cancel;
  final rows = ref.read(poojaSummaryRowsProvider);
  final total = ref.read(poojaSummaryTotalProvider);
  final controller = ref.read(poojaListControllerProvider.notifier);

  await showDialog<void>(
    context: context,
    barrierColor: AppColors.scrim,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(24.w),
      child: Container(
        width: 320.w,
        constraints: BoxConstraints(maxHeight: 600.h),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadii.card.r),
          boxShadow: AppShadows.poster(),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isCancel ? 'കാൻസൽ ചെയ്യണോ?' : 'സമ്മറി — പൂർത്തിയാക്കുക',
              style: AppText.malayalam(
                size: 18,
                weight: FontWeight.w700,
                color: AppColors.maroon,
                height: 1.35,
              ),
            ),
            SizedBox(height: 12.h),
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.creamInput,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: 280.h),
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          child: Column(
                            children: [
                              for (final r in rows)
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14.w,
                                    vertical: 8.h,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          r.name,
                                          style: AppText.malayalam(
                                            size: 14,
                                            weight: FontWeight.w600,
                                            color: AppColors.ink,
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        r.count,
                                        style: AppText.latin(
                                          size: 14,
                                          weight: FontWeight.w700,
                                          color: AppColors.maroon,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        color: AppColors.cream,
                        border: Border(
                          top: BorderSide(color: AppColors.border),
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 8.h,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ആകെ',
                            style: AppText.malayalam(
                              size: 13,
                              weight: FontWeight.w700,
                              color: AppColors.maroon,
                            ),
                          ),
                          Text(
                            total,
                            style: AppText.latin(
                              size: 14,
                              weight: FontWeight.w700,
                              color: AppColors.maroon,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isCancel) ...[
              SizedBox(height: 12.h),
              Text(
                'കാൻസൽ ചെയ്താൽ അഡ്മിൻ റീ-അസൈൻ ചെയ്യും.',
                style: AppText.malayalam(size: 12, color: AppColors.grayText),
              ),
            ],
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    controller.closeBulk();
                    Navigator.of(dialogContext).pop();
                  },
                  child: Padding(
                    padding: EdgeInsets.all(8.w),
                    child: Text(
                      'ബാക്ക്',
                      style: AppText.malayalam(
                        size: 14,
                        weight: FontWeight.w700,
                        color: AppColors.maroon,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    final toast = controller.applyBulk();
                    ref.read(toastProvider.notifier).show(toast);
                    Navigator.of(dialogContext).pop();
                  },
                  child: Container(
                    height: 40.h,
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.maroon,
                      borderRadius: BorderRadius.circular(AppRadii.input.r),
                    ),
                    child: Text(
                      isCancel ? 'കാൻസൽ ചെയ്യുക' : 'കൺഫേം ചെയ്യുക',
                      style: AppText.malayalam(
                        size: 14,
                        weight: FontWeight.w700,
                        color: AppColors.offWhite,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  // Scrim / back-button dismissals also clear the bulk mode.
  if (ref.read(poojaListControllerProvider).bulkMode != BulkMode.none) {
    controller.closeBulk();
  }
}
