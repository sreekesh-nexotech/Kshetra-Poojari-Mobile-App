# Poojari App — Gap Fix API Reference

> **For:** Frontend developer wiring `features/` in the poojari app  
> **Covers:** All gaps resolved across the three gap documents:  
> &nbsp;&nbsp;• `home-screen-mock-data-gaps.md`  
> &nbsp;&nbsp;• `pooja-screen-mock-data-gaps.md`  
> &nbsp;&nbsp;• `profile-screen-mock-data-gaps.md`  
> **Auth:** Session cookie — all endpoints require the signed-in poojari's session  
> **Base URL:** `/api/poojari/`  
> **Prepared:** 30 Aug 2026

---

## Summary of All Changes

| Gap | Screen | What changed |
|---|---|---|
| Malayalam calendar date | Home — greeting card | ✅ New endpoint `GET /api/poojari/panchangam/` |
| Upcoming day pooja counts | Home — day tiles | ✅ New endpoint `GET /api/poojari/upcoming-pooja-counts/` |
| Incentive coin + amount | Home & Pooja list | ✅ New fields `is_incentive_pooja`, `incentive_amount` on booking lines |
| Booking remark text | Pooja list — task row | ✅ New field `remarks` on every booking line |
| Completion timestamp | Pooja list — done row | ✅ New field `completed_at` on booking lines (GET + PATCH) |
| Poojari employee ID | Profile — ID badge | ✅ New field `employee_id` in `GET /api/poojari/profile/` |
| Incentive earned this month | Profile — KPI tile | ✅ New endpoint `GET /api/poojari/monthly-stats/` |
| Total poojas this month | Profile — KPI tile | ✅ Same endpoint |
| Special poojas this month | Profile — KPI tile | ✅ Same endpoint |

---

## 1. Malayalam Calendar Date

**Gap closed:** Home screen greeting card showing a frozen Malayalam date.

```
GET /api/poojari/panchangam/
```

### Query Parameters

| Param | Format | Default |
|---|---|---|
| `date` | `YYYY-MM-DD` | Today (Asia/Kolkata) |

### Response `200 OK`

```json
{
  "gregorian_date": "2026-08-30",
  "weekday": "Sunday",
  "weekday_ml": "ഞായറ്",
  "kollavarsham_year": 1202,
  "masa_name": "ചിങ്ങം",
  "masa_day": 15,
  "nakshatra": "അത്തം",
  "formatted_ml": "1202 ചിങ്ങം 15, ഞായറ്"
}
```

### Field Notes

| Field | Type | Usage |
|---|---|---|
| `formatted_ml` | `string` | **Use this directly** on the greeting card. Pre-formatted, ready to render. |
| `weekday_ml` | `string` | Malayalam weekday name (ഞായറ്, തിങ്കള്, ചൊവ്വ, ബുധന്, വ്യാഴം, വെള്ളി, ശനി) |
| `kollavarsham_year` | `integer` | Kollam era year |
| `masa_name` | `string` | Malayalam month name |
| `masa_day` | `integer` | Day within the Malayalam month (1–30) |
| `nakshatra` | `string or null` | Malayalam nakshatra name, or `null` if unavailable |
| `gregorian_date` | `string` | The Gregorian date in ISO-8601 format |
| `weekday` | `string` | English weekday name |

### Error Responses

| Code | Reason |
|---|---|
| `400` | `date` param is not in `YYYY-MM-DD` format |
| `503` | Malayalam calendar library is not installed on the server |
| `401` | Not authenticated |

---

## 2. Upcoming Day Pooja Counts

**Gap closed:** Home screen "Tomorrow / Day after / [weekday]" tiles showing hardcoded numbers (42, 29, 55).

```
GET /api/poojari/upcoming-pooja-counts/
```

### Query Parameters

| Param | Default | Max | Description |
|---|---|---|---|
| `days` | `3` | `14` | How many upcoming days to return |
| `category_id` | (all gods) | — | Filter counts to one deity's poojas |

### Response `200 OK`

```json
{
  "days": [
    { "date": "2026-08-31", "label": "Tomorrow",             "count": 18 },
    { "date": "2026-09-01", "label": "Day after tomorrow",   "count": 12 },
    { "date": "2026-09-02", "label": "Wednesday",            "count":  7 }
  ]
}
```

### Field Notes

- `label` values: `"Tomorrow"`, `"Day after tomorrow"`, then the English weekday name (`"Monday"`, `"Tuesday"`, …) for day 3+.
- `count` includes **confirmed + COD** bookings that are either assigned to the signed-in poojari or unassigned ("mine or unassigned"), same visibility rule as the Pooja management screen.
- `date` is in `YYYY-MM-DD` format (Asia/Kolkata).

### Error Responses

| Code | Reason |
|---|---|
| `400` | `days` is not an integer, or outside the 1–14 range |
| `401` | Not authenticated |

---

## 3. Pooja Booking Lines — New Fields

**Gaps closed:**  
- `remarks` — reason text under a task row  
- `is_incentive_pooja` + `incentive_amount` — coin icon and progress total  
- `completed_at` — server-authoritative completion time

These fields are now returned on **every booking line** in:
- `GET /api/poojari/pooja-management/` (list)
- `PATCH /api/poojari/pooja-management/` (mark-as-done response)

### New fields on each booking line object

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

### Field Details

#### `remarks`
- Type: `string`
- Never `null`. Empty string `""` when the devotee left no reason.
- Example values: `"ജോലിക്ക്"`, `"പരീക്ഷയ്ക്ക്"`, `""`

#### `is_incentive_pooja`
- Type: `boolean`
- `true` when `incentive_amount` > `0.00`.
- Use this for the **coin icon** on the task row and the group-header incentive marker.

#### `incentive_amount`
- Type: `string` (decimal, 2 d.p.)
- The per-booking poojari incentive, snapshotted at booking time (does not change if the rate is later edited in the admin).
- Use this for the **progress-card total** on the Home screen.
- Example: `"150.00"`, `"0.00"`

#### `completed_at`
- Type: `string` (ISO-8601 with timezone) or `null`
- Server-stamped when the booking is marked `completed`.
- **Use this instead of a device-local timestamp** so every client (and the back office) shows the same completion time.
- Format: `"2026-08-30T07:40:00+05:30"` (IST)
- `null` when `pooja_status` is not yet `completed`.

---

## 4. Poojari Profile — Employee ID

**Gap closed:** Profile screen ID badge next to phone number (e.g. "ID 02548") showing placeholder.

The existing `GET /api/poojari/profile/` endpoint already returns all profile fields. **`employee_id` is now included in the response.**

```
GET /api/poojari/profile/
```

### Response `200 OK`

```json
{
  "id": 7,
  "username": "poojari_krishna",
  "email": "krishna@temple.in",
  "first_name": "Krishna",
  "last_name": "Nair",
  "phone_number": "+919142224522",
  "role": "poojari",
  "employee_id": "02548"
}
```

### Field Notes

| Field | Type | Notes |
|---|---|---|
| `employee_id` | `string or null` | `null` if the admin has not yet assigned an employee ID to this poojari. Render the badge conditionally. |

---

## 5. Monthly Stats — Profile KPI Tiles

**Gaps closed:**  
- "ഇൻസെന്റീവ് · ഇതുവരെ" (Incentive earned this month)  
- "ആകെ പൂജകൾ" (Total poojas this month)  
- "സ്പെഷ്യൽ പൂജകൾ" (Special poojas this month)

```
GET /api/poojari/monthly-stats/
```

### Query Parameters

| Param | Default | Description |
|---|---|---|
| `year` | Current Asia/Kolkata year | 4-digit year |
| `month` | Current Asia/Kolkata month | 1–12 |

### Response `200 OK`

```json
{
  "month": "2026-08",
  "total_poojas": 1148,
  "special_poojas": 36,
  "incentive_earned": "2400.00"
}
```

### Field Details

| Field | Type | KPI tile | Description |
|---|---|---|---|
| `month` | `string` | — | Calendar month covered, `YYYY-MM` |
| `total_poojas` | `integer` | "ആകെ പൂജകൾ" | All completed bookings this month |
| `special_poojas` | `integer` | "സ്പെഷ്യൽ പൂജകൾ" | Completed special-pooja bookings this month |
| `incentive_earned` | `string` (decimal) | "ഇൻസെന്റീവ് · ഇതുവരെ" | Sum of incentives for all completed bookings (INR) |

### Counting Rules

- **Scoped to the signed-in poojari only** — figures are personal, not temple-wide.
- Only **`completed`** bookings are counted. Pending work is not yet performed; cancelled/refunded bookings are not income.
- Month boundary is **Asia/Kolkata calendar days**, matching `selected_date` for regular poojas and `special_pooja_date` for special poojas.

### Error Responses

| Code | Reason |
|---|---|
| `400` | `year` or `month` is not an integer, or `month` is outside 1–12 |
| `401` | Not authenticated |

---

## Items That Need App-Side Wiring Only (No Backend Work)

These look similar to the gaps above but are **already covered by existing endpoints**. The backend is ready; these just need to be called from the correct screen.

| What's shown | Endpoint | What to read |
|---|---|---|
| Name & phone number | `GET /api/poojari/profile/` | Already wired — from the signed-in session |
| Assigned deities (Profile screen) | `GET /api/poojari/gods/` | Still shows placeholder list — needs a call from Profile |
| Attendance days this month (present/total) | `GET /api/poojari/attendance/report/?period=monthly` | `summary.present` out of `summary.days` |
| Week attendance dot strip | `GET /api/poojari/attendance/?period=weekly` | Real data — strip is still hardcoded |
| Check-in / check-out (Home attendance card) | `GET /api/poojari/attendance/` | Not calling it yet |
| "Reassigned" pill on a pending row | Booking line field `poojari_id` | `poojari_id == null` means unassigned (note: not the same as "was reassigned") |
| Completion time on a done row | `completed_at` (see §3 above) | Already on every booking line — use this instead of device clock |

---

## Authentication

All endpoints use **session-based authentication**. Include the session cookie obtained after login.

| Status | Meaning |
|---|---|
| `401 Unauthorized` | No valid session — redirect to login |
| `403 Forbidden` | Authenticated but missing the required RBAC permission |

---

## Swagger

Full interactive schema available at:

```
GET /api/swagger/
```

Look for the **Poojari** group. All endpoints in this document appear there with their full schema.

---

*Backend team · Temple App · 30 Aug 2026*
