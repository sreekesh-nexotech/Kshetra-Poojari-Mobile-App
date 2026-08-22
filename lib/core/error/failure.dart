import 'dart:io';

import 'package:dio/dio.dart';

import '../network/network_exceptions.dart';

/// What the UI should do about a failure, beyond showing its message.
enum FailureAction {
  /// Nothing — just tell the poojari.
  none,

  /// The list on screen is out of date; reload it.
  refresh,

  /// The session is gone; clear the jar and show login.
  signOut,

  /// Money moved but the record did not. Block retries, show the refund id.
  callTheOffice,
}

/// A network or API error, translated into copy the poojari can read.
///
/// Every message here is Malayalam because it is rendered directly — the
/// server's own English strings are kept only in [debugMessage] for logs.
class Failure {
  const Failure({
    required this.message,
    this.action = FailureAction.none,
    this.refundId,
    this.debugMessage,
    this.statusCode,
  });

  final String message;
  final FailureAction action;
  final String? refundId;
  final String? debugMessage;
  final int? statusCode;

  bool get isSignedOut => action == FailureAction.signOut;
  bool get needsRefresh => action == FailureAction.refresh;

  /// Translate anything thrown by the data layer.
  ///
  /// [hasSession] disambiguates a `403`: without a session cookie it means the
  /// session expired; with one it means the role/permission is missing
  /// (pooja.md §10).
  factory Failure.from(Object error, {bool hasSession = true}) {
    if (error is ApiException) return Failure._fromApi(error, hasSession);
    if (error is DioException) return Failure._fromDio(error);
    return const Failure(
      message: 'എന്തോ കുഴപ്പം സംഭവിച്ചു · വീണ്ടും ശ്രമിക്കുക',
    );
  }

  factory Failure._fromApi(ApiException e, bool hasSession) {
    if (e.needsManualReconciliation) {
      return Failure(
        message:
            'റീഫണ്ട് തുടങ്ങി, പക്ഷേ രേഖപ്പെടുത്താനായില്ല.\n'
            'റീഫണ്ട് ഐഡി: ${e.refundId}\n'
            'ക്ഷേത്ര ഓഫീസുമായി ബന്ധപ്പെടുക. വീണ്ടും ശ്രമിക്കരുത്.',
        action: FailureAction.callTheOffice,
        refundId: e.refundId,
        debugMessage: e.message,
        statusCode: e.statusCode,
      );
    }

    if (e.isAssignedToSomeoneElse) {
      return Failure(
        message: 'ഈ പൂജ മറ്റൊരു പൂജാരിക്ക് നൽകിയിരിക്കുന്നു',
        action: FailureAction.refresh,
        debugMessage: e.message,
        statusCode: e.statusCode,
      );
    }

    if (e.isStaleOrder) {
      return Failure(
        message: 'ലിസ്റ്റ് പഴയതാണ് · പുതുക്കുന്നു',
        action: FailureAction.refresh,
        debugMessage: e.message,
        statusCode: e.statusCode,
      );
    }

    // Unauthenticated and permission-denied both arrive as 403; only the
    // cookie jar can tell them apart.
    if (e.isForbidden) {
      return Failure(
        message: hasSession
            ? 'അനുമതിയില്ല · അഡ്മിനുമായി ബന്ധപ്പെടുക'
            : 'സെഷൻ കാലഹരണപ്പെട്ടു · വീണ്ടും ലോഗിൻ ചെയ്യുക',
        action: FailureAction.signOut,
        debugMessage: e.message,
        statusCode: e.statusCode,
      );
    }

    if (e.isThrottled) {
      return Failure(
        message: 'വളരെയധികം അഭ്യർത്ഥനകൾ · അൽപ്പം കഴിഞ്ഞ് ശ്രമിക്കുക',
        debugMessage: e.message,
        statusCode: e.statusCode,
      );
    }

    return Failure(
      message: e.message,
      debugMessage: e.message,
      statusCode: e.statusCode,
    );
  }

  factory Failure._fromDio(DioException e) {
    final timedOut =
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout;

    if (timedOut) {
      return Failure(
        message: 'സെർവർ പ്രതികരിക്കുന്നില്ല · വീണ്ടും ശ്രമിക്കുക',
        debugMessage: e.message,
      );
    }

    if (e.type == DioExceptionType.connectionError ||
        e.error is SocketException) {
      return Failure(
        message: 'ഇന്റർനെറ്റ് കണക്ഷൻ ഇല്ല',
        debugMessage: e.message,
      );
    }

    return Failure(
      message: 'സെർവറിൽ പിഴവ് · വീണ്ടും ശ്രമിക്കുക',
      debugMessage: e.message,
      statusCode: e.response?.statusCode,
    );
  }
}
