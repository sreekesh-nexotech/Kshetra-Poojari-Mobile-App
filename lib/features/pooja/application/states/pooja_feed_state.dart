/// Where the pooja feed is in its load cycle.
enum LoadStatus {
  /// Nothing requested yet.
  idle,

  /// First load for this god — there is nothing to show meanwhile.
  loading,

  /// Reloading a god we already hold. The list stays on screen.
  refreshing,

  ready,
  error,
}

/// Load status for the pooja list, kept *beside* the task data rather than
/// wrapped around it.
///
/// This is what lets every derived provider stay a synchronous `Provider` and
/// every widget keep its bare `ref.watch`: the data itself is always a plain
/// `List<PoojaTaskVm>`, and only the screen's outermost branch consults this.
class PoojaFeedState {
  const PoojaFeedState({
    this.status = LoadStatus.ready,
    this.message,
    this.loadedCategories = const <int>{},
    this.godsLoaded = false,
  });

  final LoadStatus status;

  /// User-facing Malayalam copy for the error branch.
  final String? message;

  /// Which gods' lists we already hold, so switching back is instant and a
  /// revisit refreshes rather than blanks.
  final Set<int> loadedCategories;

  final bool godsLoaded;

  bool get isBusy =>
      status == LoadStatus.loading || status == LoadStatus.refreshing;
  bool get isFirstLoad => status == LoadStatus.loading;
  bool get hasError => status == LoadStatus.error;

  bool holds(int? categoryId) =>
      categoryId != null && loadedCategories.contains(categoryId);

  PoojaFeedState copyWith({
    LoadStatus? status,
    String? message,
    bool clearMessage = false,
    Set<int>? loadedCategories,
    bool? godsLoaded,
  }) {
    return PoojaFeedState(
      status: status ?? this.status,
      message: clearMessage ? null : (message ?? this.message),
      loadedCategories: loadedCategories ?? this.loadedCategories,
      godsLoaded: godsLoaded ?? this.godsLoaded,
    );
  }
}
