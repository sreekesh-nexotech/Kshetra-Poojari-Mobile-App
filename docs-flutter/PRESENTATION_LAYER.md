# Presentation Layer — Kshetra Poojari

This document describes the **presentation layer** built from the Claude Design
export (`Poojary App.dc.html`). Scope of this work: **UI + the Riverpod state and
mock-data seam that drives it** — no real Domain/Infrastructure (Dio/Hive/API)
yet. Everything is a pixel-match to the design and analyze-clean.

## Stack (what this layer adds)

- `flutter_riverpod` — state
- `flutter_screenutil` — responsive sizing against the **375 × 812** design
  baseline (all sizes use `.w/.h/.sp/.r`; `ScreenUtilInit` in `app/app.dart`)
- `go_router` — `StatefulShellRoute` for the home/pooja/account tabs + the auth stack
- `flutter_svg` — the navbar glyphs (extracted from `NavbarVariant9/10/11`)
- `cached_network_image`, `intl` — for the API-integration phase

Fonts are bundled locally for an exact, offline match: **Noto Sans Malayalam**
(rendered condensed via `FontVariation(wdth, 75)`), **Noto Serif Malayalam**,
**Roboto**, **Plus Jakarta Sans**, and **Noto Sans Symbols 2** (fallback for the
✓ / ✕ text glyphs the primary faces lack).

## Screens

| Screen | Route | Class |
|---|---|---|
| Home (today's overview) | `/home` | `HomeScreen` |
| Pooja task list | `/pooja` | `PoojaListScreen` |
| Account (month / till-now) | `/account` | `AccountScreen` |
| Login | `/login` | `LoginScreen` |
| OTP request | `/otp` | `OtpRequestScreen` |
| OTP verify | `/otp-verify` | `OtpVerifyScreen` |
| Set password | `/set-password` | `SetPasswordScreen` |
| Password changed | `/password-done` | `PasswordDoneScreen` |

Gating (design behaviour): the pooja tab is blocked until check-in; attendance
and pooja **completion** are blocked unless location is on **and** inside the
temple premises (`core/device/location_gate.dart`, defaults to the happy path).
Cancel / undo / logout work anywhere.

## Reusable widgets (`lib/core/widgets/`)

`AppCard`, `AppButton`, `AppTextField`, `KsBottomNav`, `KsProgressBar`,
`KsIncentiveCoin`, `KsPill(.reassigned/.special)`, `KsCountPill`, `KsChevron`,
`KsSectionLabel`, `KsTempleBackground`, `KsToastHost` (+ `toastProvider`), and
`showKsBlockDialog`. Design tokens live in `lib/app/theme/`
(`AppColors`, `AppText`, `AppRadii`, `AppShadows`, `AppDimens`).

## The mock-data seam (how to plug in the API)

All static data is isolated behind clearly-marked mock sources so swapping to a
repository is a one-line change per feature — no UI or controller edits:

- `features/pooja/application/mock/pooja_mock_data.dart` → exposed via
  `godsProvider` and `poojaSeedProvider`. Point these at a `PoojaRepository`.
- `features/dashboard/application/mock/home_mock_data.dart` → header/date/upcoming.
- `features/profile/application/mock/profile_mock_data.dart` → profile + KPIs + week.
- `features/auth/application/mock/auth_mock_data.dart` → demo phone / OTP checks.
- `core/device/location_gate.dart` → replace with `geolocator` + a geofence test.

The controllers (`poojaTasksControllerProvider`, `poojaListControllerProvider`,
`attendanceControllerProvider`, `authControllerProvider`, …) and all derived
selectors (home progress/tally, pooja grouping/filters, week strip) consume only
these seams and the immutable view-models in each feature's `application/models/`.

## Tests

- `test/widget_test.dart` — boot smoke test.
- `test/golden/screens_golden_test.dart` — golden PNGs of every screen at
  375 × 812 (real fonts loaded via `test/flutter_test_config.dart`), used for the
  pixel-comparison audit. Regenerate with `flutter test --update-goldens`.
- `test/state/pooja_state_test.dart` — end-to-end state: seed integrity,
  bulk complete/cancel, undo, tally flip, deity switch.

Run: `flutter analyze` (clean) · `flutter test` (all green).

> Note on goldens: the temple-background photo and deity thumbnails can appear
> blank in some golden frames because asset images decode asynchronously in the
> test harness — they render normally in the running app.
