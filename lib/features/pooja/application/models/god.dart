/// A deity the poojari is assigned to.
///
/// View-model for the presentation + application layers. When the API is wired,
/// swap [imageAsset] for a network `imageUrl` and map the server DTO into this
/// same shape — the UI only ever reads this class.
class GodVm {
  const GodVm({
    required this.id,
    required this.name,
    required this.imageAsset,
  });

  /// Stable id (`g1`, `g2`).
  final String id;

  /// Display name with the ശ്രീ honorific (Malayalam).
  final String name;

  /// Local thumbnail asset. Replace with `imageUrl` + CachedNetworkImage on
  /// API integration.
  final String imageAsset;
}
