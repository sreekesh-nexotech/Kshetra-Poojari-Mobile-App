/// Which bulk action modal is open (design: `bulkMode` = done | cancel | null).
enum BulkMode { none, done, cancel }

/// Status filter tabs, in the exact design order — പെൻഡിംഗ് first (default
/// view), എല്ലാം last.
const List<String> kPoojaCategories = <String>[
  'പെൻഡിംഗ്', // 0 → pending
  'റീ-അസൈൻഡ്', // 1 → reassigned
  'സ്പെഷ്യൽ', // 2 → special
  'നോർമൽ', // 3 → normal (not special)
  'പൂർത്തിയായി', // 4 → done
  'എല്ലാം', // 5 → all
];

/// Purely-visual pooja-screen state (selected deity, active filter, selection
/// set, dropdown + modal flags). Immutable — updated via `copyWith`.
class PoojaListState {
  const PoojaListState({
    this.selectedGodId = 'g1',
    this.activeTab = 0,
    this.selectedIds = const <int>{},
    this.pickerOpen = false,
    this.bulkMode = BulkMode.none,
  });

  final String selectedGodId;
  final int activeTab;
  final Set<int> selectedIds;
  final bool pickerOpen;
  final BulkMode bulkMode;

  int get selectedCount => selectedIds.length;
  bool get hasSelection => selectedIds.isNotEmpty;

  PoojaListState copyWith({
    String? selectedGodId,
    int? activeTab,
    Set<int>? selectedIds,
    bool? pickerOpen,
    BulkMode? bulkMode,
  }) {
    return PoojaListState(
      selectedGodId: selectedGodId ?? this.selectedGodId,
      activeTab: activeTab ?? this.activeTab,
      selectedIds: selectedIds ?? this.selectedIds,
      pickerOpen: pickerOpen ?? this.pickerOpen,
      bulkMode: bulkMode ?? this.bulkMode,
    );
  }
}
