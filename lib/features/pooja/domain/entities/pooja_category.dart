/// A god — Ganapathi, Devi, Ayyappan. The server calls it a `PoojaCategory`,
/// and its id is the `category_id` every poojari endpoint requires.
///
/// The poojari endpoints return a **narrower** object than
/// `/api/booking/poojacategory/` does, so the catalogue-only fields are
/// nullable and this is one class rather than two (pooja.md §5).
class PoojaCategory {
  const PoojaCategory({
    required this.id,
    required this.name,
    this.mediaUrl,
    this.homeMediaUrl,
    this.isActive = true,
    this.sortOrder,
    this.poojasCount,
  });

  final int id;

  /// Malayalam script — needs a font with Malayalam coverage.
  final String name;

  final String? mediaUrl;
  final String? homeMediaUrl;
  final bool isActive;

  /// null on the poojari endpoints. The order the back office dragged the
  /// shrines into; the tab strip sorts by it.
  final int? sortOrder;

  /// null on the poojari endpoints.
  final int? poojasCount;

  factory PoojaCategory.fromJson(Map<String, dynamic> j) => PoojaCategory(
    id: j['id'] as int,
    name: j['name'] as String? ?? '',
    mediaUrl: j['media_url'] as String?,
    homeMediaUrl: j['home_media_url'] as String?,
    isActive: j['is_active'] as bool? ?? true,
    sortOrder: j['sort_order'] as int?,
    poojasCount: j['poojas_count'] as int?,
  );
}
