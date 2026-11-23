import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:in_app_update/in_app_update.dart';

/// Android in-app update via Google Play's In-App Update API.
///
/// The pop-ups are rendered by Play itself — this service only decides *when*
/// and *which flow* (immediate vs flexible) to request. See
/// `in_app_update_implementation.md` at the repo root.
///
/// Decision flow:
///  * not Android → no-op (the API is Play-only).
///  * a flexible download already finished in an earlier session → show the
///    Play "restart to install" prompt.
///  * a developer-triggered immediate update was interrupted → resume it.
///  * update available with priority ≥ [immediatePriorityThreshold] and the
///    immediate flow allowed → blocking full-screen Play overlay.
///  * otherwise, if allowed → flexible (background download), then the
///    restart prompt — but only when the download actually succeeded.
///
/// Every failure is swallowed: no Play Store, a sideloaded / debug build with a
/// different signing key, or no network must never block the poojari.
class AppUpdateService {
  const AppUpdateService();

  /// `updatePriority` (0–5) is set per release through the Play Developer
  /// API (`inAppUpdatePriority`); it defaults to 0, so unless a release is
  /// explicitly marked important every update goes through the flexible flow.
  static const int immediatePriorityThreshold = 4;

  /// Guards against overlapping checks (e.g. the home screen being rebuilt
  /// while a flexible download is still pending) stacking two Play pop-ups.
  static bool _inFlight = false;

  Future<void> checkAndPrompt() async {
    if (!Platform.isAndroid || _inFlight) return;
    _inFlight = true;

    try {
      final info = await InAppUpdate.checkForUpdate();

      // A flexible update downloaded earlier but never installed (the user
      // backgrounded / killed the app before restarting) → prompt restart.
      if (info.installStatus == InstallStatus.downloaded) {
        await InAppUpdate.completeFlexibleUpdate();
        return;
      }

      // An immediate update was started but interrupted → resume it.
      if (info.updateAvailability ==
              UpdateAvailability.developerTriggeredUpdateInProgress &&
          info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
        return;
      }

      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return;
      }

      // High-priority updates → immediate (blocking) flow. On success Play
      // installs and restarts the app itself; nothing further to do here.
      if (info.updatePriority >= immediatePriorityThreshold &&
          info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
        return;
      }

      // Everything else → flexible (background) flow. Only ask for the
      // restart once the download has actually completed; a dismissed
      // pop-up resolves with `userDeniedUpdate`.
      if (info.flexibleUpdateAllowed) {
        final result = await InAppUpdate.startFlexibleUpdate();
        if (result == AppUpdateResult.success) {
          await InAppUpdate.completeFlexibleUpdate();
        }
      }
    } catch (e) {
      // Silent failure — never block the user on update infrastructure.
      if (kDebugMode) debugPrint('In-app update check failed: $e');
    } finally {
      _inFlight = false;
    }
  }
}
