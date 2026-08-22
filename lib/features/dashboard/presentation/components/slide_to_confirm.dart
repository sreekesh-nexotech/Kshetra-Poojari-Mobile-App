import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/ks_chevron.dart';

/// Slide-to-confirm track for marking check-in / check-out. Purely visual drag
/// state lives here; it reports completion via [onConfirmed].
class SlideToConfirm extends StatefulWidget {
  const SlideToConfirm({
    super.key,
    required this.label,
    required this.onConfirmed,
  });

  final String label;
  final VoidCallback onConfirmed;

  @override
  State<SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<SlideToConfirm> {
  double _x = 0;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final handleW = 56.w;
    final pad = 4.w;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxTravel = constraints.maxWidth - handleW - pad * 2;
        return Container(
          height: 48.h,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.creamInput,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(left: 66.w, right: 12.w),
                  child: Center(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.malayalam(
                        size: 13,
                        weight: FontWeight.w700,
                        color: AppColors.maroon,
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: _dragging
                    ? Duration.zero
                    : const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                left: pad + _x,
                top: pad,
                child: GestureDetector(
                  onHorizontalDragStart: (_) =>
                      setState(() => _dragging = true),
                  onHorizontalDragUpdate: (d) => setState(() {
                    _x = (_x + d.delta.dx).clamp(0.0, maxTravel);
                  }),
                  onHorizontalDragEnd: (_) {
                    final confirmed = _x > 0.78 * maxTravel;
                    setState(() {
                      _dragging = false;
                      _x = 0;
                    });
                    if (confirmed) widget.onConfirmed();
                  },
                  child: Container(
                    width: handleW,
                    height: 40.h,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.maroon,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        KsChevron(
                          size: 8,
                          color: AppColors.offWhite,
                          angleDeg: 45,
                        ),
                        Transform.translate(
                          offset: Offset(-4.w, 0),
                          child: KsChevron(
                            size: 8,
                            color: AppColors.offWhite,
                            angleDeg: 45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
