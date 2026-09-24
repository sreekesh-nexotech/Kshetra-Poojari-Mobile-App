/// Today's attendance: check-in / check-out clock labels and the collapsed
/// card override. Immutable; updated via [copyWith].
class AttendanceState {
  const AttendanceState({
    this.checkInAt,
    this.checkOutAt,
    this.expandedOverride,
    this.checkingIn = false,
  });

  /// Check-in clock label ("06:05 AM"), null until marked.
  final String? checkInAt;

  /// Check-out clock label, null until marked.
  final String? checkOutAt;

  /// Explicit expand/collapse from a header tap; null = follow the default
  /// (expanded until check-in, collapsed after).
  final bool? expandedOverride;

  /// True while a check-in is in flight — from the slide until the mark lands
  /// or is refused. Most of that time is the GPS fix (up to 15 s), so the
  /// slider shows it rather than sit there looking ignored.
  final bool checkingIn;

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

  /// Slide-to-confirm label (design `slideLabel`), or what the wait is for
  /// while the check-in is in flight.
  String get slideLabel {
    if (checkingIn) return 'ലൊക്കേഷൻ എടുക്കുന്നു…';
    return checkInAt == null ? 'സ്ലൈഡ് — ചെക്ക്-ഇൻ' : 'സ്ലൈഡ് — ചെക്ക്-ഔട്ട്';
  }

  AttendanceState copyWith({
    String? checkInAt,
    String? checkOutAt,
    bool? expandedOverride,
    bool clearExpandedOverride = false,
    bool? checkingIn,
  }) {
    return AttendanceState(
      checkInAt: checkInAt ?? this.checkInAt,
      checkOutAt: checkOutAt ?? this.checkOutAt,
      expandedOverride: clearExpandedOverride
          ? null
          : (expandedOverride ?? this.expandedOverride),
      checkingIn: checkingIn ?? this.checkingIn,
    );
  }
}
