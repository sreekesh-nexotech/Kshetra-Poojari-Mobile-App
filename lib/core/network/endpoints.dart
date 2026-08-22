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
  static const String otpSignIn = '/api/auth/otp-signin/';
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

  // ── Catalogue ─────────────────────────────────────────────────────────────
  /// The gods that build the shrine picker.
  static const String poojaCategory = '/api/booking/poojacategory/';

  /// Cheap "has anything changed?" probe for cache invalidation on resume.
  /// Poll this, never the list endpoint — the throttle is 2000 req/hour.
  static const String globalUpdate = '/api/booking/global-update/';
}
