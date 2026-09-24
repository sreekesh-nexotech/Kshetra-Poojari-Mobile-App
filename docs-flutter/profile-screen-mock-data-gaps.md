# Profile ("Account") screen — mock data with no backend endpoint

**For the backend team.** This lists everything the Profile/Account screen in
the poojari app currently shows using placeholder (mock) values, and explains
why — for each one, either there is no endpoint at all yet, or the endpoint
that exists doesn't return the exact figure the screen needs.

Scope: `lib/features/profile/` (the "Account" tab — profile card, this-month
KPI tiles, week attendance strip). Checked against the two backend API docs in
this repo: `docs-flutter/pooja.md` and `docs-flutter/poojari-app.md`.

---

## 1. No endpoint exists yet — these need new backend work

| # | What's shown on screen | Placeholder value today | Why it can't be wired |
|---|---|---|---|
| 1 | **Poojari ID** (shown next to the phone number, e.g. "9142 2245 22 · ID 02548") | `02548` | The profile endpoint (`GET /api/poojari/profile/`) does not return a poojari ID field — only `id, username, email, first_name, last_name, phone_number, role`. Nothing else in either doc exposes one either. *(Close relative: the attendance-report endpoints return an `employee_id` field — see §2 below — but that's a different endpoint than the one profile data comes from.)* |
| 2 | **Incentive earned this month** (KPI tile "ഇൻസെന്റീവ് · ഇതുവരെ", e.g. "₹2,400") | `₹2,400` | No incentive/money field anywhere in either doc — not on the profile, the attendance report, or the pooja stats endpoint. There is currently no source at all for this number. |
| 3 | **Total poojas this month** (KPI tile "ആകെ പൂജകൾ", e.g. "1,148") | `1,148` | The closest existing endpoint, `GET /api/poojari/pooja-stats/`, returns pooja totals — but it's **all-time and all-poojaris**, not "this poojari, this month" (documented as a known gotcha in `pooja.md` §11.9). There's no endpoint today that gives one poojari's monthly pooja count. |
| 4 | **Special poojas this month** (KPI tile "സ്പെഷ്യൽ പൂജകൾ", e.g. "36") | `36` | Same issue as #3 — `pooja-stats` does return a `special_pooja` count, but again all-time/all-poojaris, not scoped to this poojari's current month. |

---

## 2. Related, but *not* missing an endpoint — just not wired up yet

These look similar to the gaps above but the backend already has a working
endpoint for them. Listed here so it's clear these are an app-side wiring
task, not something the backend needs to build.

| What's shown | Endpoint that already covers it | Note |
|---|---|---|
| Name & phone number | `GET /api/poojari/profile/` | Already wired — pulled from the signed-in session. |
| Assigned deities ("അസൈൻ ചെയ്ത ദേവതകൾ") | `GET /api/poojari/gods/` (`poojari-app.md` §2) | Real endpoint, just not called yet from this screen — still shows the placeholder list. |
| Attendance days this month ("ഹാജർ ദിനങ്ങൾ", e.g. "24/26") | `GET /api/poojari/attendance/report/?period=monthly` (`poojari-app.md` §6) | Returns exactly this: `summary.present` out of `summary.days`. Just needs the app to call it. |
| Week attendance dot strip | `GET /api/poojari/attendance/?period=weekly` or the report endpoint above | Real endpoint exists; the strip is still hardcoded. |
| Poojari ID (alternate source) | `employee_id` field inside the attendance-report response (`poojari-app.md` §6–7) | Not part of the profile endpoint (see §1.1 above), but if the app called the attendance report anyway for the KPI tile, this field could double as the ID — worth a conversation about whether it should just be added to `GET /api/poojari/profile/` instead, since that's the more natural place for it. |

---

## Summary for backend

If you want to close every gap above, the useful new endpoint(s) would be:

- **A per-poojari, this-month pooja summary** (total poojas + special poojas
  count, scoped to the caller and to a date range/month) — closes #3 and #4.
- **An incentive figure** — there is currently no concept of incentive amount
  anywhere in the API, so this needs a source of truth decided first (is it
  computed from completed bookings? a separate ledger?) before an endpoint
  makes sense — closes #2.
- **A poojari ID field**, most simply added to `GET /api/poojari/profile/`
  alongside `employee_id` (which already exists elsewhere) — closes #1.

Everything in §2 needs no backend changes — that's on the app team to wire up.
