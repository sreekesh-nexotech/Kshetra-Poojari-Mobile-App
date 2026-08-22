import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/theme.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/ks_block_dialog.dart';
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
  final refundAmount = isCancel ? controller.selectedTotal : 0.0;

  var busy = false;

  await showDialog<void>(
    context: context,
    barrierColor: AppColors.scrim,
    // Cancelling moves money: once it is in flight the sheet must not be
    // dismissed out from under it.
    barrierDismissible: !isCancel,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => PopScope(
        canPop: !busy,
        child: Dialog(
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
                    'ഈ ബുക്കിംഗുകൾ കാൻസൽ ചെയ്യും. '
                    '₹${refundAmount.toStringAsFixed(0)} ഭക്തന് റീഫണ്ട് ചെയ്യും. '
                    'ഇത് തിരികെ എടുക്കാനാവില്ല.',
                    style: AppText.malayalam(
                      size: 12,
                      color: AppColors.grayText,
                      height: 1.5,
                    ),
                  ),
                ],
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: busy
                          ? null
                          : () {
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
                            color: busy
                                ? AppColors.grayInactive
                                : AppColors.maroon,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: busy
                          ? null
                          : () async {
                              if (!isCancel) {
                                // Completing is optimistic: close at once and let
                                // the request settle in the background.
                                Navigator.of(dialogContext).pop();
                                await _run(ref, controller);
                                return;
                              }
                              // Cancelling moves money — block until it lands.
                              setDialogState(() => busy = true);
                              final navigator = Navigator.of(dialogContext);
                              await _run(ref, controller);
                              if (navigator.canPop()) navigator.pop();
                            },
                      child: Container(
                        height: 40.h,
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: busy ? AppColors.rose : AppColors.maroon,
                          borderRadius: BorderRadius.circular(AppRadii.input.r),
                        ),
                        child: busy
                            ? SizedBox(
                                width: 18.w,
                                height: 18.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.offWhite,
                                ),
                              )
                            : Text(
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
      ),
    ),
  );

  // Scrim / back-button dismissals also clear the bulk mode.
  if (ref.read(poojaListControllerProvider).bulkMode != BulkMode.none) {
    controller.closeBulk();
  }
}

/// Applies the bulk action and surfaces whatever came back.
///
/// A `500` that already moved money is not a toast — it is a dead end the
/// poojari has to take to the temple office, so it gets a blocking dialog and
/// no retry affordance.
Future<void> _run(WidgetRef ref, PoojaListController controller) async {
  final toasts = ref.read(toastProvider.notifier);
  final context = ref.context;

  final outcome = await controller.applyBulk();

  if (outcome.needsManualReconciliation) {
    if (context.mounted) {
      await showKsBlockDialog(
        context,
        title: 'ഓഫീസുമായി ബന്ധപ്പെടുക',
        message:
            'റീഫണ്ട് ആരംഭിച്ചു, പക്ഷേ രേഖപ്പെടുത്താനായില്ല.\n'
            'റീഫണ്ട് ഐഡി: ${outcome.unreconciledRefundId}\n\n'
            'വീണ്ടും ശ്രമിക്കരുത് — രണ്ടു തവണ റീഫണ്ട് ആയേക്കാം.',
      );
    }
  } else if (outcome.toast.isNotEmpty) {
    toasts.show(outcome.toast);
  }

  // The list disagreed with the server; reload rather than leave it wrong.
  if (outcome.needsRefresh) await controller.refreshCurrent();
}
