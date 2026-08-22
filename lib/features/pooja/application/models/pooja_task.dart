/// Lifecycle of a single pooja task.
enum TaskStatus { pending, done, cancelled }

/// One person + nakshatra = one pooja task (the design's task model).
///
/// Immutable value object with [copyWith] — mutations go through the
/// controller, never by editing fields in place.
class PoojaTaskVm {
  const PoojaTaskVm({
    required this.id,
    required this.godId,
    required this.poojaName,
    required this.person,
    required this.nakshatra,
    this.remark,
    this.special = false,
    this.incentive = false,
    this.reassigned = false,
    this.status = TaskStatus.pending,
    this.doneAt,
  });

  final int id;
  final String godId;

  /// Pooja name (group header), Malayalam.
  final String poojaName;

  /// Devotee name, English (Roboto).
  final String person;

  /// Nakshatra, Malayalam.
  final String nakshatra;

  /// Optional short remark ("ജോലിക്ക്", "പരീക്ഷയ്ക്ക്"…), Malayalam.
  final String? remark;

  final bool special;
  final bool incentive;
  final bool reassigned;

  final TaskStatus status;

  /// Completion time label (e.g. "07:40 AM"), set when [status] is done.
  final String? doneAt;

  bool get isPending => status == TaskStatus.pending;
  bool get isDone => status == TaskStatus.done;
  bool get isCancelled => status == TaskStatus.cancelled;
  bool get hasRemark => remark != null && remark!.isNotEmpty;

  PoojaTaskVm copyWith({
    TaskStatus? status,
    String? doneAt,
    bool clearDoneAt = false,
  }) {
    return PoojaTaskVm(
      id: id,
      godId: godId,
      poojaName: poojaName,
      person: person,
      nakshatra: nakshatra,
      remark: remark,
      special: special,
      incentive: incentive,
      reassigned: reassigned,
      status: status ?? this.status,
      doneAt: clearDoneAt ? null : (doneAt ?? this.doneAt),
    );
  }
}
