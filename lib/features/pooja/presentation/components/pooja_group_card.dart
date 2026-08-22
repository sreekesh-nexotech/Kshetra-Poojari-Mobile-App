import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/ks_chips.dart';
import '../../../../core/widgets/ks_toast.dart';
import '../../application/models/pooja_view_models.dart';
import '../../application/providers/pooja_list_controller.dart';
import 'pooja_task_row.dart';
import 'task_checkbox.dart';

/// A pooja group: cream header (name + badges + count + select-all) over its
/// task rows.
class PoojaGroupCard extends ConsumerWidget {
  const PoojaGroupCard({super.key, required this.group});

  final PoojaGroupVm group;

  String get _headerMark => switch (group.check) {
    GroupCheck.all => '✓',
    GroupCheck.partial => '–',
    GroupCheck.none => '',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(poojaListControllerProvider.notifier);

    return AppCard(
      radius: 8,
      clip: true,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: group.hasPending
                ? () => controller.toggleGroup(group.pendingIds)
                : null,
            child: Container(
              color: AppColors.creamInput,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                children: [
                  if (group.hasPending) ...[
                    TaskCheckbox(
                      mark: _headerMark,
                      filled: group.check != GroupCheck.none,
                    ),
                    SizedBox(width: 10.w),
                  ],
                  Expanded(
                    child: Text(
                      group.name,
                      style: AppText.malayalam(
                        size: 16,
                        weight: FontWeight.w700,
                        color: AppColors.maroon,
                        height: 1.35,
                      ),
                    ),
                  ),
                  if (group.special) ...[
                    SizedBox(width: 8.w),
                    KsPill.special('സ്പെഷ്യൽ'),
                  ],
                  if (group.incentive) ...[
                    SizedBox(width: 8.w),
                    const KsIncentiveCoin(size: 18),
                  ],
                  SizedBox(width: 8.w),
                  KsCountPill(count: group.countLabel),
                ],
              ),
            ),
          ),
          for (final row in group.rows)
            PoojaTaskRow(
              row: row,
              onTap: () => controller.toggleTask(row.id),
              onUndo: () async {
                // Capture before the await — the notifier outlives the frame
                // but reading it after an async gap is a trap worth avoiding.
                final toasts = ref.read(toastProvider.notifier);
                final outcome = await controller.undo(row.id);
                if (outcome.toast.isEmpty) return;
                toasts.show(
                  outcome.toast,
                  raised: ref.read(poojaListControllerProvider).hasSelection,
                );
                if (outcome.needsRefresh) await controller.refreshCurrent();
              },
            ),
        ],
      ),
    );
  }
}
