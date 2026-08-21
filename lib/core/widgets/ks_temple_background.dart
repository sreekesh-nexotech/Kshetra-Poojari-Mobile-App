import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';

/// Full-bleed temple photograph behind every screen. Tab screens (home / pooja
/// / account) render it rotated 180° exactly as the design frames do
/// (`transform: matrix(-1,0,0,-1,…)`); the auth screens use it upright.
class KsTempleBackground extends StatelessWidget {
  const KsTempleBackground({super.key, this.flipped = true});

  /// Rotate the photo 180° (tab screens). Auth screens pass `false`.
  final bool flipped;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/images/temple-bg.jpg',
      fit: BoxFit.cover,
      // A calm warm ground while the JPEG decodes.
      color: null,
    );
    return Positioned.fill(
      child: ColoredBox(
        color: AppColors.cream,
        child: flipped
            ? Transform.rotate(angle: 3.14159265, child: image)
            : image,
      ),
    );
  }
}
