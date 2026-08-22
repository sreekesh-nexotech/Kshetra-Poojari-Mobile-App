/// A deity the poojari is assigned to.
///
/// Maps a server `PoojaCategory`: [id] is the `category_id` every poojari
/// endpoint requires. [imageUrl] is what the API supplies; [imageAsset] is the
/// bundled fallback used before a URL exists (and by the golden tests).
class GodVm {
  const GodVm({
    required this.id,
    required this.name,
    this.imageUrl,
    this.imageAsset,
  });

  /// Server `category_id`.
  final int id;

  /// Display name with the ശ്രീ honorific (Malayalam).
  final String name;

  /// Remote thumbnail from `media_url`. Null on a shrine with no image.
  final String? imageUrl;

  /// Local fallback thumbnail.
  final String? imageAsset;

  /// Stand-in while the catalogue is still loading, so the picker can render
  /// an empty control instead of throwing on an empty list.
  static const GodVm placeholder = GodVm(id: -1, name: '');

  bool get isPlaceholder => id == -1;
}
