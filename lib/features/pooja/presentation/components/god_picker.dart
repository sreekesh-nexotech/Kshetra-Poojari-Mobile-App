import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/theme.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/ks_chevron.dart';
import '../../application/models/god.dart';
import '../../application/providers/pooja_data_providers.dart';
import '../../application/providers/pooja_list_controller.dart';

/// Deity selector (one god at a time). The dropdown is local visual state,
/// rendered in the root overlay so it floats above the task list.
class GodPicker extends ConsumerStatefulWidget {
  const GodPicker({super.key});

  @override
  ConsumerState<GodPicker> createState() => _GodPickerState();
}

class _GodPickerState extends ConsumerState<GodPicker> {
  final OverlayPortalController _portal = OverlayPortalController();
  final LayerLink _link = LayerLink();

  @override
  Widget build(BuildContext context) {
    final god = ref.watch(selectedGodProvider);
    final gods = ref.watch(godsProvider);

    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: (context) => Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _portal.hide,
              ),
            ),
            CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              offset: Offset(8.w, 44.h),
              child: Align(
                alignment: Alignment.topLeft,
                child: _Dropdown(
                  gods: gods,
                  selectedId: god.id,
                  onPick: (id) {
                    ref
                        .read(poojaListControllerProvider.notifier)
                        .selectGod(id);
                    _portal.hide();
                  },
                ),
              ),
            ),
          ],
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _portal.isShowing ? _portal.hide() : _portal.show(),
          child: Container(
            height: 40.h,
            padding: EdgeInsets.only(left: 16.w, right: 12.w),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadii.input.r),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    god.name,
                    style: AppText.malayalam(
                      size: 16,
                      weight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                KsChevron(
                  color: AppColors.ink,
                  angleDeg: _portal.isShowing ? -45 : 135,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.gods,
    required this.selectedId,
    required this.onPick,
  });

  final List<GodVm> gods;
  final String selectedId;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 289.w,
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadii.input.r),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: AppShadows.menu(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < gods.length; i++) ...[
              if (i > 0) SizedBox(height: 16.h),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onPick(gods[i].id),
                child: Text(
                  gods[i].name,
                  style: AppText.malayalam(
                    size: 16,
                    weight: gods[i].id == selectedId
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
