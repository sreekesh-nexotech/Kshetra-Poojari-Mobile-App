import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which device precondition (if any) blocks a premises-gated action.
enum GateBlock { none, locationOff, outsidePremises }

/// ── POOJA-TAB GATE (still a stand-in) ───────────────────────────────────────
/// Models the two device preconditions the design gates pooja completion on:
/// (1) is location ON, (2) is the poojari inside the temple premises. Both
/// default to the happy path (true), so completion is effectively ungated.
///
/// **Attendance no longer goes through here.** It runs a real fix against the
/// radius the server hands out — see [LocationService] and
/// `AttendanceController.checkIn`. This stayed a stand-in on purpose: the
/// backend geofences the attendance `POST` and nothing else, so
/// `PATCH /pooja-management/` is accepted wherever it is sent, and turning
/// this into a real GPS prompt would invent a client-only rule the server
/// does not share (docs-flutter/poojari-geofence.md covers attendance only).
class LocationGateState {
  const LocationGateState({this.locationOn = true, this.insidePremises = true});

  final bool locationOn;
  final bool insidePremises;

  LocationGateState copyWith({bool? locationOn, bool? insidePremises}) =>
      LocationGateState(
        locationOn: locationOn ?? this.locationOn,
        insidePremises: insidePremises ?? this.insidePremises,
      );
}

class LocationGateController extends StateNotifier<LocationGateState> {
  LocationGateController() : super(const LocationGateState());

  /// Ordered gate: location first, then premises (design order).
  GateBlock checkGate() {
    if (!state.locationOn) return GateBlock.locationOff;
    if (!state.insidePremises) return GateBlock.outsidePremises;
    return GateBlock.none;
  }

  // Demo hooks (would be driven by real device state in production).
  void setLocationOn(bool value) => state = state.copyWith(locationOn: value);
  void setInsidePremises(bool value) =>
      state = state.copyWith(insidePremises: value);
}

final locationGateProvider =
    StateNotifierProvider<LocationGateController, LocationGateState>(
      (ref) => LocationGateController(),
    );

/// Malayalam copy for every way a premises-gated action can be refused.
///
/// The first three are the design's original strings, kept verbatim. The rest
/// cover the states the real geofence introduced (poojari-geofence.md) and are
/// written to match their voice.
abstract final class GateCopy {
  GateCopy._();

  static const String locationOffTitle = 'ലൊക്കേഷൻ ഓൺ അല്ല';
  static const String locationOffMessage =
      'ഹാജറും പൂജ സ്റ്റാറ്റസും മാർക്ക് ചെയ്യാൻ ഫോണിലെ ലൊക്കേഷൻ ഓൺ ചെയ്യുക.';

  static const String outsideTitle = 'ക്ഷേത്ര പരിസരത്തല്ല';
  static const String outsideMessage =
      'ഹാജറും പൂജ സ്റ്റാറ്റസും മാർക്ക് ചെയ്യാൻ നിങ്ങൾ ക്ഷേത്ര പരിസരത്ത് വേണം. '
      'ജി.പി.എസ് പ്രകാരം ഇപ്പോൾ പുറത്താണ്.';

  static const String notCheckedInTitle = 'ചെക്ക്-ഇൻ ചെയ്തിട്ടില്ല';
  static const String notCheckedInMessage =
      'പൂജ ലിസ്റ്റ് തുറക്കാൻ ആദ്യം ഇന്നത്തെ ചെക്ക്-ഇൻ ചെയ്യുക.';

  // ── Permission ────────────────────────────────────────────────────────────
  /// Denied once. Sliding again re-asks, so the copy says to try again.
  static const String permissionDeniedTitle = 'ലൊക്കേഷൻ അനുമതി വേണം';
  static const String permissionDeniedMessage =
      'ക്ഷേത്ര പരിസരത്താണെന്ന് ഉറപ്പാക്കാനാണ് ലൊക്കേഷൻ ചോദിക്കുന്നത്. '
      'അനുമതി നൽകി വീണ്ടും സ്ലൈഡ് ചെയ്യുക.';

  /// Denied permanently — re-asking is a no-op from here, only settings help.
  static const String permissionBlockedTitle =
      'ലൊക്കേഷൻ അനുമതി തടഞ്ഞിരിക്കുന്നു';
  static const String permissionBlockedMessage =
      'ഈ ആപ്പിന് ലൊക്കേഷൻ അനുമതി നിഷേധിച്ചിരിക്കുന്നു. ഫോൺ സെറ്റിങ്സിൽ പോയി '
      'അനുമതി നൽകിയാൽ മാത്രമേ ഹാജർ മാർക്ക് ചെയ്യാൻ കഴിയൂ.';

  // ── The fix itself ────────────────────────────────────────────────────────
  static const String fixUnavailableTitle = 'ലൊക്കേഷൻ കിട്ടിയില്ല';
  static const String fixUnavailableMessage =
      'ജി.പി.എസ് സിഗ്നൽ കിട്ടുന്നില്ല. തുറസ്സായ സ്ഥലത്തേക്ക് മാറി നിന്ന് '
      'വീണ്ടും ശ്രമിക്കുക.';

  // ── Server-side configuration ─────────────────────────────────────────────
  /// `{"location": null}` on the read, or a `409` on the mark. Not the
  /// poojari's fault and not their GPS — say so plainly.
  static const String noTempleLocationTitle =
      'ക്ഷേത്ര ലൊക്കേഷൻ സെറ്റ് ചെയ്തിട്ടില്ല';
  static const String noTempleLocationMessage =
      'ഹാജർ പരിശോധിക്കാൻ ക്ഷേത്രത്തിന്റെ ലൊക്കേഷൻ ഇതുവരെ സെറ്റ് ചെയ്തിട്ടില്ല. '
      'ക്ഷേത്ര ഓഫീസുമായി ബന്ധപ്പെടുക.';

  // ── Outside the radius ────────────────────────────────────────────────────
  /// "You are 850 m away — get within 200 m." Telling them the number beats
  /// telling them no: it is the difference between a rule and an instruction.
  static String outsideMessageFor({
    required int distanceMeters,
    required int radiusMeters,
  }) =>
      'നിങ്ങൾ ക്ഷേത്രത്തിൽ നിന്ന് ${distanceLabel(distanceMeters)} അകലെയാണ്. '
      'ഹാജർ മാർക്ക് ചെയ്യാൻ ${distanceLabel(radiusMeters)} പരിധിക്കുള്ളിൽ എത്തുക.';

  /// Metres up to a kilometre, then one decimal of a kilometre — 178773 m
  /// reads as `178.8 കി.മീ`, not as a number nobody can parse at a glance.
  /// Latin digits throughout, as everywhere else in the app.
  static String distanceLabel(int metres) => metres < 1000
      ? '$metres മീറ്റർ'
      : '${(metres / 1000).toStringAsFixed(1)} കി.മീ';
}
