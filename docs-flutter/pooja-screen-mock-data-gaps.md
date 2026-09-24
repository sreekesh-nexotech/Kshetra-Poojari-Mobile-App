# Pooja list screen — mock data with no backend endpoint

**For the backend team.** This lists everything the Pooja list/booking screen
in the poojari app currently shows using a placeholder value instead of real
server data, and explains why — for each one, the field simply doesn't exist
in the booking/order JSON today.

Scope: `lib/features/pooja/` (the per-god task list — group headers, task
rows, the incentive coin). Checked against `docs-flutter/pooja.md`, the
backend doc for this screen's endpoints
(`GET`/`PATCH /api/poojari/pooja-management/`). The app's own mapper already
flags these gaps in a code comment —
`lib/features/pooja/application/mappers/pooja_vm_mapper.dart:9-17` — this
document is that same list, written up for sharing outside the app team.

---

## 1. No endpoint exists yet — these need new backend work

| # | What's shown on screen | Placeholder behaviour today | Why it can't be wired |
|---|---|---|---|
| 1 | **Remark** under a task row (e.g. "ജോലിക്ക്", "പരീക്ഷയ്ക്ക്" — a short reason for the booking) | Always blank — the subtitle line just doesn't render | Neither the booking (`order_line`) nor the order JSON in `pooja.md` §7 has any free-text remark/reason field. |
| 2 | **Incentive coin** on a task row, and the group header's incentive marker | Always off — the coin never renders, no booking is ever flagged as an incentive job | No `incentive` field exists on a booking or order anywhere in `pooja.md`. There's nothing to read it from. *(Same gap already flagged in the Home-screen doc — this is the same missing field, shown in a second place.)* |

---

## 2. Related, but *not* missing an endpoint — worth knowing, not a backend ask

These also show something the server doesn't literally send, but they're
covered by data that already exists — either computed client-side from a
real field, or a deliberate design choice. Listed so they aren't mistaken for
the two real gaps above.

| What's shown | How it's actually produced today | Note |
|---|---|---|
| **Completion time** on a done row (e.g. "07:40 AM") | Stamped on the device the moment a `PATCH` to mark it "completed" succeeds — not read back from the server | Works fine for a booking marked from this device, but if two devices (or the back office) can mark the same booking, this time is only known to whoever tapped it. Worth asking whether `PATCH /api/poojari/pooja-management/` should return a completion timestamp in its response, so every client shows the same time. |
| **"Reassigned" pill** on a pending row | Approximated as `poojari_id == null` (i.e. "currently unassigned") | This is not really "was this booking taken away from someone" — it's "is nobody currently on it." The field it's built from (`poojari_id`) is real and documented (`pooja.md` §7), so no backend work is needed; it's a labelling/design question, not a missing-endpoint one. |

---

## Summary for backend

Two fields would close the real gaps in this screen:

- **A remark/reason field** on the booking or order line — free text, shown
  as the row's subtitle.
- **An incentive flag** on the booking — closes both this screen's coin *and*
  the same gap already reported for the Home screen
  (`docs-flutter/home-screen-mock-data-gaps.md`, item 4), so one field fixes
  two screens.

Optionally, returning a completion timestamp from the mark-as-completed
`PATCH` response (§2) would make "who marked it and when" consistent across
devices, though the screen works without it today.
