import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/ks_chevron.dart';

/// Slide-to-confirm track for marking check-in / check-out. Purely visual drag
/// state lives here; it reports completion via [onConfirmed].
///
/// [enabled] is false when the temple has no attendance site configured: the
/// mark would come back `409` whatever the poojari does, so the control greys
/// out rather than inviting a drag into a refusal (poojari-geofence.md §2).
///
/// [busy] is true while a confirmed slide is still being acted on — the GPS
/// fix behind a check-in can take up to 15 s. The handle stays maroon (this
/// is progress, not a refusal) but swaps its chevrons for a spinner and stops
/// taking drags, so a second slide cannot pile on top of the first.
class SlideToConfirm extends StatefulWidget {
  const SlideToConfirm({
    super.key,
    required this.label,
    required this.onConfirmed,
    this.enabled = true,
    this.busy = false,
  });

  final String label;
  final VoidCallback onConfirmed;
  final bool enabled;
  final bool busy;

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
    final busy = widget.busy;
    // Drags are accepted only when there is something to confirm and nothing
    // already being confirmed.
    final enabled = widget.enabled && !busy;
    // Greyed only for the real "cannot" — busy keeps the live colour.
    final active = widget.enabled;

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
                        color: active
                            ? AppColors.maroon
                            : AppColors.grayInactive,
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
                  onHorizontalDragStart: enabled
                      ? (_) => setState(() => _dragging = true)
                      : null,
                  onHorizontalDragUpdate: enabled
                      ? (d) => setState(() {
                          _x = (_x + d.delta.dx).clamp(0.0, maxTravel);
                        })
                      : null,
                  onHorizontalDragEnd: enabled
                      ? (_) {
                          final confirmed = _x > 0.78 * maxTravel;
                          setState(() {
                            _dragging = false;
                            _x = 0;
                          });
                          if (confirmed) widget.onConfirmed();
                        }
                      : null,
                  child: Container(
                    width: handleW,
                    height: 40.h,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? AppColors.maroon : AppColors.grayInactive,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: busy
                        ? SizedBox(
                            width: 18.r,
                            height: 18.r,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.offWhite,
                            ),
                          )
                        : Row(
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
