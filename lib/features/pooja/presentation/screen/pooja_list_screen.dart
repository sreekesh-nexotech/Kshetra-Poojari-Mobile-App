import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/error/error_view.dart';
import '../../../../core/widgets/ks_temple_background.dart';
import '../../application/providers/pooja_data_providers.dart';
import '../../application/providers/pooja_list_controller.dart';
import '../../application/states/pooja_feed_state.dart';
import '../../application/states/pooja_list_state.dart';
import '../components/bulk_summary_modal.dart';
import '../components/god_picker.dart';
import '../components/pooja_group_card.dart';
import '../components/selection_action_bar.dart';
import '../components/status_filter_chips.dart';

/// Pooja tab — today's bookings for one shrine, grouped one card per order,
/// with filters, bulk select and undo.
class PoojaListScreen extends ConsumerStatefulWidget {
  const PoojaListScreen({super.key});

  @override
  ConsumerState<PoojaListScreen> createState() => _PoojaListScreenState();
}

class _PoojaListScreenState extends ConsumerState<PoojaListScreen> {
  @override
  void initState() {
    super.initState();
    // After the first frame, so the provider container is ready. No-ops when
    // a fixture already supplied data.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final categoryId = ref.read(effectiveCategoryIdProvider);
      ref.read(poojaFeedControllerProvider.notifier).ensureLoaded(categoryId);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Open the confirm modal when a bulk action begins.
    ref.listen(poojaListControllerProvider.select((s) => s.bulkMode), (
      prev,
      next,
    ) {
      if (next != BulkMode.none && (prev == null || prev == BulkMode.none)) {
        showBulkSummaryModal(context, ref);
      }
    });

    // Switching shrine fetches that shrine's day, unless we already hold it.
    ref.listen(effectiveCategoryIdProvider, (prev, next) {
      if (next != null && next != prev) {
        ref.read(poojaFeedControllerProvider.notifier).load(next);
      }
    });

    final groups = ref.watch(poojaGroupsProvider);
    final isEmpty = ref.watch(poojaListEmptyProvider);
    final feed = ref.watch(poojaFeedControllerProvider);
    final hasSelection = ref.watch(
      poojaListControllerProvider.select((s) => s.hasSelection),
    );
    final bottomInset = (hasSelection ? 170 : 24).toDouble();

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
                child: _body(
                  feed: feed,
                  groups: groups,
                  isEmpty: isEmpty,
                  bottomInset: bottomInset,
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

  /// Loading and error only take over the screen when there is nothing to
  /// show. A refresh over existing bookings leaves them in place — the
  /// poojari is mid-shift and a blank list reads as "your work vanished".
  Widget _body({
    required PoojaFeedState feed,
    required List groups,
    required bool isEmpty,
    required double bottomInset,
  }) {
    final nothingToShow = groups.isEmpty;

    if (feed.isFirstLoad && nothingToShow) {
      return const _Loading();
    }
    if (feed.hasError && nothingToShow) {
      return ErrorView(
        message: feed.message ?? 'ലോഡ് ചെയ്യാനായില്ല',
        onRetry: _refresh,
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, bottomInset.h),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.maroon,
      child: isEmpty
          ? _EmptyList(bottomInset: bottomInset)
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, bottomInset.h),
              itemCount: groups.length,
              separatorBuilder: (_, _) => SizedBox(height: 12.h),
              itemBuilder: (_, i) => PoojaGroupCard(group: groups[i]),
            ),
    );
  }

  Future<void> _refresh() => ref
      .read(poojaFeedControllerProvider.notifier)
      .refresh(ref.read(effectiveCategoryIdProvider));
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.maroon),
    );
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList({required this.bottomInset});

  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return ListView(
      // AlwaysScrollable so pull-to-refresh still works on an empty day.
      physics: const AlwaysScrollableScrollPhysics(),
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
