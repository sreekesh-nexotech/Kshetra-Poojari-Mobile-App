import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which device precondition (if any) blocks a premises-gated action.
enum GateBlock { none, locationOff, outsidePremises }

/// ── DEVICE / GEOFENCE SEAM ───────────────────────────────────────────────────
/// Models the two device preconditions the design gates on before attendance
/// or pooja completion: (1) is location ON, (2) is the poojari inside the temple
/// premises. Both default to the happy path (true) so the demo flows work.
///
/// Replace this with real `geolocator` permission/service checks + a geofence
/// distance test on API integration — the UI only ever reads [checkGate].
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

/// Exact Malayalam copy for the device-gate block popups (design strings).
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
}
