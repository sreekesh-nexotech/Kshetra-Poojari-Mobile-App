/// Per-deity progress row on the home combined card.
class GodCardVm {
  const GodCardVm({
    required this.id,
    required this.name,
    required this.fracLabel,
    required this.progress,
    this.imageUrl,
    this.imageAsset,
  });

  /// Server `category_id`.
  final int id;
  final String name;

  /// Remote thumbnail from the catalogue; falls back to [imageAsset].
  final String? imageUrl;
  final String? imageAsset;

  /// "2/6".
  final String fracLabel;

  /// 0..1 for the mini bar.
  final double progress;
}

/// Overall progress shown on the home combined card.
class HomeProgress {
  const HomeProgress({
    required this.percentInt,
    required this.fracLabel,
    required this.pendingLabel,
    required this.incentiveFracLabel,
  });

  /// 27 (→ "27%" and the 0..1 bar).
  final int percentInt;

  /// "9/35" done / total.
  final String fracLabel;

  /// Zero-padded remaining ("ബാക്കി 26").
  final String pendingLabel;

  /// "1/5" incentive poojas done.
  final String incentiveFracLabel;

  double get progress => percentInt / 100;
}

/// One row of the home "today" tally table.
class TallyRowVm {
  const TallyRowVm({
    required this.name,
    required this.count,
    required this.reassigned,
    required this.incentive,
  });

  final String name;
  final String count;
  final bool reassigned;
  final bool incentive;
}

/// The whole tally table (flips between "to-do" and "today's summary").
class HomeTally {
  const HomeTally({
    required this.title,
    required this.rows,
    required this.totalLabel,
    required this.total,
    required this.noteOn,
    required this.note,
  });

  /// "ഇന്ന് ചെയ്യാനുള്ളവ" or "ഇന്നത്തെ സമ്മറി".
  final String title;
  final List<TallyRowVm> rows;

  /// "ആകെ ബാക്കി" or "ആകെ ചെയ്തത്".
  final String totalLabel;
  final String total;

  /// Show the gray "ചെയ്യാത്തവ" leftover row (only after check-out).
  final bool noteOn;
  final String note;
}

/// Upcoming-day count tile.
class UpcomingDay {
  const UpcomingDay({
    required this.label,
    required this.count,
    this.latinLabel = false,
  });

  final String label;
  final int count;

  /// Render the label in Roboto (the "Sep 12" tile).
  final bool latinLabel;
}
