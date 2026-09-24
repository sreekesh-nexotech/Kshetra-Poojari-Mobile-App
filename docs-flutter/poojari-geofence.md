# Poojari attendance — geofenced marking

**From:** Backend **To:** Mobile / frontend
**Branch:** `hari-dev` **Date:** 10 Sep 2026
**Related:** [poojari-app-handover.md](poojari-app-handover.md) ·
[POOJARI_APP_API.md](POOJARI_APP_API.md)

Marking attendance now requires the poojari to be inside the temple premises.
The app sends its coordinates with the mark; the server measures the distance
itself and refuses marks made from outside the radius.

**Three endpoints are involved.** Two are new, one changed:

| | Endpoint | Status |
|---|---|---|
| §2 | `GET /api/poojari/attendance/location/` | **new** — where they must stand |
| §3 | `POST /api/poojari/attendance/` | **changed** — now takes coordinates |
| §4 | `GET /api/poojari/attendance/` | changed — 4 new read-only fields |

---

## 1. Read this first

### 1.1 The server is the authority, not the app

Run `Geolocator.distanceBetween` before enabling the button — it is what makes
the button honest instead of throwing a refusal at the user. But the server
measures again on every mark and its answer is the one that counts. **Handle
`403` on the POST even when your own check passed**, because the two can
disagree: a stale cached radius, a coordinate that drifted between the check
and the send, or an admin narrowing the radius mid-session.

Do not send a `distance_meters` you calculated. The server ignores it and
computes its own.

### 1.2 Only *today + present* is geofenced

| Mark | Coordinates | Geofenced |
|---|---|---|
| Today, `present` | **required** | **yes** |
| Today, `leave` / `absent` | optional, ignored | no |
| A past date, any status | optional, ignored | no |

Marking leave from home is the point of marking leave, and a poojari correcting
last Tuesday is not standing in last Tuesday. So only a same-day presence claim
has to prove where it was made from.

> **`date: "<today>"` sent explicitly is still geofenced.** The exemption is for
> past days, not for typing today's date out.

### 1.3 Enforcement ships OFF

`POOJARI_ATTENDANCE_GEOFENCE_ENFORCED` is `False` until the app build that
sends coordinates is live. While off:

* coordinates are **still recorded and still measured** when you send them,
* `location_verified` is still set honestly,
* but **no mark is ever refused** — you will not see `403` or `409`.

**This does not mean you can skip sending coordinates.** The `400` for a
missing latitude is enforced by the serializer and is on *now*, regardless of
the flag. Build against the enforced behaviour; you simply will not be able to
observe `403` on the test server until the flag is flipped.

### 1.4 Auth and headers — the same as every other poojari endpoint

Nothing new here; restated so this document stands alone.

| Header | Value | When |
|---|---|---|
| `Cookie` | `sessionid=…` | every request (set by sign-in) |
| `X-CSRFToken` | the `csrftoken` cookie's value | **`POST` only** |
| `Content-Type` | `application/json` | `POST` only |
| `Referer` | your origin | `POST` only, over HTTPS |

Session auth, cookie-based — there is no bearer token. Order of operations:

1. `GET /api/auth/csrf/` → sets the `csrftoken` cookie.
2. `POST /api/auth/poojari-signin/` → sets the `sessionid` cookie.
3. Send both cookies on every call below; echo the CSRF token in `X-CSRFToken`
   on writes.

Your HTTP client must persist cookies across requests (`CORS_ALLOW_CREDENTIALS`
is on server-side). Throttle: **2000 requests/hour** per authenticated user.

**No poojari id appears anywhere** — in path, query or body. Every endpoint here
acts on the signed-in user. A `poojari` key in the body is ignored, not honoured.

---

## 2. Temple location — where they have to be standing

* **Name / purpose:** Fetch the coordinates and radius the app runs its own
  pre-check against. Call once per session and cache; re-fetch on a `409`.
* **Method + path:** `GET /api/poojari/attendance/location/`
* **Headers:**
  * `Cookie: sessionid=…` *(required)*
  * No CSRF or `Content-Type` — it is a read.
* **Path / query params:** none.
* **Request body:** none.

**Success response — `200 OK`**

```json
{
  "location": {
    "id": 2,
    "name": "Main Temple",
    "latitude": "10.123456",
    "longitude": "76.654321",
    "radius_meters": 200
  }
}
```

`latitude` and `longitude` are **strings**, not floats — they are decimals with
6 places and JSON floats would lose precision. Parse with `double.parse()`.
`radius_meters` is an integer.

**`location` is `null` when no site is configured:**

```json
{ "location": null }
```

Still `200`. Show a "contact the temple office" state and **disable the mark
button** — a mark attempted in this state comes back `409`. Do not treat `null`
as "no geofence, mark freely".

**Error responses**

| Code | Body | Meaning |
|---|---|---|
| `403` | `{"detail": "Authentication credentials were not provided."}` | Not signed in, or the session expired |
| `403` | `{"detail": "You do not have permission to perform this action."}` | Signed in but not a poojari |

* **Pagination:** none. Single object.

---

## 3. Mark attendance

* **Name / purpose:** Mark one day. Upserts — posting the same date twice
  corrects the existing mark rather than duplicating it.
* **Method + path:** `POST /api/poojari/attendance/`
* **Headers:**
  * `Cookie: sessionid=…` *(required)*
  * `X-CSRFToken: <csrftoken cookie>` *(required)*
  * `Content-Type: application/json` *(required)*
* **Path / query params:** none.

**Request body**

| Field | Type | Required | Notes |
|---|---|---|---|
| `status` | `"present"` \| `"absent"` \| `"leave"` | no | defaults to `"present"` |
| `latitude` | string or number, −90…90 | **when today + present** | 6 decimal places |
| `longitude` | string or number, −180…180 | **when today + present** | 6 decimal places |
| `date` | `"YYYY-MM-DD"` | no | defaults to today (IST). Not the future; max 31 days back |
| `remarks` | string, ≤1000 | no | defaults to `""` |

Send `latitude`/`longitude` **as strings** to avoid float rounding. Both or
neither — one without the other is a `400`.

```json
{
  "status": "present",
  "latitude": "10.123456",
  "longitude": "76.654321"
}
```

Marking leave for a past day, no coordinates needed:

```json
{
  "status": "leave",
  "date": "2026-09-09",
  "remarks": "Family function"
}
```

**Success response — `201 Created`** (new mark) or **`200 OK`** (corrected an
existing one; `created` is `false`)

```json
{
  "message": "Attendance marked",
  "created": true,
  "attendance": {
    "id": 2,
    "date": "2026-09-10",
    "status": "present",
    "remarks": "",
    "latitude": "10.123456",
    "longitude": "76.654321",
    "distance_meters": 0,
    "location_verified": true,
    "marked_at": "2026-09-10T11:25:54.332594+05:30",
    "updated_at": "2026-09-10T11:25:54.332606+05:30"
  }
}
```

Branch on `created`, not on the status code, if you need to tell "marked" from
"updated" — `message` is already worded for display.

### Error responses

**`403` — outside the premises.** The one to build a real screen for.

```json
{
  "error": "Outside temple premises",
  "detail": "You need to be inside the temple premises to mark attendance.",
  "distance_meters": 178773,
  "radius_meters": 200,
  "location": {
    "id": 2,
    "name": "Main Temple",
    "latitude": "10.123456",
    "longitude": "76.654321",
    "radius_meters": 200
  }
}
```

**No row is written.** Use `distance_meters` to say *how far* — "You are 850m
away, move within 200m" beats "not allowed". The embedded `location` is the
server's current config: if it disagrees with your cache, replace your cache
with it.

> Distinguish this `403` from the auth `403` by the presence of `error` — the
> auth failures return `detail` only, with no `error` key.

**`409` — no temple location configured.** A deployment problem, not the
poojari's fault. Say so; do not blame their GPS.

```json
{
  "error": "No temple location configured",
  "detail": "Attendance cannot be verified yet. Ask the temple office to set up the attendance location."
}
```

No row is written. Also returned when the temple has several active sites and
this poojari is assigned to none — the server refuses to guess rather than pick
one. Re-fetch §2 before retrying.

**`400` — bad payload.** Always `{"error": "Invalid input", "details": {...}}`,
with `details` keyed by field name and each value an array of messages.

Missing location on a same-day present mark:

```json
{
  "error": "Invalid input",
  "details": {
    "latitude": ["Location is required to mark attendance for today. Enable location access and try again."]
  }
}
```

One coordinate without the other:

```json
{
  "error": "Invalid input",
  "details": { "longitude": ["Latitude and longitude must be sent together."] }
}
```

A future date:

```json
{
  "error": "Invalid input",
  "details": { "date": ["Attendance cannot be marked for a future date."] }
}
```

Beyond the 31-day backdating limit:

```json
{
  "error": "Invalid input",
  "details": { "date": ["Attendance can only be marked up to 31 days back."] }
}
```

An out-of-range coordinate (`latitude: "99.0"`) is also a `400`, refused before
any distance is taken.

**Summary**

| Code | `error` key | Row written | What to show |
|---|---|---|---|
| `201` / `200` | — | yes | Success |
| `400` | `"Invalid input"` | no | Read `details` |
| `403` | `"Outside temple premises"` | **no** | Distance + "move closer" |
| `403` | *(absent — `detail` only)* | no | Re-authenticate |
| `409` | `"No temple location configured"` | **no** | "Contact the office" |

* **Pagination:** none.

---

## 4. Read the attendance sheet back

* **Name / purpose:** The poojari's own marks over a window. Unchanged except
  for four new fields on each record.
* **Method + path:** `GET /api/poojari/attendance/`
* **Headers:** `Cookie: sessionid=…` *(required)*. No CSRF — it is a read.
* **Query params:**

| Param | Values | Default |
|---|---|---|
| `period` | `weekly` \| `monthly` | `monthly` |
| `date_from` | `YYYY-MM-DD` | start of the current period |
| `date_to` | `YYYY-MM-DD` | end of the current period |

* **Request body:** none.

**Success response — `200 OK`**

```json
{
  "poojari": {
    "id": 7,
    "name": "verify-poojari",
    "username": "verify-poojari",
    "employee_id": null
  },
  "period": {
    "period": "weekly",
    "date_from": "2026-09-07",
    "date_to": "2026-09-13",
    "days": 7
  },
  "count": 2,
  "records": [
    {
      "id": 2,
      "date": "2026-09-10",
      "status": "present",
      "remarks": "",
      "latitude": "10.123456",
      "longitude": "76.654321",
      "distance_meters": 0,
      "location_verified": true,
      "marked_at": "2026-09-10T11:25:54.332594+05:30",
      "updated_at": "2026-09-10T11:25:54.332606+05:30"
    },
    {
      "id": 3,
      "date": "2026-09-09",
      "status": "leave",
      "remarks": "Family function",
      "latitude": null,
      "longitude": null,
      "distance_meters": null,
      "location_verified": false,
      "marked_at": "2026-09-10T11:25:54.379803+05:30",
      "updated_at": "2026-09-10T11:25:54.379818+05:30"
    }
  ]
}
```

**The four new fields, all read-only and all nullable except the last:**

* **`latitude` / `longitude`** — strings or `null`. Where the device was.
* **`distance_meters`** — integer or `null`. Metres from the site at the moment
  of marking, stored rather than recomputed: if the radius is widened later, the
  record still says how far away they actually were.
* **`location_verified`** — **boolean, never null.** `true` only when the server
  measured the distance *and* accepted it.

> ⚠️ **`location_verified: false` does not mean "cheated".** It is `false` for a
> leave, for a backdated mark, for every row created before this feature, and
> for anything marked while enforcement was off. Do not render it as a warning
> on the poojari's own sheet. `records` is sorted newest first.

**Error responses**

| Code | Body |
|---|---|
| `400` | `{"error": "Invalid input", "details": {…}}` — bad `period` or a backwards date range |
| `403` | `{"detail": "Authentication credentials were not provided."}` |
| `403` | `{"detail": "You do not have permission to perform this action."}` |

* **Pagination:** none — every mark in the window is returned in one response.
  The window itself is capped at **731 days**, and there is at most one record
  per day, so a request can return up to ~731 records. Use `period=weekly` or
  `monthly` (or explicit `date_from`/`date_to`) rather than pulling a wide range
  you then filter client-side.

---

## 5. Suggested flow

```
sign in
  └─ GET /api/poojari/attendance/location/   → cache {lat, lng, radius}
       ├─ location == null → disable button, "contact the office"
       └─ otherwise
            on button press:
              Geolocator.getCurrentPosition()
              distanceBetween(current, cached) <= radius ?
                ├─ no  → "You are N m away" (no request sent)
                └─ yes → POST /api/poojari/attendance/
                           ├─ 201/200 → success
                           ├─ 403 + error → show distance_meters, refresh cache
                           ├─ 409        → "contact the office", refresh cache
                           └─ 400        → read details
```

**Edge cases worth handling explicitly**

* **Location permission denied / GPS off.** You cannot produce coordinates, so a
  same-day present mark will `400`. Prompt for permission rather than sending
  the request. Leave and absent still work — offer those.
* **A stale cache.** Both `403` and `409` carry enough to re-sync; re-fetch §2
  after either.
* **Marking twice in a day.** Expected and supported. The second mark replaces
  the first, including its coordinates. A *refused* second mark leaves the good
  first one untouched.
* **Crossing midnight.** `date` defaults to the temple's own day in IST
  (`Asia/Kolkata`), not UTC. A poojari marking at 00:30 IST lands on the day
  they are standing in. Do not compute the date from a device clock in another
  timezone.

---

## 6. What backend still needs from ops before flipping the switch

Not your work, listed so the sequencing is visible:

1. Create the `TempleLocation` row (Django admin, or
   `POST /api/admin/temple-locations/` — admin/manager only).
2. Ship this app build.
3. Confirm marks are arriving with coordinates.
4. Set `POOJARI_ATTENDANCE_GEOFENCE_ENFORCED=True`.

Until step 4 the geofence records but never refuses, so the app can ship before
the flag is flipped without a coordinated release.
