/// Date / clock helpers.
abstract final class AppTime {
  AppTime._();

  /// Formats [when] as the design's clock label, e.g. `07:40 AM` — 12-hour,
  /// zero-padded hours and minutes. Mirrors the prototype's `now()`.
  ///
  /// Reads [when]'s fields as given — it does **not** convert timezones. For
  /// a server timestamp (which carries its own `+05:30`), use [istClockLabel]
  /// instead; this one is for an already-local value, e.g. `DateTime.now()`.
  static String clockLabel([DateTime? when]) {
    final d = when ?? DateTime.now();
    final ap = d.hour >= 12 ? 'PM' : 'AM';
    final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final hh = h12.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$hh:$mm $ap';
  }

  /// Formats a server timestamp as the design's clock label, in **Asia/Kolkata**
  /// — regardless of the device's own timezone.
  ///
  /// `DateTime.parse`/`tryParse` on a string with an explicit offset (the
  /// shape every poojari endpoint sends, e.g. `2026-09-04T21:23:02+05:30`)
  /// returns a UTC-flagged [DateTime] whose `.hour`/`.minute` are the *UTC*
  /// clock, not IST — reading them directly (what [clockLabel] does) or
  /// calling `.toLocal()` (which follows the device's timezone, not the
  /// temple's) both give the wrong wall-clock time on any device not
  /// already set to IST. This adds the fixed +05:30 offset explicitly, so
  /// the label is right no matter what timezone the device is in.
  static String istClockLabel(DateTime when) {
    final utc = when.isUtc ? when : when.toUtc();
    final ist = utc.add(const Duration(hours: 5, minutes: 30));
    return clockLabel(
      DateTime(ist.year, ist.month, ist.day, ist.hour, ist.minute),
    );
  }

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// Formats [when] as the design's Gregorian date label, e.g.
  /// `August 29, 2026`. Defaults to today, so the home greeting card reads
  /// the current date rather than a string frozen at build time.
  static String gregorianLabel([DateTime? when]) {
    final d = when ?? DateTime.now();
    final day = d.day.toString().padLeft(2, '0');
    return '${_months[d.month - 1]} $day, ${d.year}';
  }

  /// Zero-pads a count to two digits, as the design does (`03`, `42`).
  static String pad2(int n) => n.toString().padLeft(2, '0');

  /// Today's date **in Asia/Kolkata**, whatever the device's own timezone is.
  ///
  /// The temple's day is the server's day. A poojari marking at 00:30 IST on a
  /// device left on UTC would otherwise be told they had not marked today, and
  /// one in a timezone ahead of IST would be shown tomorrow. Anywhere a server
  /// `date` field is compared against "today", this is the value to compare
  /// with (poojari-geofence.md §5).
  static String istToday([DateTime? now]) {
    final ist = (now ?? DateTime.now()).toUtc().add(
      const Duration(hours: 5, minutes: 30),
    );
    return isoDate(ist);
  }

  /// `YYYY-MM-DD`, for a `date`/`date_from`/`date_to` query parameter.
  static String isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static const _weekdayInitials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  /// Single-letter weekday label for the account week strip, e.g. `M` for
  /// Monday. [DateTime.weekday] is 1 (Monday) through 7 (Sunday).
  static String weekdayInitial(DateTime d) => _weekdayInitials[d.weekday - 1];
}
