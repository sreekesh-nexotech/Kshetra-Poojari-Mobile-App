# Poojari app API

`/api/poojari/` — and the back office's half of the same screens under
`/api/admin/poojaris/`.

> Building the app against this? [`../flutter/pooja-booking.md`](../flutter/pooja-booking.md)
> is the client-side companion: Dio + cookie-jar setup, Dart models, and the
> traps in the booking screen's payloads.

Three things a poojari does in the app, and the back office's view of each:

| What | The poojari's endpoint | The back office's |
|---|---|---|
| Mark a pooja performed | `PATCH /api/poojari/pooja-management/` | [`POST /api/admin/bookings/complete/`](pooja-bookings.md#5-mark-bookings-as-performed) |
| Choose which gods they serve | `GET`/`PUT /api/poojari/gods/` | `GET`/`PUT /api/admin/poojaris/<id>/gods/` |
| Mark and read attendance | `POST`/`GET /api/poojari/attendance/` | `GET /api/admin/poojaris/<id>/attendance/` |

> **The poojari's endpoints take no poojari id — anywhere.**
> Not in the path, not in the body. That is not a convenience; it is the
> guarantee. There is no parameter on `/api/poojari/…` that could be pointed at
> a colleague, so "only that poojari and the admin" is enforced by the shape of
> the URL rather than by a check that could be forgotten. Reading or writing
> somebody *else's* row is a different endpoint under `/api/admin/`, behind a
> different permission.

---

## Contents

1. [Auth and permissions](#1-auth-and-permissions)
2. [The gods a poojari serves](#2-the-gods-a-poojari-serves)
3. [What the shrine list narrows](#3-what-the-shrine-list-narrows)
4. [Marking a pooja's status](#4-marking-a-poojas-status)
5. [Marking attendance](#5-marking-attendance)
6. [The attendance report](#6-the-attendance-report)
7. [The back office's register](#7-the-back-offices-register)
8. [Error responses](#8-error-responses)
9. [Deploying this](#9-deploying-this)

---

## 1. Auth and permissions

Session cookies, same as the rest of the API — see
[`API_PERMISSIONS.md`](../../API_PERMISSIONS.md) §1–3. Send
`credentials: "include"` on every request and the CSRF header on writes.

| Endpoint | Permission required |
|---|---|
| `GET /api/poojari/pooja-management/` | `rbac.view_assigned_pooja_orders` |
| `PATCH /api/poojari/pooja-management/` | `rbac.update_pooja_status` |
| `GET /api/poojari/pooja-stats/` | `rbac.view_poojari_stats` |
| `GET /api/poojari/gods/` | `rbac.assign_own_gods` **+** `temple_poojari.view_poojarigod` |
| `PUT /api/poojari/gods/` | `rbac.assign_own_gods` **+** `temple_poojari.add_poojarigod` **+** `…delete_poojarigod` |
| `GET /api/poojari/attendance/` | `rbac.view_own_attendance` **+** `temple_poojari.view_poojariattendance` |
| `POST /api/poojari/attendance/` | `rbac.mark_own_attendance` **+** `temple_poojari.add_poojariattendance` **+** `…change_poojariattendance` |
| `GET /api/poojari/attendance/report/` | `rbac.view_own_attendance` **+** `temple_poojari.view_poojariattendance` |
| `GET /api/admin/poojaris/<id>/gods/` | `rbac.manage_poojaris` **+** `temple_poojari.view_poojarigod` |
| `PUT /api/admin/poojaris/<id>/gods/` | `rbac.manage_poojari_gods` **+** `temple_poojari.add_poojarigod` **+** `…delete_poojarigod` |
| `GET /api/admin/poojaris/<id>/attendance/` | `rbac.view_poojari_attendance` **+** `temple_poojari.view_poojariattendance` |
| `GET /api/admin/poojaris/attendance/` | `rbac.view_poojari_attendance` **+** `temple_poojari.view_poojariattendance` |

`assign_own_gods` and `manage_poojari_gods` are deliberately different
permissions. The first can only ever act on its holder; the second decides
another person's workload. `temple_poojari` holds the first and never the
second. Likewise `view_own_attendance` versus `view_poojari_attendance`.

Nobody holds a write permission on somebody else's attendance — not even
Admin. A sheet an administrator could fill in is not a record of who turned up.

In the role editor these appear under **Poojaris** as `gods_read`,
`gods_update` and `attendance`. Admin and Manager hold all three; Reports
Manager holds the two reads.

---

## 2. The gods a poojari serves

A god is a `PoojaCategory` — see
[pooja_management_god.md](pooja_management_god.md). The temple's poojaris are
not interchangeable: one keeps the Ganapathi shrine, another the Devi shrine.
This list is that split.

### Read it

```
GET /api/poojari/gods/
```

**Response `200`:**

```json
{
  "count": 1,
  "gods": [
    {
      "id": 7,
      "god": {
        "id": 3,
        "name": "ഗണപതി",
        "media_public_id": "temple/gods/ganapathi",
        "media_url": "https://cdn.example.com/temple/gods/ganapathi.webp",
        "home_media_public_id": null,
        "home_media_url": null,
        "is_active": true
      },
      "assigned_by_name": "Aravind Nair",
      "assigned_at": "2026-08-22T09:14:03.117Z"
    }
  ]
}
```

`assigned_by_name` is `null` when the poojari chose the god themselves, and
names the admin when the back office rostered them.

### Replace it

```
PUT /api/poojari/gods/
{ "god_ids": [3, 11] }
```

The whole list, replaced — the screen behind this is a row of tickboxes, and
sending what is ticked is both what it knows and the only version that cannot
leave the roster half-applied. Only the difference is written, so re-saving an
unchanged list keeps the rows it had, along with who assigned them and when.

**Response `200`:** `{ "message": "Gods updated successfully", "count": 2, "gods": [ … ] }`

The same two calls exist under `/api/admin/poojaris/<id>/gods/` for the back
office, with the poojari named in the path and `assigned_by` recorded as the
admin who made the call.

---

## 3. What the shrine list narrows

> **An empty list means *every* god, not *no* god.**

This is the single most important rule on this page. A poojari with no gods
assigned is **unscoped**: they see every god's bookings, which is exactly what
every poojari did before shrines existed. Assigning the first god is what turns
the scoping on; clearing the list turns it back off. That way this feature
could ship without blanking the screen of every poojari in the temple, and a
temple that does not want shrine scoping simply never uses it.

Once a poojari has at least one god, three things narrow to it:

**`GET /api/poojari/pooja-management/`** — the booking list.

| `category_id` | Unscoped poojari | Scoped poojari |
|---|---|---|
| A god they serve | `200`, that god's bookings | `200`, that god's bookings |
| A god they do not serve | `200`, that god's bookings | **`403`** |
| Omitted | **`400`** `category_id is required` | `200`, **every shrine they keep**, in one list |

Omitting `category_id` is new and is the poojari app's home screen — two
shrines are two tabs, and this is the "All" one. The response gained a
`categories` array for it:

```json
{
  "category": null,
  "categories": [ { "id": 3, "name": "ഗണപതി", … }, { "id": 11, "name": "ദേവി", … } ],
  "count": 4,
  "orders": [ … ]
}
```

`category` is the god that was *asked for* and stays `null` when the whole
shrine list was; it still carries the single god for existing callers that pass
`category_id`. `categories` is what the rows are actually scoped to either way,
so it is the one a client can always read.

A god the poojari does not serve is refused with `403` rather than answered
with an empty `200`. An empty list reads as "nothing on today" — the poojari
would wait at a shrine that was never theirs for work that was never coming.

**`GET /api/poojari/pooja-stats/`** — the panel above that list. Scoped the
same way: with no `category_id` it returns a row per shrine they keep, and a
god they do not serve is a `403`.

**`PATCH /api/poojari/pooja-management/`** — see below.

Shrine scoping stacks on top of the assignment rule that was already there:
a booking must be **for a god you serve** *and* **assigned to you or to
nobody**. See [pooja-bookings.md §8](pooja-bookings.md#8-how-assignment-looks-to-the-poojari).

---

## 4. Marking a pooja's status

```
PATCH /api/poojari/pooja-management/
{
  "order_id": 4182,
  "order_line_ids": [9051, 9052],
  "pooja_status": "completed"
}
```

`pooja_status` is one of `pending`, `completed`, `cancelled`.

**`order_line_ids` is the field that matters.** The unit here is the *booking*
— one pooja, one person, one date — not the order, which can hold a whole
family's checkout across several poojas and dates. Omitting `order_line_ids`
moves every booking on the order, which is what the older order-level callers
expect; send it to move only the bookings meant.

Marking a booking `completed` records the caller as the poojari who performed
it, where nobody had been assigned it. Marking `cancelled` refunds only the
bookings actually cancelled and recomputes the order's own status from what is
left standing.

Four things are refused:

| Response | When |
|---|---|
| `400` | The order is already cancelled, or an id is not on that order |
| `403` `…are assigned to another poojari` | A booking the back office gave to somebody else |
| `403` `…are for gods you do not serve` | A booking outside the caller's shrine list |
| `400` | `pooja_status` is not one of the three |

The shrine check applies to bookings nobody has been assigned, too: the list
endpoint already hides them, and without this an order id and a guess would
still move one. Note that a whole-order update (no `order_line_ids`) on an
order that straddles two shrines is refused outright rather than half-applied.

**Response `200`:**

```json
{
  "message": "Pooja status updated to completed",
  "bookings_updated": 2,
  "order": { "id": 4182, "pooja_status": "completed", "status": "confirmed", … }
}
```

---

## 5. Marking attendance

```
POST /api/poojari/attendance/
{ "status": "present" }
```

Every field is optional. `date` defaults to the temple's today
(`Asia/Kolkata`, never UTC — a poojari marking in after local midnight lands on
the day they are standing in), `status` to `present`, `remarks` to empty.

| Field | Values |
|---|---|
| `date` | `YYYY-MM-DD`. Today or earlier, at most 31 days back. |
| `status` | `present`, `absent`, `leave` |
| `remarks` | Free text, ≤ 1000 chars |

Attendance is kept per calendar **day**, not as a pair of punches: a poojari's
day at the temple is not a shift with a clock on the wall, and the question the
temple actually asks — who was here this week, and who was not — is answered by
the day.

**Marking a day already marked replaces it.** A poojari who marked leave and
then came in has to be able to say so, and a second `POST` is what the app sends
when they do. `201` on the first mark for a day, `200` on a correction; the
`created` boolean says which.

```json
{
  "message": "Attendance updated",
  "created": false,
  "attendance": {
    "id": 88,
    "date": "2026-08-22",
    "status": "present",
    "remarks": "",
    "marked_at": "2026-08-22T03:41:19.882Z",
    "updated_at": "2026-08-22T11:02:55.310Z"
  }
}
```

`marked_at` is when the mark was made, which is not the day it is *for* —
a poojari correcting yesterday this morning is a normal thing to want to see.

Backdating past 31 days is a `400`. Beyond a month the sheet is history, and an
admin should be the one to touch it — today, that means a data fix rather than
an endpoint (see §9).

### List the marks

```
GET /api/poojari/attendance/?period=monthly
```

The raw rows over a window — the same window the report is read over. Ask the
report for figures and this one for the rows behind them.

---

## 6. The attendance report

```
GET /api/poojari/attendance/report/?period=weekly
GET /api/poojari/attendance/report/?period=monthly&date_from=2026-01-01&date_to=2026-06-30
```

| Param | Meaning |
|---|---|
| `period` | `weekly` or `monthly`. Default `monthly`. |
| `date_from`, `date_to` | `YYYY-MM-DD`, inclusive. Optional. |

`period` decides **two** things: the size of the bucket, and — when no dates
are sent — the window itself. So `?period=weekly` alone is *this week, by
weeks*; `?period=monthly` alone is *this month, by months*; and either one with
dates is that longer span cut into buckets of the chosen size.

Weeks run **Monday to Sunday**. Months are calendar months. A bucket is never
wider than the window it came out of: asking for 10–20 August monthly gives one
eleven-day bucket labelled August, not the whole of August — the report's
figures are about the days asked for, so its buckets are too.

Sending only one of `date_from`/`date_to` opens the other end of *that bound's
own bucket* rather than running off to the horizon: a half-typed range is a
range being typed. A span over 731 days is a `400`.

**Response `200`:**

```json
{
  "poojari": { "id": 41, "name": "Sharma Sastrigal", "username": "sharma", "employee_id": "P-001" },
  "period": { "period": "weekly", "date_from": "2026-08-01", "date_to": "2026-08-31", "days": 31 },
  "summary": {
    "present": 5, "absent": 1, "leave": 1,
    "days": 31, "marked_days": 7, "not_marked": 24,
    "attendance_percentage": 16.1
  },
  "groups": [
    {
      "key": "2026-W32", "label": "03 Aug - 09 Aug 2026",
      "date_from": "2026-08-03", "date_to": "2026-08-09",
      "present": 5, "absent": 0, "leave": 0,
      "days": 7, "marked_days": 5, "not_marked": 2,
      "attendance_percentage": 71.4
    }
  ],
  "records": [
    { "id": 71, "date": "2026-08-03", "status": "present", "remarks": "", "marked_at": "…", "updated_at": "…" }
  ]
}
```

**`attendance_percentage` is present days over *every* day in the span, not
over the marked ones.** Five days present out of thirty-one is 16.1%. A figure
computed over only the marked days would tell a poojari who marked one day that
they had a perfect month, and that is the one number this report must not
print. `marked_days` and `not_marked` are there so a client that wants the
other ratio can compute it and label it honestly.

`key` is built from the *natural* week or month, so two reports over
overlapping windows agree on what `2026-W32` means even when one of them
clipped it.

An admin reads the same body for any poojari at
`GET /api/admin/poojaris/<id>/attendance/` — literally the same function builds
it, so the back office and the poojari can never be shown different figures for
the same weeks.

---

## 7. The back office's register

```
GET /api/admin/poojaris/attendance/?period=monthly
```

Every poojari over one window, one line each. This is a register, not a report:
it answers *who has been turning up this month* across the team, and the
drill-down behind a row is `GET /api/admin/poojaris/<id>/attendance/`. The
day-by-day `records` are left off — thirty poojaris times thirty-one days is
not a table anybody reads.

```json
{
  "period": { "period": "monthly", "date_from": "2026-08-01", "date_to": "2026-08-31", "days": 31 },
  "count": 2,
  "poojaris": [
    {
      "id": 41, "name": "Sharma Sastrigal", "username": "sharma", "employee_id": "P-001",
      "summary": { "present": 5, "absent": 1, "leave": 1, "days": 31, "marked_days": 7, "not_marked": 24, "attendance_percentage": 16.1 }
    },
    {
      "id": 42, "name": "Krishnan Namboothiri", "username": "krishnan", "employee_id": null,
      "summary": { "present": 0, "absent": 0, "leave": 0, "days": 31, "marked_days": 0, "not_marked": 31, "attendance_percentage": 0.0 }
    }
  ]
}
```

A poojari who marked nothing still gets a row — that is the point of the
screen. "Poojari" here means an account with the `temple_poojari` role **or** a
`PoojariProfile` row: the role is what the app signs in with, the profile is
what the back office registered, and an account has been able to have one
without the other since long before either of these screens existed.

The whole register is one query for the marks, not one per poojari.

---

## 8. Error responses

| Status | Body | When |
|---|---|---|
| `400` | `{"error": "category_id is required"}` | Unscoped poojari, no god named |
| `400` | `{"error": "Invalid input", "details": {…}}` | Serializer rejected the body or the query params |
| `403` | `{"error": "That god is not one of the gods you serve"}` | Listing or statting a shrine outside the list |
| `403` | `{"error": "Bookings [9052] are for gods you do not serve"}` | Marking a booking outside the list |
| `403` | `{"error": "Bookings [9052] are assigned to another poojari"}` | Marking somebody else's booking |
| `403` | *(RBAC)* | Reading a colleague's sheet, or an admin endpoint without the permission |
| `404` | `{"error": "Category not found"}` | No such `category_id` |
| `404` | *(DRF)* | No such poojari on an `/api/admin/poojaris/<id>/…` path |

---

## 9. Deploying this

Two commands, in this order:

```
python manage.py migrate
python manage.py sync_rbac
```

`migrate` creates `poojari_god` and `poojari_attendance` and the five new
permission rows; `sync_rbac` pushes those permissions onto the role groups.
Until `sync_rbac` runs, every endpoint on this page returns `403` — the
permissions exist but no group holds them. `python manage.py rbac_audit`
reports both halves.

Nothing on this page changes behaviour for an existing poojari until somebody
assigns them a god: §3's rule is what makes the deploy safe to do on a normal
day.

### Not built, and worth knowing

* **An admin cannot correct a poojari's attendance.** Deliberate — see §1 — but
  it means a poojari who forgets a fortnight has no route back except the
  Django admin at `/admin/`, where `PoojariAttendance` is registered.
* **Every calendar day counts as a working day.** There is no holiday or
  weekly-off calendar, so `attendance_percentage` is over all days in the span.
  A temple that closes on some days would want that subtracted.
