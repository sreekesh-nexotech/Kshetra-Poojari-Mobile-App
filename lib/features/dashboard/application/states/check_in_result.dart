import '../../../../core/device/location_gate.dart';
import '../../../../core/error/failure.dart';

/// Why a check-in did not happen — or [CheckInBlock.none] if it did.
///
/// One flat list rather than "device errors" and "server errors", because the
/// poojari does not care which side said no; they care what to do next. Two of
/// these ([outsidePremises], [noTempleLocation]) can arrive from either side.
enum CheckInBlock {
  /// Marked. The only value for which the card flips.
  none,

  /// The device's location switch is off.
  locationOff,

  /// Permission refused, but re-askable — sliding again re-prompts.
  permissionDenied,

  /// Permission refused permanently; only the settings screen can undo it.
  permissionBlocked,

  /// Permission fine, no fix arrived.
  fixUnavailable,

  /// Measured outside the radius — by us before sending, or by the server
  /// after. No attendance row was written either way.
  outsidePremises,

  /// No site configured for this poojari. A deployment problem, not theirs.
  noTempleLocation,

  /// Anything else — offline, throttled, session gone. See [failure].
  failed,

  /// A check-in was already in flight; this slide was dropped. Nothing to
  /// show — the slider is already saying it is busy.
  busy,
}

/// The outcome of `AttendanceController.checkIn`, carrying enough for the card
/// to say something specific rather than "could not mark".
class CheckInResult {
  const CheckInResult._(
    this.block, {
    this.distanceMeters,
    this.radiusMeters,
    this.failure,
  });

  const CheckInResult.marked() : this._(CheckInBlock.none);

  const CheckInResult.locationOff() : this._(CheckInBlock.locationOff);

  const CheckInResult.permissionDenied()
    : this._(CheckInBlock.permissionDenied);

  const CheckInResult.permissionBlocked()
    : this._(CheckInBlock.permissionBlocked);

  const CheckInResult.fixUnavailable() : this._(CheckInBlock.fixUnavailable);

  const CheckInResult.noTempleLocation()
    : this._(CheckInBlock.noTempleLocation);

  const CheckInResult.outsidePremises({
    required int distanceMeters,
    required int radiusMeters,
  }) : this._(
         CheckInBlock.outsidePremises,
         distanceMeters: distanceMeters,
         radiusMeters: radiusMeters,
       );

  const CheckInResult.failed(Failure failure)
    : this._(CheckInBlock.failed, failure: failure);

  const CheckInResult.busy() : this._(CheckInBlock.busy);

  final CheckInBlock block;

  /// Set for [CheckInBlock.outsidePremises] only.
  final int? distanceMeters;
  final int? radiusMeters;

  /// Set for [CheckInBlock.failed] only.
  final Failure? failure;

  bool get ok => block == CheckInBlock.none;

  /// Whether the poojari can fix this from the phone's settings — the block
  /// dialog grows a second button for these.
  bool get opensSettings =>
      block == CheckInBlock.locationOff ||
      block == CheckInBlock.permissionBlocked;

  /// Title for the blocking popup. Empty when [ok].
  String get title => switch (block) {
    CheckInBlock.none => '',
    CheckInBlock.locationOff => GateCopy.locationOffTitle,
    CheckInBlock.permissionDenied => GateCopy.permissionDeniedTitle,
    CheckInBlock.permissionBlocked => GateCopy.permissionBlockedTitle,
    CheckInBlock.fixUnavailable => GateCopy.fixUnavailableTitle,
    CheckInBlock.outsidePremises => GateCopy.outsideTitle,
    CheckInBlock.noTempleLocation => GateCopy.noTempleLocationTitle,
    // A failure is a toast, not a popup — it has no title.
    CheckInBlock.failed => '',
    CheckInBlock.busy => '',
  };

  /// Body copy for the popup, or the toast line for [CheckInBlock.failed].
  String get message => switch (block) {
    CheckInBlock.none => '',
    CheckInBlock.locationOff => GateCopy.locationOffMessage,
    CheckInBlock.permissionDenied => GateCopy.permissionDeniedMessage,
    CheckInBlock.permissionBlocked => GateCopy.permissionBlockedMessage,
    CheckInBlock.fixUnavailable => GateCopy.fixUnavailableMessage,
    // Falls back to the design's generic line if a distance somehow did not
    // come through — better a vaguer sentence than an empty popup.
    CheckInBlock.outsidePremises =>
      distanceMeters == null || radiusMeters == null
          ? GateCopy.outsideMessage
          : GateCopy.outsideMessageFor(
              distanceMeters: distanceMeters!,
              radiusMeters: radiusMeters!,
            ),
    CheckInBlock.noTempleLocation => GateCopy.noTempleLocationMessage,
    CheckInBlock.failed => failure?.message ?? '',
    CheckInBlock.busy => '',
  };
}
