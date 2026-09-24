# Handover — poojari app backend

**From:** Backend **To:** Mobile / frontend
**Branch:** `hari-dev` (`8557832`…`56b4d43`, pushed) **Date:** 4 Sep 2026
**Answers:** [backend-endpoint-verification.md](backend-endpoint-verification.md) ·
Contract: [POOJARI_APP_API.md](POOJARI_APP_API.md) ·
Full reference: [poojari-app.md](poojari-app.md)

Every gap in your 30 Aug audit is closed. `/api/poojari/` went from **4 routes
to 10**, and all of `POOJARI_APP_API.md` is now implemented and in
`/api/schema/`. 1339 tests pass.

Read §1 before you deploy anything. The rest is additive.

---

## 1. One breaking change — `pooja-management/`

**This is the only thing here that can break the shipped app.** The booking
list is now scoped to the poojari's shrine list, which the endpoint has never
done on any server you have tested against.

| | Before | Now |
|---|---|---|
| `category_id` omitted | `400 category_id is required` | `200` — every shrine they keep |
| `category` in response | always an object | **`null`** when no single category was asked for |
| new key | — | **`categories`** — what the rows are actually scoped to |
| a god they do not serve | `200`, that god's bookings | **`403`** |
| `PATCH` on such a booking | went through | **`403`** |

```json
{
  "category": null,
  "categories": [ { "id": 3, "name": "ഗണപതി", … } ],
  "count": 4,
  "orders": [ … ]
}
```

**What to check on your side:** anything reading `category.name` unconditionally
will throw on `null`. Read `categories` instead — it is populated either way,
and it is the honest answer to "what am I looking at". Also handle `403` on both
the list and the `PATCH`.

**Why it is safe to ship anyway:** an empty shrine list means **every** god, not
none. Every poojari today has an empty list, so nothing changes for anyone until
an admin assigns a shrine. You can deploy this on a normal day.

---

## 2. Booking lines — four new fields

On **every** booking line, in both `GET` and `PATCH /api/poojari/pooja-management/`.

```json
{
  "id": 1042,
  "pooja_status": "completed",
  "remarks": "ജോലിക്ക്",
  "is_incentive_pooja": true,
  "incentive_amount": "150.00",
  "completed_at": "2026-08-30T07:40:00+05:30"
}
```

* **`remarks`** — `string`, never `null`. `""` when there is nothing to say.
* **`completed_at`** — ISO 8601 **in IST (`+05:30`)**, or `null` until performed.
  Use this, not a device clock: a pooja performed at 01:30 IST is 20:00 the
  *previous* day in UTC, and a poojari reading their day back after midnight
  must not see it fall off the end of the day they just worked.
* **`is_incentive_pooja`** — `boolean`, derived from `incentive_amount > 0`.
  Gate the coin on this.
* **`incentive_amount`** — decimal `string`, 2 d.p. Always the real figure,
  `"0.00"` included, so do **not** gate rendering on it being absent.

Both are the rate **snapshotted when the booking was taken**, so a rate edited
in the admin afterwards does not restate work already performed.

> ⚠️ **`incentive_amount` will be `"0.00"` everywhere on the test server.** Not
> a bug — no pooja in the system has a rate set yet. See §7.

**Bonus:** the `PATCH` now answers with the completion time it just set, so you
no longer need to re-fetch the list to render a timestamp the write already
knew. (It previously echoed pre-write data — see §6.)

---

## 3. New endpoints

All under `/api/poojari/`, all session-authenticated, all about the signed-in
poojari — **no poojari id anywhere**, in path or body.

### `GET /panchangam/` — greeting card

`?date=YYYY-MM-DD`, default today (IST).

```json
{
  "gregorian_date": "2026-08-30", "weekday": "Sunday", "weekday_ml": "ഞായർ",
  "kollavarsham_year": 1202, "masa_name": "ചിങ്ങം", "masa_day": 15,
  "nakshatra": null,
  "formatted_ml": "1202 ചിങ്ങം 15, ഞായർ"
}
```

**Render `formatted_ml` directly.** Two caveats:

* **`nakshatra` is always `null`** today. It comes from the temple's own
  calendar table, which does not carry nakshatram. The field is in the contract
  and nullable — render without it.
* **`503` past 2029.** The calendar is seeded 2025-01-01 → 2029-12-31. Outside
  that, and for a malformed row, you get `503` — the request was fine, the
  calendar cannot answer. `400` is only a malformed `date` param.

### `GET /upcoming-pooja-counts/` — home day tiles

`?days=` default **3**, max **14**. `?category_id=` optional.

```json
{ "days": [
  { "date": "2026-08-31", "label": "Tomorrow",          "count": 18 },
  { "date": "2026-09-01", "label": "Day after tomorrow", "count": 12 },
  { "date": "2026-09-02", "label": "Wednesday",          "count":  7 }
] }
```

**The window starts tomorrow, not today** — today's work is the list below the
tiles. Counts **bookings, not orders** (a family's four poojas on one order are
four tiles' worth of work), confirmed + COD, mine-or-unassigned. Every day is
returned including zeroes, so tile *n* is always day *n*.

### `GET /monthly-stats/` — profile KPI tiles

`?year=` `?month=` default to the current IST month.

```json
{ "month": "2026-08", "total_poojas": 1148, "special_poojas": 36,
  "incentive_earned": "2400.00" }
```

Personal (not temple-wide), **completed bookings only**, month read against each
booking's own date. `incentive_earned` sums the snapshotted rates.

**Attendance is deliberately not here** — the profile's attendance tile reads
`GET /attendance/report/?period=monthly`, `summary.present` of `summary.days`.

### `GET`/`PUT /gods/` — assigned deities

`GET` → `{ "count": 1, "gods": [ { "id", "god": {…}, "assigned_by_name", "assigned_at" } ] }`
`PUT` `{ "god_ids": [3, 11] }` replaces the whole list.

`assigned_by_name` is `null` when the poojari chose it themselves.

### `GET`/`POST /attendance/` and `GET /attendance/report/`

`POST { "status": "present" }` — every field optional. `date` defaults to the
temple's today, at most 31 days back, future dates refused.
**Marking a day twice replaces it** — `201` on the first mark, `200` on a
correction, `created` says which.

`GET /attendance/?period=weekly` gives the raw rows for the week strip.
`GET /attendance/report/?period=weekly|monthly` gives the figures.

> **`attendance_percentage` is present days over *every* day in the span**, not
> over the marked ones. Five present out of thirty-one is 16.1%, not 100%.
> `marked_days` and `not_marked` are there if you want the other ratio — label
> it honestly if you use it.

---

## 4. `employee_id` on the profile

`GET /api/poojari/profile/` now includes it, and the `PoojariProfile` component
in `/api/schema/` declares it — the check you used to find it missing.

`string or null`. **Render the badge conditionally**: a poojari can sign in
having never been registered by the back office, and gets `null`.

---

## 5. Regenerate your client — four component renames

**No endpoint, field or behaviour changed.** These are OpenAPI component names
only. But a client generated from the old schema references names that no longer
exist.

| Was | Now |
|---|---|
| `PoojaCategory` (poojari's) | `PoojariPoojaCategory` |
| `PoojaOrderDetail` (poojari's) | `PoojariPoojaOrderDetail` |
| `PoojaOrderLineDetail` | `PoojariPoojaOrderLineDetail` |
| `UserAttribute` (booking's) | `BookingUserAttribute` |

Each name was shared by two differently-shaped serializers, so the generated
schema silently described one of them wrongly — `booking`'s `PoojaCategory`
carries `parent`, `children` and `poojas_count`, which poojari endpoints never
send. If you generated models from the schema, some of them were wrong.

**`BookingUserAttribute` is not a poojari endpoint** — it affects the devotee
app. Please pass that on.

Also worth knowing: `pooja-management/` was **absent from `/api/schema/`
entirely** until now, which is why you could not verify §2's fields there. It
and all 12 poojari operations are now typed.

---

## 6. Two bugs fixed that you may have worked around

* **`PATCH /api/poojari/profile/{id}/` returned `500`, always.** A backend
  error, on `main` too — every profile update has been failing. If you have a
  workaround or a disabled edit screen, you can undo it.
* **The `pooja-management` `PATCH` echoed pre-write data.** A booking you had
  just marked done came back reading `pending`. If you re-fetch the list after a
  `PATCH` to work around this, you no longer need to.

---

## 7. What will still look broken on the test server

Two things that are *data*, not code — worth knowing before you report them
again:

1. **Every incentive is `"0.00"`.** No pooja has a rate set. There is now a
   command for it (`manage.py set_pooja_incentives`), but the figures are the
   temple's to decide and nothing has been seeded. The coin will not render
   until then. Note also that existing bookings keep the rate they were taken
   at, so setting rates now affects *new* bookings unless we also backfill.
2. **`nakshatra` is `null`.** See §3.

And a deploy note that affects you directly: after `migrate`, the backend must
run `sync_rbac`. Until it does, **every new endpoint here returns `403`** —
which looks exactly like a permissions bug on your side. If you see blanket
`403`s on a fresh deploy, ask us whether the sync ran before debugging your
session handling.

---

## 8. Already yours to wire — no backend work needed

From `POOJARI_APP_API.md`'s own list, confirmed still true:

| Screen element | Endpoint |
|---|---|
| Assigned deities (Profile) | `GET /gods/` |
| Attendance days this month | `GET /attendance/report/?period=monthly` |
| Week attendance dot strip | `GET /attendance/?period=weekly` |
| Check-in card (Home) | `GET`/`POST /attendance/` |
| "Reassigned" pill | booking line `poojari_id` — `null` means *unassigned*, which is not the same as *was reassigned* |
| Completion time on a done row | `completed_at` (§2) |

---

## 9. Open questions for you

Small, and none of them block you:

1. **`is_incentive_pooja`** — we derive it from `incentive_amount > 0`, matching
   how the rest of the system defines "pays an incentive". Confirm you are not
   expecting a flag settable independently of the amount.
2. **`category: null`** — confirm the app tolerates it (§1). This is the one we
   would like an answer on before it reaches your test server.
3. **`403` handling** on `pooja-management` `GET` and `PATCH`.

---

## 10. Checking it yourself

```
GET /api/schema/     # all 10 poojari paths, fully typed
GET /api/swagger/    # the same, interactive — look for the Poojari group
```

Everything in this document is in the schema. If a shape here disagrees with the
schema, the schema is right and we have a doc bug — tell us.
