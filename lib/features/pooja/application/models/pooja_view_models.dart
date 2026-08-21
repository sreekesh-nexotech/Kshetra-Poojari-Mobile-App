import 'pooja_task.dart';

/// Tri-state of a group header checkbox.
enum GroupCheck { none, partial, all }

/// A pooja group (one pooja name) as rendered on the list screen.
class PoojaGroupVm {
  const PoojaGroupVm({
    required this.name,
    required this.countLabel,
    required this.special,
    required this.incentive,
    required this.hasPending,
    required this.check,
    required this.pendingIds,
    required this.rows,
  });

  final String name;

  /// Zero-padded task count for the header pill (`03`).
  final String countLabel;
  final bool special;
  final bool incentive;

  /// Whether the group still has pending tasks (drives header checkbox).
  final bool hasPending;
  final GroupCheck check;

  /// Ids of the group's pending tasks (for select-all).
  final List<int> pendingIds;
  final List<PoojaRowVm> rows;
}

/// A single task row within a group.
class PoojaRowVm {
  const PoojaRowVm({
    required this.id,
    required this.person,
    required this.nakshatra,
    required this.remark,
    required this.status,
    required this.reassignedPill,
    required this.selected,
    required this.timeLabel,
  });

  final int id;
  final String person;
  final String nakshatra;
  final String? remark;
  final TaskStatus status;

  /// Show the റീ-അസൈൻഡ് pill (reassigned AND still pending).
  final bool reassignedPill;

  /// Selected in the current multi-select.
  final bool selected;

  /// Completion time label for done rows.
  final String? timeLabel;

  bool get hasRemark => remark != null && remark!.isNotEmpty;
  bool get isPending => status == TaskStatus.pending;
  bool get isDone => status == TaskStatus.done;
  bool get isCancelled => status == TaskStatus.cancelled;
}
