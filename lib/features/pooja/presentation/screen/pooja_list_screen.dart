import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/ks_temple_background.dart';
import '../../application/providers/pooja_list_controller.dart';
import '../../application/states/pooja_list_state.dart';
import '../components/bulk_summary_modal.dart';
import '../components/god_picker.dart';
import '../components/pooja_group_card.dart';
import '../components/selection_action_bar.dart';
import '../components/status_filter_chips.dart';

/// Pooja tab — grouped task checklist with filters, bulk select and undo.
class PoojaListScreen extends ConsumerWidget {
  const PoojaListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Open the confirm modal when a bulk action begins.
    ref.listen(poojaListControllerProvider.select((s) => s.bulkMode), (
      prev,
      next,
    ) {
      if (next != BulkMode.none && (prev == null || prev == BulkMode.none)) {
        showBulkSummaryModal(context, ref);
      }
    });

    final groups = ref.watch(poojaGroupsProvider);
    final isEmpty = ref.watch(poojaListEmptyProvider);
    final hasSelection = ref.watch(
      poojaListControllerProvider.select((s) => s.hasSelection),
    );

    return Stack(
      children: [
        const KsTempleBackground(flipped: true),
        SafeArea(
          bottom: false,
          child: Column(
            children: [
              SizedBox(height: 50.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 17.w),
                child: const GodPicker(),
              ),
              SizedBox(height: 12.h),
              const StatusFilterChips(),
              SizedBox(height: 12.h),
              Expanded(
                child: isEmpty
                    ? _EmptyList(bottomInset: hasSelection ? 170 : 24)
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                          16.w,
                          12.h,
                          16.w,
                          (hasSelection ? 170 : 24).h,
                        ),
                        itemCount: groups.length,
                        separatorBuilder: (_, _) => SizedBox(height: 12.h),
                        itemBuilder: (_, i) => PoojaGroupCard(group: groups[i]),
                      ),
              ),
            ],
          ),
        ),
        if (hasSelection)
          Positioned(
            left: 12.w,
            right: 12.w,
            bottom: 12.h,
            child: const SelectionActionBar(),
          ),
      ],
    );
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList({required this.bottomInset});

  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, bottomInset.h),
      children: [
        Container(
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 32.h),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            'ഈ ലിസ്റ്റിൽ ഇന്ന് പൂജകളില്ല',
            style: AppText.malayalam(size: 14, color: AppColors.grayText),
          ),
        ),
      ],
    );
  }
}
