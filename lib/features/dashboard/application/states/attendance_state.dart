/// Today's attendance: check-in / check-out clock labels and the collapsed
/// card override. Immutable; updated via [copyWith].
class AttendanceState {
  const AttendanceState({
    this.checkInAt,
    this.checkOutAt,
    this.expandedOverride,
  });

  /// Check-in clock label ("06:05 AM"), null until marked.
  final String? checkInAt;

  /// Check-out clock label, null until marked.
  final String? checkOutAt;

  /// Explicit expand/collapse from a header tap; null = follow the default
  /// (expanded until check-in, collapsed after).
  final bool? expandedOverride;

  bool get started => checkInAt != null;
  bool get done => checkInAt != null && checkOutAt != null;
  bool get notDone => !done;

  /// Design `attOpenEff`: expanded until check-in unless overridden.
  bool get expanded => expandedOverride ?? !started;

  /// Header status label (design `attStatus`).
  String get statusLabel {
    if (checkInAt == null) return 'മാർക്ക് ചെയ്തിട്ടില്ല';
    if (checkOutAt != null) return '✓ $checkInAt – $checkOutAt';
    return 'ഇൻ · $checkInAt';
  }

  /// Slide-to-confirm label (design `slideLabel`).
  String get slideLabel =>
      checkInAt == null ? 'സ്ലൈഡ് — ചെക്ക്-ഇൻ' : 'സ്ലൈഡ് — ചെക്ക്-ഔട്ട്';

  AttendanceState copyWith({
    String? checkInAt,
    String? checkOutAt,
    bool? expandedOverride,
    bool clearExpandedOverride = false,
  }) {
    return AttendanceState(
      checkInAt: checkInAt ?? this.checkInAt,
      checkOutAt: checkOutAt ?? this.checkOutAt,
      expandedOverride:
          clearExpandedOverride ? null : (expandedOverride ?? this.expandedOverride),
    );
  }
}
