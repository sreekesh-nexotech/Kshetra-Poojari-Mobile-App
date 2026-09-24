# Endpoint verification — `POOJARI_APP_API.md` against the test server

**From:** Mobile team **To:** Backend team
**Screens:** Home, Pooja, Profile — poojari app
**Server tested:** `http://62.171.151.149:8030`
**Method:** Logged in fresh (`POST /api/auth/poojari-signin/`) and called every
endpoint the app now wires, with the resulting session — same paths, same
query params the app itself sends. Cross-checked against the server's own
`GET /api/schema/`.
**Open items:** 3, need your input

The app-side wiring for all three gap docs (`home-screen-mock-data-gaps.md`,
`pooja-screen-mock-data-gaps.md`, `profile-screen-mock-data-gaps.md`) is done,
built against `POOJARI_APP_API.md`. Testing it against this server surfaced
three things that need backend action before any of it is visible end to end.

---

## 1. Seven documented routes aren't registered on this server

Not flaky 404s — confirmed from the server's own OpenAPI schema
(`GET /api/schema/`), which lists **exactly four** routes under
`/api/poojari/`:

```
/api/poojari/pooja-management/
/api/poojari/pooja-stats/
/api/poojari/profile/
/api/poojari/profile/{id}/
```

Every other endpoint `POOJARI_APP_API.md` and `poojari-app.md` describe is
simply absent from this build's URL config:

| Endpoint | Screen | Result |
|---|---|---|
| `GET /api/poojari/panchangam/` | Home | `404` |
| `GET /api/poojari/upcoming-pooja-counts/` | Home | `404` |
| `POST`/`GET /api/poojari/attendance/` | Home (check-in), Profile (week strip) | `404` |
| `GET /api/poojari/attendance/report/` | Profile | `404` |
| `GET /api/poojari/gods/` | Profile | `404` |
| `GET /api/poojari/monthly-stats/` | Profile | `404` |

**What we need to know:** are these deployed anywhere yet (staging, another
box), or still pending a deploy to this server? `attendance` is the odd one
out — `poojari-app.md` §5 documents it as an *existing*, already-shipped
feature, predating `POOJARI_APP_API.md` entirely — so this server looks like
it's running a build from before that feature shipped, not something newly
broken.

*Not a concern on the app side* — every one of these calls fails closed: the
greeting card shows no Malayalam date, the upcoming-days row renders no
tiles, check-in still flips locally even though the `POST` 404s, and the
profile screen's assigned-deities line, week strip and KPI tiles just stay
blank. Once the routes exist, this should start working with no client
change.

---

## 2. `employee_id` is missing from the `PoojariProfile` schema, not just this response

`GET /api/poojari/profile/` returns `200`:

```json
{"id":74,"username":"Neeraja","email":"neeraja@gmail.com","first_name":"","last_name":"","phone_number":"+918086343747","role":"temple_poojari"}
```

We checked whether this was just an unset value for this particular poojari,
but the server's own schema settles it — the `PoojariProfile` component in
`GET /api/schema/` defines only:

```
id, username, email, first_name, last_name, phone_number, role
```

`employee_id` isn't in the schema at all for this endpoint. (It does exist
elsewhere in the schema, on what looks like an admin/registration-side
serializer — a different endpoint than the one profile data comes from.)

**What we need to know:** can `employee_id` be added to the `PoojariProfile`
serializer, per `POOJARI_APP_API.md` §4?

---

## 3. No live bookings on this server to verify the new booking-line fields

`POOJARI_APP_API.md` §3 documents `remarks`, `is_incentive_pooja`,
`incentive_amount`, and `completed_at` as new fields on every booking line
returned by `GET`/`PATCH /api/poojari/pooja-management/`. The app now parses
all four, but we can't confirm they're actually shaped the way the doc
describes, because there's nothing to check them against — every category id
we tried (1 through 16) came back the same way:

```json
{"category": {...}, "count": 0, "orders": []}
```

**What we need to know:** could a booking be seeded on this server (any
category, any status) so we can confirm the four fields round-trip correctly?
Today the app degrades gracefully when they're absent — the coin, remark and
completion time just don't render — so this isn't blocking, but it also means
this part of the work is unverified rather than verified-working.

---

## Summary for backend

- **Deploy (or point us at an environment with)** `panchangam`,
  `upcoming-pooja-counts`, `attendance` (+`report`), `gods`, and
  `monthly-stats` — all confirmed absent from this server's URL config via
  its own schema.
- **Add `employee_id`** to the `PoojariProfile` schema/serializer.
- **Seed one live booking** on this server so the four new booking-line
  fields can actually be checked end to end.

— Mobile team · Prepared 30 Aug 2026
