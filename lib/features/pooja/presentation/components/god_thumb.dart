import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';

/// A shrine thumbnail that prefers the catalogue's `media_url` and falls back
/// to a bundled asset — so the same widget serves a live response, an offline
/// one, and a shrine the back office never gave an image.
class GodThumb extends StatelessWidget {
  const GodThumb({
    super.key,
    required this.size,
    this.imageUrl,
    this.imageAsset,
    this.radius = 8,
  });

  final double size;
  final String? imageUrl;
  final String? imageAsset;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(radius.r),
      ),
      child: _image(),
    );
  }

  Widget? _image() {
    final url = imageUrl;
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        // A missing thumbnail must never blank the row; the cream fill and the
        // bundled asset carry it.
        errorWidget: (_, _, _) => _asset() ?? const SizedBox.shrink(),
        placeholder: (_, _) => _asset() ?? const SizedBox.shrink(),
      );
    }
    return _asset();
  }

  Widget? _asset() {
    final asset = imageAsset;
    if (asset == null || asset.isEmpty) return null;
    return Image.asset(asset, fit: BoxFit.cover);
  }
}
