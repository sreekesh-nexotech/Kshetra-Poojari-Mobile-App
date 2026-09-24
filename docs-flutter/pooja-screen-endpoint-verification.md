# Pooja screen — endpoint verification

**From:** Mobile team **To:** Backend team
**Screen:** Pooja — poojari app (per-god task list)
**Server tested:** `http://62.171.151.149:8030`
**Method:** Logged in fresh (`POST /api/auth/poojari-signin/`) and called
every endpoint the pooja screen wires — the god picker, the booking list for
every shrine, the omitted-`category_id` edge case, and the mark-as-done
`PATCH` with both a bad order id and a bad status — with the resulting
session, same paths/params the app sends.
**Open items:** 1, needs your input. Everything else below is good news.

---

## What's confirmed working

| Check | Result |
|---|---|
| `GET /api/booking/poojacategory/?is_active=true` (god picker) | ✅ `200` — 17 gods, all active |
| `GET /api/poojari/pooja-management/?category_id=N` — every category (1–16, and 53) | ✅ `200` on all 17 |
| `GET /api/poojari/pooja-management/` with **no** `category_id` | ✅ `400 {"error":"category_id is required"}` — matches `poojari-app.md` §3 exactly for an unscoped poojari |
| `PATCH /api/poojari/pooja-management/` with a non-existent order id | ✅ `404 {"error":"Pooja order not found"}` — sensible, endpoint is live and validates |
| `PATCH /api/poojari/pooja-management/` with an invalid `pooja_status` | ✅ `400 {"error":"Invalid input","details":{"pooja_status":["\"bogus\" is not a valid choice."]}}` — matches the doc exactly |

The pooja-management endpoint — read, write, and the shrine-scoping edge case
— is fully live and behaves exactly as `poojari-app.md` documents. Nothing
needed here.

---

## One open item: no live bookings anywhere to check against

Every one of the 17 categories above returned `count: 0, "orders": []`.
There is currently no booking on this server, in any state, for any god.

That matters for one specific thing: `POOJARI_APP_API.md` §3 documents four
new fields on every booking line — `remarks`, `is_incentive_pooja`,
`incentive_amount`, `completed_at`. The app now parses all four, but there is
nothing to actually check them against. We can't tell whether they're present
and shaped the way the doc describes, because there's no row to look at.

**What we need:** could a booking be seeded on this server (any god, any
status — pending is enough to confirm `remarks`/`is_incentive_pooja`, a
completed one would additionally confirm `completed_at`)? Today the app
degrades cleanly when these are absent — no remark subtitle, no coin, no
completion time — so nothing is broken on our side. It's just unverified
rather than confirmed-working.

---

## Aside, not a bug: a brief full outage mid-test

Partway through this pass, the whole server stopped responding —
`502 Bad Gateway` on *every* call, including the completely unauthenticated
`GET /api/auth/csrf/`. That's nginx answering with no upstream behind it, not
anything endpoint-specific. It recovered on its own a short while later, and
a full re-run afterwards (including the specific category id we were
checking right before it happened) came back clean. Flagging only in case it
lines up with something in your logs — a restart, a deploy, an OOM — not
something we need fixed on our end.

---

— Mobile team · Prepared 31 Aug 2026
