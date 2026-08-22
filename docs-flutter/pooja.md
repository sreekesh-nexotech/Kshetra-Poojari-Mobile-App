# Flutter integration — the poojari's pooja booking screen

How the poojari app talks to `/api/poojari/` to show today's bookings and mark
them performed.

Backend contract as on branch `hari-dev`. Where `main` still differs, §11 says
so — build the models to this page and the `main` shape still parses.

---

## Contents

1. [The screens, and what feeds them](#1-the-screens-and-what-feeds-them)
2. [The one concept: an order is not a booking](#2-the-one-concept-an-order-is-not-a-booking)
3. [Transport: session cookies, not tokens](#3-transport-session-cookies-not-tokens)
4. [Signing in](#4-signing-in)
5. [The shrine tabs](#5-the-shrine-tabs)
6. [The stats panel](#6-the-stats-panel)
7. [Today's list](#7-todays-list)
8. [Marking a status](#8-marking-a-status)
9. [Profile](#9-profile)
10. [Errors, and what the UI should do with each](#10-errors-and-what-the-ui-should-do-with-each)
11. [Gotchas that will cost you a day each](#11-gotchas-that-will-cost-you-a-day-each)
12. [Integration checklist](#12-integration-checklist)

---

## 1. The screens, and what feeds them

| Screen | Call |
|---|---|
| Login | `POST /api/auth/poojari-signin/` |
| Shrine tabs across the top | `GET /api/booking/poojacategory/?is_active=true` |
| Completion panel above the list | `GET /api/poojari/pooja-stats/` |
| Today's bookings, one tab | `GET /api/poojari/pooja-management/?category_id=<god>` |
| The tick on a booking row | `PATCH /api/poojari/pooja-management/` |
| Profile / logout | `GET /api/poojari/profile/`, `POST /api/auth/logout/` |

Everything on this page is under the `temple_poojari` role. A poojari holds
`rbac.view_assigned_pooja_orders`, `rbac.update_pooja_status`,
`rbac.view_poojari_stats`, the catalogue read permissions, and nothing else —
so a stray call to an `/api/admin/…` endpoint comes back `403`, not `404`.

---

## 2. The one concept: an order is not a booking

Get this wrong and every screen is subtly wrong.

```
PoojaOrder      #4182   one checkout — a family paid once
├── OrderLine   #9051   Ganapathi Homam · Ramesh    · 22 Aug   ← a booking
├── OrderLine   #9052   Ganapathi Homam · Lakshmi   · 22 Aug   ← a booking
└── OrderLine   #9053   Bhagavathi Seva · Ramesh    · 24 Aug   ← a booking
```

**The booking — one pooja, one person, one date — is the unit the temple
performs.** It carries its own `pooja_status`, its own assigned `poojari`, its
own price. The order is a payment envelope around several of them, which can
span two gods, three dates and two poojaris.

The order's `pooja_status` is a **derived summary**, recomputed by the server
after every write:

- `completed` — every booking still standing has been performed
- `cancelled` — nothing is standing
- `pending` — anything else

So the Flutter list should render **one card per order, one checkable row per
booking**, and the order-level badge should be treated as read-only rollup.
Never write to it directly and never compute it client-side; let the `order`
object in the PATCH response overwrite what you hold.

---

## 3. Transport: session cookies, not tokens

This backend uses **Django session authentication**. There is no JWT, no
`Authorization: Bearer`. Two cookies matter:

| Cookie | Set by | Used for |
|---|---|---|
| `sessionid` | `login()` on sign-in | Who you are |
| `csrftoken` | `GET /api/auth/csrf/`, and again on sign-in | Proving a write is not cross-site |

DRF's `SessionAuthentication` **enforces CSRF on every unsafe method for an
authenticated user**. `PATCH /api/poojari/pooja-management/` will come back
`403 CSRF Failed: CSRF token missing` if you do not send the header — this is
the single most common way this integration fails on day one.

### The rule

- Persist cookies to disk, so a poojari is not logged out when the app restarts.
- Read `csrftoken` out of the jar and echo it as the **`X-CSRFToken` header** on
  every `POST`/`PATCH`/`PUT`/`DELETE`.
- The sign-in endpoints themselves are `@csrf_exempt`, so the very first call
  needs no token. Everything after sign-in does.

### Dependencies

```yaml
dependencies:
  dio: ^5.4.0
  dio_cookie_manager: ^3.1.1
  cookie_jar: ^4.0.8
  path_provider: ^2.1.2
```

### The client

```dart
// lib/core/api_client.dart
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';

class ApiClient {
  ApiClient._(this.dio, this._jar, this._baseUri);

  final Dio dio;
  final PersistCookieJar _jar;
  final Uri _baseUri;

  static Future<ApiClient> create({required String baseUrl}) async {
    final dir = await getApplicationSupportDirectory();
    final jar = PersistCookieJar(
      // ignoreExpires: false — a real session expiry must log the poojari out.
      storage: FileStorage('${dir.path}/.cookies/'),
    );

    final dio = Dio(BaseOptions(
      baseUrl: baseUrl, // e.g. https://api.temple.example
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      // Let 4xx through to our own error mapping instead of throwing on status.
      validateStatus: (code) => code != null && code < 500,
      headers: {'Accept': 'application/json'},
      contentType: Headers.jsonContentType,
    ));

    final client = ApiClient._(dio, jar, Uri.parse(baseUrl));
    dio.interceptors
      ..add(CookieManager(jar))
      ..add(InterceptorsWrapper(onRequest: client._attachCsrf));
    return client;
  }

  static const _unsafe = {'POST', 'PUT', 'PATCH', 'DELETE'};

  Future<void> _attachCsrf(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_unsafe.contains(options.method.toUpperCase())) {
      final token = await _csrfToken();
      if (token != null) options.headers['X-CSRFToken'] = token;
      // Django checks Referer on HTTPS and rejects a missing one.
      options.headers['Referer'] = _baseUri.toString();
    }
    handler.next(options);
  }

  Future<String?> _csrfToken() async {
    final cookies = await _jar.loadForRequest(_baseUri);
    for (final c in cookies) {
      if (c.name == 'csrftoken') return c.value;
    }
    return null;
  }

  /// Call once at startup, before the login form is submitted.
  Future<void> primeCsrf() => dio.get('/api/auth/csrf/');

  Future<void> clearSession() => _jar.deleteAll();
}
```

### Platform notes

- **Android** — `android/app/src/main/AndroidManifest.xml` needs
  `<uses-permission android:name="android.permission.INTERNET"/>`. Against a
  plain-HTTP dev server you also need a `network_security_config.xml` allowing
  cleartext for that host; production is HTTPS and needs neither.
- **iOS** — nothing special over HTTPS. For a cleartext dev host, add an ATS
  exception for that host only in `Info.plist`.
- **Android emulator** — `localhost` is the emulator. Use `10.0.2.2` for a
  Django server on the dev machine.
- **`SESSION_COOKIE_SAMESITE = "Lax"`** in production. That is irrelevant to a
  native app (there is no browser origin), but it means the same backend cannot
  be driven from a Flutter *web* build on a different origin. Flutter web needs
  `CORS_ALLOWED_ORIGINS` to name its origin, and `withCredentials`.

---

## 4. Signing in

```
POST /api/auth/poojari-signin/
{ "username": "sharma", "password": "…", "fcm_token": "…" }
```

Either `username` or `phone_number` works; `password` is always required.
`fcm_token` is optional and is stored on the user for push.

**`200` — signed in.** The `sessionid` and `csrftoken` cookies are on this
response; the cookie jar picks them up.

```json
{
  "message": "Poojari signin successful",
  "user": { "id": 41, "username": "sharma", "phone_number": "9847…",
            "email": "…", "role": "temple_poojari" },
  "profile_status": "active"
}
```

**`200` — but not signed in.** A poojari the back office registered who has
never set a password gets this instead, and it must be handled or the app will
sit on a spinner:

```json
{ "message": "Account pending activation. OTP sent to set your password.",
  "requires_password_setup": true, "phone_number": "9847…" }
```

Branch on `requires_password_setup` **before** looking at `user`. It only
happens on the phone-number path, and it means: send the poojari to the OTP
screen (`POST /api/auth/otp-signin/`, then `POST /api/auth/forgot-password/`
to set the password while logged in).

| Status | Body | Meaning |
|---|---|---|
| `400` | `Password is required` / `Username or phone number is required` | Form validation |
| `401` | `Invalid credentials` | Wrong password |
| `403` | `Access denied. No poojari account found…` | The account exists but is not a poojari |
| `403` | `Your account is inactive. Please contact the temple admin.` | Profile deactivated |

```dart
sealed class SignInResult {}
class SignedIn extends SignInResult { SignedIn(this.user); final PoojariUser user; }
class NeedsPasswordSetup extends SignInResult {
  NeedsPasswordSetup(this.phoneNumber); final String phoneNumber;
}
class SignInFailed extends SignInResult { SignInFailed(this.message); final String message; }

Future<SignInResult> signIn({String? username, String? phone, required String password}) async {
  await api.primeCsrf();
  final res = await api.dio.post('/api/auth/poojari-signin/', data: {
    if (username != null) 'username': username,
    if (phone != null) 'phone_number': phone,
    'password': password,
    if (fcmToken != null) 'fcm_token': fcmToken,
  });

  final body = res.data as Map<String, dynamic>;
  if (res.statusCode == 200) {
    if (body['requires_password_setup'] == true) {
      return NeedsPasswordSetup(body['phone_number'] as String);
    }
    return SignedIn(PoojariUser.fromJson(body['user'] as Map<String, dynamic>));
  }
  return SignInFailed(body['error'] as String? ?? 'Sign in failed');
}
```

**Session restore.** On cold start, don't show the login screen until you know.
Call `GET /api/poojari/profile/`; `200` means the persisted `sessionid` is
still good, `403` means it is not — clear the jar and show login.

**Logout:** `POST /api/auth/logout/`, then `clearSession()`. It also clears the
stored FCM token server-side, so push stops for that device.

---

## 5. The shrine tabs

```
GET /api/booking/poojacategory/?is_active=true
```

A "category" is a **god** — Ganapathi, Devi, Ayyappan. It is what
`category_id` means everywhere below, and what the tab strip is built from.

**Unpaginated by default.** Paging is opt-in: send `?page=` or `?page_size=`
and you get a page, otherwise you get every row.

```json
{
  "count": 3,
  "results": [
    { "id": 3, "name": "ഗണപതി", "parent": null,
      "media_url": "https://cdn…/ganapathi.webp", "media_public_id": "temple/gods/ganapathi",
      "home_media_url": null, "home_media_public_id": null,
      "children": [], "poojas_count": 12, "is_active": true, "sort_order": 1 }
  ],
  "summary": { "total": 3, "active": 3, "inactive": 0, "next_sort_order": 4 }
}
```

Order the tabs by `sort_order` — that is the order the back office dragged them
into. `?search=` accepts Manglish (`ganapathi` finds `ഗണപതി`) if you add a
search box.

> This response is **server-side cached with no timeout** and invalidated on
> write. It is safe to hold in memory for the session; refresh it on
> pull-to-refresh, not on every tab change.

Note the poojari endpoints return a **narrower** category object —
`id, name, media_public_id, media_url, home_media_public_id, home_media_url,
is_active`, with no `children`, `poojas_count` or `sort_order`. Model it as one
class with those extras nullable rather than two.

---

## 6. The stats panel

```
GET /api/poojari/pooja-stats/              → every god
GET /api/poojari/pooja-stats/?category_id=3 → one god
```

**The response shape changes with the parameter.** With `category_id` you get a
bare stats object; without it you get a wrapper. Handle both explicitly.

```json
// no category_id
{ "categories_count": 2,
  "categories_stats": [
    { "category": { "id": 3, "name": "ഗണപതി", … },
      "regular_pooja": { "total": 40, "completed": 31, "pending": 9, "completion_percentage": 78 },
      "special_pooja": { "total": 6,  "completed": 6,  "pending": 0, "completion_percentage": 100 } }
  ] }

// ?category_id=3  →  just the inner object
{ "category": {…}, "regular_pooja": {…}, "special_pooja": {…} }
```

`completion_percentage` is an **integer**, already rounded server-side. Show it
as given; don't recompute from `completed/total` or you will disagree with the
back office on the rounding.

> ⚠️ **These figures are not today's, and not yours.** The stats query counts
> every `confirmed`/`cod` order for the god, over all time, for all poojaris —
> unlike the list below, which is today-only and scoped to the caller. Label
> the panel accordingly ("Overall", not "Today"), or the numbers will not match
> the list underneath it and the poojari will report it as a bug.

---

## 7. Today's list

```
GET /api/poojari/pooja-management/?category_id=3
```

| Param | Required | Values |
|---|---|---|
| `category_id` | **yes** | A god id. Omitting it is a `400`, not "all gods". |
| `special_pooja` | no | `true` / `false` |
| `pooja_status` | no | `pending` / `completed` / `cancelled` |

What comes back is **today's bookings for that god that are yours or nobody's**:

- **Today** is the temple's today — `Asia/Kolkata`, not the device's and not
  UTC. A booking matches on `selected_date` or on its special-pooja date.
- **Yours or nobody's** — a booking the back office assigned to another poojari
  is not on your screen, and neither is the rest of the order it sits in. One
  nobody has been given is up for grabs and does show.
- Orders are sorted **pending first, then completed, then cancelled**, and
  oldest-first inside each group. Preserve that order; it is the work queue.
- **Not paginated.** One day's work for one god is a short list.

```json
{
  "category": { "id": 3, "name": "ഗണപതി", "media_url": "…", "is_active": true, … },
  "count": 1,
  "orders": [
    {
      "id": 4182,
      "user_email": "ramesh@example.com",
      "pooja_status": "pending",
      "status": "confirmed",
      "pooja_name": "ഗണപതി ഹോമം",
      "special_pooja": false,
      "total": "750.00",
      "created_at": "2026-08-22T04:12:09.117Z",
      "order_lines": [
        {
          "id": 9051,
          "status": "confirmed",
          "pooja_status": "pending",
          "poojari_id": null,
          "pooja_date": "2026-08-22",
          "user_list": { "name": "Ramesh", "dob": "1990-04-11", "time": "08:30:00" },
          "nakshtram": "തിരുവോണം",
          "price": "250.00"
        }
      ]
    }
  ]
}
```

Field-by-field, with the traps:

| Field | Note |
|---|---|
| `total`, `price` | **Strings**, not numbers — DRF renders `Decimal` as a string. Parse with `Decimal`/`double.parse`, never `as num`. |
| `nakshtram` | Spelled without the `a`. It is the wire name; don't "fix" it in the parser or it will silently read `null`. |
| `status` | The **money** state: `confirmed` / `cod` / `cancelled` / `refunded`. |
| `pooja_status` | The **execution** state: `pending` / `completed` / `cancelled`. Two different fields, two different vocabularies. |
| `poojari_id` | `null` = unassigned, up for grabs. Your own id = assigned to you. It is never anyone else's on this endpoint. |
| `pooja_name`, `special_pooja` | Read off the *first* matching line only. With a mixed order they describe one booking, not the order — prefer the per-line data for anything the poojari reads. |
| `user_list` | `null` for a counter walk-in. Show a placeholder, don't crash. |
| `pooja_date` | `YYYY-MM-DD`, no time. |

> ⚠️ **`?pooja_status=` filters the *order*, not the booking.** An order with
> one done and one pending booking has an order-level status of `pending`, so
> `?pooja_status=completed` will not return it — and the completed booking
> inside it disappears from the filtered view. For a per-booking filter chip,
> fetch unfiltered and filter `order_lines` in Dart.

### Models

```dart
// lib/features/pooja/models.dart

/// A god / PoojaCategory. The poojari endpoints return the first seven fields;
/// `/api/booking/poojacategory/` adds the last three.
class God {
  const God({
    required this.id,
    required this.name,
    this.mediaUrl,
    this.homeMediaUrl,
    this.isActive = true,
    this.sortOrder,
    this.poojasCount,
  });

  final int id;
  final String name;
  final String? mediaUrl;
  final String? homeMediaUrl;
  final bool isActive;
  final int? sortOrder;     // null on the poojari endpoints
  final int? poojasCount;   // null on the poojari endpoints

  factory God.fromJson(Map<String, dynamic> j) => God(
        id: j['id'] as int,
        name: j['name'] as String? ?? '',
        mediaUrl: j['media_url'] as String?,
        homeMediaUrl: j['home_media_url'] as String?,
        isActive: j['is_active'] as bool? ?? true,
        sortOrder: j['sort_order'] as int?,
        poojasCount: j['poojas_count'] as int?,
      );
}

class PoojariUser {
  const PoojariUser({
    required this.id,
    required this.username,
    this.email,
    this.phoneNumber,
    this.firstName,
    this.lastName,
    this.role = 'temple_poojari',
  });

  final int id;
  final String username;
  final String? email;
  final String? phoneNumber;
  final String? firstName;
  final String? lastName;
  final String role;

  factory PoojariUser.fromJson(Map<String, dynamic> j) => PoojariUser(
        id: j['id'] as int,
        username: j['username'] as String? ?? '',
        email: j['email'] as String?,
        phoneNumber: j['phone_number'] as String?,
        firstName: j['first_name'] as String?,
        lastName: j['last_name'] as String?,
        role: j['role'] as String? ?? 'temple_poojari',
      );
}

enum PoojaStatus { pending, completed, cancelled }

PoojaStatus poojaStatusFrom(String? raw) => switch (raw) {
      'completed' => PoojaStatus.completed,
      'cancelled' => PoojaStatus.cancelled,
      _ => PoojaStatus.pending,
    };

class Devotee {
  const Devotee({required this.name, this.dob, this.time});
  final String name;
  final String? dob;
  final String? time;

  factory Devotee.fromJson(Map<String, dynamic> j) => Devotee(
        name: j['name'] as String? ?? '',
        dob: j['dob'] as String?,
        time: j['time'] as String?,
      );
}

/// One booking: one pooja, one person, one date.
class Booking {
  const Booking({
    required this.id,
    required this.status,
    required this.poojaStatus,
    required this.poojariId,
    required this.poojaDate,
    required this.price,
    this.devotee,
    this.nakshatram,
  });

  final int id;
  final String status;          // confirmed | cod | cancelled | refunded
  final PoojaStatus poojaStatus;
  final int? poojariId;         // null = unassigned
  final DateTime? poojaDate;
  final double price;
  final Devotee? devotee;
  final String? nakshatram;

  bool get isSettled => status == 'cancelled' || status == 'refunded';
  bool get isDone => poojaStatus == PoojaStatus.completed;
  bool get canMark => !isSettled && poojaStatus != PoojaStatus.cancelled;

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
        id: j['id'] as int,
        status: j['status'] as String? ?? 'confirmed',
        poojaStatus: poojaStatusFrom(j['pooja_status'] as String?),
        poojariId: j['poojari_id'] as int?,
        poojaDate: DateTime.tryParse(j['pooja_date'] as String? ?? ''),
        // Decimal on the wire is a String.
        price: double.tryParse('${j['price'] ?? '0'}') ?? 0,
        devotee: j['user_list'] == null
            ? null
            : Devotee.fromJson(j['user_list'] as Map<String, dynamic>),
        // Wire name is `nakshtram` — no `a`. Do not correct it.
        nakshatram: j['nakshtram'] as String?,
      );

  Booking copyWith({PoojaStatus? poojaStatus, int? poojariId}) => Booking(
        id: id,
        status: status,
        poojaStatus: poojaStatus ?? this.poojaStatus,
        poojariId: poojariId ?? this.poojariId,
        poojaDate: poojaDate,
        price: price,
        devotee: devotee,
        nakshatram: nakshatram,
      );
}

/// One checkout, holding several bookings.
class PoojaOrder {
  const PoojaOrder({
    required this.id,
    required this.poojaStatus,
    required this.status,
    required this.total,
    required this.bookings,
    this.poojaName,
    this.specialPooja = false,
    this.userEmail,
    this.createdAt,
  });

  final int id;
  final PoojaStatus poojaStatus; // derived rollup — read-only
  final String status;
  final double total;
  final List<Booking> bookings;
  final String? poojaName;
  final bool specialPooja;
  final String? userEmail;
  final DateTime? createdAt;

  List<Booking> get markable => bookings.where((b) => b.canMark).toList();

  factory PoojaOrder.fromJson(Map<String, dynamic> j) => PoojaOrder(
        id: j['id'] as int,
        poojaStatus: poojaStatusFrom(j['pooja_status'] as String?),
        status: j['status'] as String? ?? 'confirmed',
        total: double.tryParse('${j['total'] ?? '0'}') ?? 0,
        poojaName: j['pooja_name'] as String?,
        specialPooja: j['special_pooja'] as bool? ?? false,
        userEmail: j['user_email'] as String?,
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? ''),
        bookings: ((j['order_lines'] as List?) ?? const [])
            .map((e) => Booking.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class TodaysWork {
  const TodaysWork({required this.category, required this.orders});
  final God category;
  final List<PoojaOrder> orders;

  factory TodaysWork.fromJson(Map<String, dynamic> j) => TodaysWork(
        category: God.fromJson(j['category'] as Map<String, dynamic>),
        orders: ((j['orders'] as List?) ?? const [])
            .map((e) => PoojaOrder.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
```

---

## 8. Marking a status

```
PATCH /api/poojari/pooja-management/
{
  "order_id": 4182,
  "order_line_ids": [9051, 9052],
  "pooja_status": "completed"
}
```

| Field | Required | Note |
|---|---|---|
| `order_id` | yes | |
| `order_line_ids` | **effectively yes** | The bookings to move. Non-empty list. |
| `pooja_status` | yes | `pending` \| `completed` \| `cancelled` |

> **Always send `order_line_ids`.** Omitting it is legal and moves *every*
> booking on the order — other poojas, other dates, other people. That default
> exists only for the older order-level callers. A Flutter screen that shows
> booking rows should always name the rows it is moving, even when the poojari
> ticked all of them.

Marking `completed` also records the caller as the performing poojari on any
booking nobody had been assigned — you get the work by doing it. A booking the
back office gave to someone else is refused before anything is written.
Completing an already-completed booking is a **no-op, not an error**, so a
double-tapped button is safe.

### Three different success bodies

`completed` / `pending` — `200`:

```json
{
  "message": "Pooja status updated to completed",
  "bookings_updated": 2,
  "order": {
    "id": 4182, "pooja_status": "pending", "status": "confirmed",
    "total": "750.00", "refund_amount": "0.00", "refund_status": "none",
    "order_lines": [
      { "id": 9051, "pooja_name": "ഗണപതി ഹോമം", "status": "confirmed",
        "pooja_status": "completed", "poojari": 41 }
    ]
  }
}
```

`cancelled`, nothing captured (COD / unpaid) — `200`, and **no
`bookings_updated` key**:

```json
{ "message": "Bookings cancelled successfully.", "order": { … } }
```

`cancelled`, paid — `200`, plus refund fields:

```json
{ "message": "Bookings cancelled successfully. Refund has been initiated.",
  "refund_id": "rfnd_Nx…", "refund_amount": "250.00", "order": { … } }
```

Only the bookings actually cancelled are refunded; the rest of the order stands
and its money with it. Read `bookings_updated` as nullable.

### Note the `order` object is a *different* shape

The PATCH response's `order` is the **detail** serializer, not the list one. It
has `refund_amount` / `refund_status` that the list lacks, and its
`order_lines` carry only `id, pooja_name, status, pooja_status, poojari` —
no devotee, no date, no price. Its `order_lines` are also **every** line on the
order, not just the ones for your god.

So: **do not replace your list row with this object.** Use it to patch the
fields it actually carries.

```dart
class StatusUpdateResult {
  const StatusUpdateResult({
    required this.message,
    required this.orderPoojaStatus,
    required this.orderStatus,
    required this.lineStatuses,
    this.bookingsUpdated,
    this.refundId,
    this.refundAmount,
  });

  final String message;
  final PoojaStatus orderPoojaStatus;
  final String orderStatus;
  /// line id -> its new pooja_status, for the lines this response mentions.
  final Map<int, PoojaStatus> lineStatuses;
  final int? bookingsUpdated;   // absent on the cancel paths
  final String? refundId;
  final double? refundAmount;

  bool get refundStarted => refundId != null;

  factory StatusUpdateResult.fromJson(Map<String, dynamic> j) {
    final order = j['order'] as Map<String, dynamic>;
    final lines = (order['order_lines'] as List?) ?? const [];
    return StatusUpdateResult(
      message: j['message'] as String? ?? '',
      bookingsUpdated: j['bookings_updated'] as int?,
      refundId: j['refund_id'] as String?,
      refundAmount: j['refund_amount'] == null
          ? null
          : double.tryParse('${j['refund_amount']}'),
      orderPoojaStatus: poojaStatusFrom(order['pooja_status'] as String?),
      orderStatus: order['status'] as String? ?? '',
      lineStatuses: {
        for (final l in lines.cast<Map<String, dynamic>>())
          l['id'] as int: poojaStatusFrom(l['pooja_status'] as String?),
      },
    );
  }
}
```

### The repository call

```dart
Future<StatusUpdateResult> markBookings({
  required int orderId,
  required List<int> bookingIds,
  required PoojaStatus status,
}) async {
  assert(bookingIds.isNotEmpty, 'Never send an empty list — omitting the key moves the whole order.');

  final res = await api.dio.patch('/api/poojari/pooja-management/', data: {
    'order_id': orderId,
    'order_line_ids': bookingIds,
    'pooja_status': status.name,
  });

  final body = res.data as Map<String, dynamic>;
  if (res.statusCode == 200) return StatusUpdateResult.fromJson(body);
  throw PoojaApiException.fromResponse(res.statusCode!, body);
}
```

### Merging the result back

```dart
PoojaOrder applyUpdate(PoojaOrder order, StatusUpdateResult r) => PoojaOrder(
      id: order.id,
      // The rollup is the server's to compute — take it, never derive it.
      poojaStatus: r.orderPoojaStatus,
      status: r.orderStatus,
      total: order.total,
      poojaName: order.poojaName,
      specialPooja: order.specialPooja,
      userEmail: order.userEmail,
      createdAt: order.createdAt,
      // Only touch the lines the response actually mentions; the response
      // carries every line on the order, ours are a subset of it.
      bookings: [
        for (final b in order.bookings)
          r.lineStatuses.containsKey(b.id)
              ? b.copyWith(poojaStatus: r.lineStatuses[b.id])
              : b,
      ],
    );
```

### Optimistic UI

Marking done is the app's whole job and it happens standing in a shrine on
patchy 4G. Flip the row immediately, send, and reconcile:

```dart
Future<void> toggleDone(int orderId, Booking booking) async {
  final target = booking.isDone ? PoojaStatus.pending : PoojaStatus.completed;
  final snapshot = state;                 // for rollback
  state = state.withBookingStatus(booking.id, target);   // optimistic

  try {
    final r = await repo.markBookings(
      orderId: orderId, bookingIds: [booking.id], status: target,
    );
    state = state.applyUpdate(orderId, r);
  } on PoojaApiException catch (e) {
    state = snapshot;                     // put it back
    if (e.isAssignedToSomeoneElse || e.isStaleOrder) {
      await refresh();                    // the list is out of date, reload it
    }
    showError(e.message);
  }
}
```

Cancelling is **not** optimistic. It moves money — put it behind a confirmation
sheet that names the bookings and the amount, and show a blocking spinner until
the response lands. If `refundStarted` is true, say so in the success toast:
the devotee's refund is now in flight at Razorpay.

---

## 9. Profile

```
GET   /api/poojari/profile/       → { id, username, email, first_name, last_name, phone_number, role }
PATCH /api/poojari/profile/<id>/  → { message, updated_fields, profile }
```

Note the router shape: the read is the **list** route (no id), the write is the
**detail** route (id in the path). The server updates `request.user` regardless
of the id in the path — pass your own to keep it honest.

Editable: `first_name`, `last_name`, `email`, `username`.
`phone_number` and `role` are read-only.

> ⚠️ **Known backend bug — don't build against the empty-body case.**
> `PoojariProfileView.partial_update` reads `serializer.validated_data` *before*
> calling `is_valid()`, which raises inside DRF. A PATCH with an empty or
> all-unknown body returns **`500`**, not the documented `400 "No valid fields
> provided"`. Validate client-side that at least one known field changed, and
> only then send.

---

## 10. Errors, and what the UI should do with each

Every error body on these endpoints is `{"error": "..."}`, occasionally with
`"details"` from the serializer. RBAC denials are DRF's own shape,
`{"detail": "..."}` — read both keys.

| Status | `error` | Cause | Flutter |
|---|---|---|---|
| `400` | `category_id is required` | Tab id missing from the query | Bug — always send it |
| `400` | `Invalid input` + `details` | Bad `pooja_status`, empty `order_line_ids` | Bug — show generic, log `details` |
| `400` | `Bookings [9052] are not on order 4182` | Stale list; the line moved | Refresh the list |
| `400` | `Cannot modify pooja_status. Order is already cancelled` | Someone cancelled it meanwhile | Refresh the list |
| `400` | `No active bookings to cancel` | Already cancelled/refunded | Refresh the list |
| `400` | `Refund already in progress: pending` | Double-submitted cancel | Toast; do not retry |
| `403` | `Bookings [9052] are assigned to another poojari` | The back office gave it away | Toast + refresh |
| `403` | `CSRF Failed: …` / `detail` | Missing `X-CSRFToken` | See §3 — this is a client bug |
| `403` | `detail: You do not have permission…` | Role/permission missing | Sign out; tell them to call the admin |
| `403` | *(unauthenticated)* | Session expired | Clear jar, go to login |
| `404` | `Pooja order not found` | Deleted | Refresh the list |
| `404` | `Category not found` | Stale tab | Refresh the tabs |
| `429` | *(DRF throttle)* | 2000 req/hour per user | Back off; stop polling |
| `500` | `Failed to initiate refund: …` | Razorpay refused | Toast; the cancel did **not** happen |
| `500` | `Refund was initiated … but the database update failed` + `refund_id` | Money left, DB didn't | **Show the `refund_id` and tell them to call the temple office.** Do not retry — a retry could refund twice. |

Note that on a `403`, an unauthenticated caller and a caller who lacks a
permission look almost identical. Distinguish them by whether you hold a
session: no `sessionid` cookie → login screen; cookie present → permissions.

```dart
class PoojaApiException implements Exception {
  PoojaApiException(this.statusCode, this.message, {this.details, this.refundId});
  final int statusCode;
  final String message;
  final Map<String, dynamic>? details;
  final String? refundId;

  factory PoojaApiException.fromResponse(int code, Map<String, dynamic> body) =>
      PoojaApiException(
        code,
        (body['error'] ?? body['detail'] ?? 'Something went wrong') as String,
        details: body['details'] as Map<String, dynamic>?,
        refundId: body['refund_id'] as String?,
      );

  bool get isAssignedToSomeoneElse =>
      statusCode == 403 && message.contains('assigned to another poojari');
  bool get isStaleOrder =>
      statusCode == 404 ||
      (statusCode == 400 &&
          (message.contains('are not on order') ||
           message.contains('already cancelled') ||
           message.contains('No active bookings')));
  /// Money moved but the record didn't. Never retry this one.
  bool get needsManualReconciliation => statusCode == 500 && refundId != null;
}
```

---

## 11. Gotchas that will cost you a day each

1. **Session cookies, not tokens.** No `Authorization` header will ever work.
   Persist the jar or the poojari re-logs in on every cold start (§3).
2. **`X-CSRFToken` on every write.** Sign-in is exempt; the PATCH is not.
3. **Two status fields per booking.** `status` is money
   (`confirmed`/`cod`/`cancelled`/`refunded`), `pooja_status` is execution
   (`pending`/`completed`/`cancelled`). A refunded booking has
   `status: refunded` and `pooja_status: cancelled`.
4. **The order's `pooja_status` is derived.** Never write it, never compute it
   locally; take the server's rollup out of the PATCH response.
5. **Always send `order_line_ids`.** Omitting it moves the entire order.
6. **Money arrives as strings.** `"750.00"`, not `750.0`.
7. **`nakshtram`** — misspelled on the wire, deliberately left alone.
8. **The list is today-only, in `Asia/Kolkata`.** A device set to another
   timezone or a manual "today" computed client-side will disagree with the
   server. Never send a date; there is no date parameter.
9. **The stats panel is all-time and all-poojaris**, while the list under it is
   today-and-yours. Label them differently (§6).
10. **`?pooja_status=` filters orders, not bookings** (§7).
11. **`category_id` is mandatory** on the list endpoint — there is no "all
    gods" view. The first tab must be selected before the first fetch.
12. **The PATCH response's `order.order_lines` is a different, thinner shape**
    and covers *every* line on the order (§8). Merge, don't replace.
13. **Names are Malayalam.** `pooja_name`, `category.name` and `nakshtram` come
    back in Malayalam script. Bundle a font with Malayalam coverage (Noto Sans
    Malayalam) — the default Android/iOS stack renders some of these as boxes.
14. **Cache invalidation.** `GET /api/booking/global-update/` returns
    `{"last_updated": "…"}` in `Asia/Kolkata` and bumps whenever orders or lines
    change. Poll it on resume to decide whether to invalidate cached catalogue
    data — don't poll the list endpoint itself, the throttle is 2000/hour.
15. **Nothing here is paginated** except the catalogue endpoints, and those
    only when you ask.

---

## 12. Integration checklist

- [ ] `PersistCookieJar` wired to `getApplicationSupportDirectory()`
- [ ] `X-CSRFToken` + `Referer` interceptor on all unsafe methods
- [ ] `GET /api/auth/csrf/` called before the login form submits
- [ ] `requires_password_setup` branch handled on sign-in
- [ ] Cold start restores the session via `GET /api/poojari/profile/`
- [ ] Logout calls the endpoint **and** clears the jar
- [ ] Tabs from `poojacategory`, sorted by `sort_order`
- [ ] List renders one card per order, one checkable row per booking
- [ ] Server sort order (pending → completed → cancelled) preserved
- [ ] `order_line_ids` always sent, never empty
- [ ] Optimistic tick with rollback on error; refresh on stale-list errors
- [ ] Cancel is confirmed, blocking, and surfaces `refund_id`
- [ ] `500` + `refund_id` shows a call-the-office message and blocks retry
- [ ] Decimals parsed from strings
- [ ] Malayalam font bundled and applied to devotee/pooja/god names
- [ ] Counter walk-ins (`user_list: null`) render a placeholder
- [ ] `403` disambiguated: session expired vs permission denied
- [ ] No polling loops (2000 req/hour cap)

---

## Appendix — `main` vs `hari-dev`

If you point the app at a server running `main`, three things differ:

| | `main` | `hari-dev` |
|---|---|---|
| PATCH granularity | `order_id` only — moves the whole order | `order_line_ids` picks bookings |
| PATCH response | no `bookings_updated` | `bookings_updated` on the non-cancel path |
| Booking rows | no `pooja_status`, no `poojari_id` on `order_lines` | both present |
| List scoping | god only | god **and** yours-or-nobody's |
| "Today" | `timezone.now().date()` (UTC) | `timezone.localdate()` (`Asia/Kolkata`) |
| God link | one `category` FK per pooja | `gods` M2M, primary god first |
| Permissions | `IsTemplePoojari` (role check) | RBAC permission map |

The models above parse a `main` response without throwing — `pooja_status` and
`poojari_id` come through null and `Booking.poojaStatus` falls back to
`pending`. What you cannot do on `main` is mark one booking of several: send
`order_line_ids` there and it is ignored, and the whole order moves.
