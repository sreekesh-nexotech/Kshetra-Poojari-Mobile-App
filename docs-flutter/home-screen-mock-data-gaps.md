# Home screen data gaps

**From:** Mobile team **To:** Backend team
**Screen:** Home — poojari app
**Docs checked:** `pooja.md`, `poojari-app.md`
**Open items:** 3, need your input

Three things on the poojari app's Home screen are still placeholder content,
because we couldn't find a matching field or endpoint in the API docs.
Flagging them now, before we build further on top of guesses.

---

## Needs your input

### 1. Malayalam calendar date

**On the screen.** The greeting card at the top of Home shows two dates side
by side — a Malayalam-calendar date (e.g. *"1180 കർക്കിടകം 22, ശനി"*) and the
Gregorian date next to it. The Malayalam one is frozen text on our end right
now, not computed from anything.

**What we checked.** Neither doc mentions a panchangam or Malayalam-calendar
conversion anywhere.

**What we need to know.** Is there already an endpoint for this that we've
missed? If not — should one be added, or is converting a Gregorian date to
the Kollam-era calendar something we should just do on our side?

*The Gregorian date next to it isn't a backend question — that's just
today's date, and we'll compute it locally. Mentioning it only because it's
currently frozen too.*

### 2. Upcoming days' pooja counts

**On the screen.** Below the day's task list, three tiles show a pooja count
for "Tomorrow", "Day after", and one more named day further out. Right now
those are fixed demo numbers — 42, 29, 55 — not real counts.

**What we checked.** `pooja.md` §7, gotcha #8: *"Never send a date; there is
no date parameter."* The bookings list is explicitly today-only, in
Asia/Kolkata.

**What we need to know.** Is there a way to get a per-day booking count for
the next few days some other way, or would this need a new endpoint?

### 3. Incentive flag on a pooja

**On the screen.** A small coin icon appears next to poojas that carry an
incentive, and the progress card totals them separately — e.g. "1/5
incentive poojas done." Right now this is hardcoded off: no pooja is ever
shown as an incentive pooja.

**What we checked.** The booking and order response shapes in `pooja.md` §7
— every field, cross-checked line by line — have nothing that reads as an
incentive marker.

**What we need to know.** Does an "incentive pooja" concept exist on the
backend at all? If it does, what field should we be reading it from?

---

## For context, not a gap

*No action needed from you.* These looked like the same kind of thing at
first glance, but the docs already cover them — we just haven't finished
wiring our side yet. Listed here only so they don't get raised again by
mistake.

| | |
|---|---|
| **Check-in / check-out** | Already documented (`/api/poojari/attendance/`) — our attendance card just isn't calling it yet. |
| **Today's progress %, per-god cards** | Real data once loaded (`/api/poojari/pooja-management/`) — Home just doesn't trigger the fetch yet, so it can read empty until the pooja tab has been opened once. |
| **"Reassigned" pill** | Not missing — we're reading it off `poojari_id == null`. Only a labeling nuance: that means "unassigned," which isn't quite the same claim as "reassigned." |

---

**One more thing, for our own roadmap rather than a question:**
`poojari-app.md` documents `GET /api/poojari/gods/` (a poojari's own shrine
list) and `GET /api/poojari/pooja-stats/` (all-time, all-poojari figures) —
both real, neither used by Home yet. That's a design call on our end, not
something we need from you. Flagging it here so it isn't lost.

— Mobile team · Prepared 28 Aug 2026
