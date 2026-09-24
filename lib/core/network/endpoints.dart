/// Every path the poojari app calls, per `docs-flutter/pooja.md` §1.
///
/// Trailing slashes are load-bearing — Django's `APPEND_SLASH` would turn a
/// missing one into a 301, and a redirected PATCH silently drops its body.
abstract final class Endpoints {
  Endpoints._();

  // ── Auth ──────────────────────────────────────────────────────────────────
  /// Primes the `csrftoken` cookie. Call once before the login form submits.
  static const String csrf = '/api/auth/csrf/';
  static const String poojariSignIn = '/api/auth/poojari-signin/';

  /// Sends the OTP. `{"phone_number": "+91..."}` — the number must carry the
  /// country code or the server 404s it as unregistered even when it exists.
  static const String sendOtp = '/api/auth/send-otp/';

  /// Verifies the OTP and signs in. `{"phone_number": "+91...", "otp_code":
  /// "123456"}` — note `otp_code`, not `otp`.
  static const String otpSignIn = '/api/auth/otp-signin/';

  /// Sets a new password for whoever `otpSignIn` just signed in as — no
  /// phone/OTP fields, it rides the session cookie.
  /// `{"new_password": "…", "confirm_password": "…"}`.
  static const String forgotPassword = '/api/auth/forgot-password/';
  static const String logout = '/api/auth/logout/';

  // ── Poojari ───────────────────────────────────────────────────────────────
  /// GET on the list route; the read carries no id (see pooja.md §9).
  static const String profile = '/api/poojari/profile/';

  /// PATCH on the detail route — pass your own id.
  static String profileDetail(int userId) => '/api/poojari/profile/$userId/';

  /// GET today's bookings (`?category_id=` mandatory) and PATCH a status.
  static const String poojaManagement = '/api/poojari/pooja-management/';

  /// All-time, all-poojaris completion figures. Not wired yet — see pooja.md §6.
  static const String poojaStats = '/api/poojari/pooja-stats/';

  /// Home greeting card's Malayalam (Kollavarsham) calendar date. Optional
  /// `?date=YYYY-MM-DD`, defaults to today (Asia/Kolkata). See
  /// `POOJARI_APP_API.md` §1.
  static const String panchangam = '/api/poojari/panchangam/';

  /// Home screen's "Tomorrow / Day after / …" tiles. Optional `?days=` (max
  /// 14, default 3) and `?category_id=`. See `POOJARI_APP_API.md` §2.
  static const String upcomingPoojaCounts =
      '/api/poojari/upcoming-pooja-counts/';

  /// GET lists marks over `?period=`; POST marks *today* present/absent/leave
  /// (one mark per calendar day — there is no separate check-out timestamp).
  /// See poojari-app.md §5.
  static const String attendance = '/api/poojari/attendance/';

  /// GET the temple coordinates + radius the check-in slide pre-checks
  /// against. Fetch once per session and cache; re-fetch after a `403`
  /// (outside premises) or `409` (nothing configured), both of which carry
  /// the server's current view. `{"location": null}` is a `200`, not an
  /// error — it means no site is configured. See poojari-geofence.md §2.
  static const String attendanceLocation = '/api/poojari/attendance/location/';

  /// `?period=weekly|monthly[&date_from=&date_to=]` — bucketed summary +
  /// `groups` + raw `records`. See poojari-app.md §6.
  static const String attendanceReport = '/api/poojari/attendance/report/';

  /// GET the poojari's own assigned shrines; PUT replaces the whole list.
  /// Profile screen's "അസൈൻ ചെയ്ത ദേവതകൾ". See poojari-app.md §2.
  static const String gods = '/api/poojari/gods/';

  /// This poojari's this-month totals for the profile KPI tiles. See
  /// `POOJARI_APP_API.md` §5.
  static const String monthlyStats = '/api/poojari/monthly-stats/';

  // ── Catalogue ─────────────────────────────────────────────────────────────
  /// The gods that build the shrine picker.
  static const String poojaCategory = '/api/booking/poojacategory/';

  /// Cheap "has anything changed?" probe for cache invalidation on resume.
  /// Poll this, never the list endpoint — the throttle is 2000 req/hour.
  static const String globalUpdate = '/api/booking/global-update/';
}
