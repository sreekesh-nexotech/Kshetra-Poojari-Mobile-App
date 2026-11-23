/// Build-time configuration, supplied with `--dart-define`.
///
/// ```
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
/// flutter build apk --release \
///     --dart-define=FLAVOR=prod \
///     --dart-define=API_BASE_URL=https://api.temple.example
/// ```
///
/// Nothing is read from an asset or a `.env` file: `String.fromEnvironment` is
/// const-folded into the binary, so there is no I/O and no extra dependency.
library;

enum Flavor { dev, staging, prod }

abstract final class Env {
  Env._();

  /// Raw flavor name. Kept as a `String` because `Flavor.values.byName` is not
  /// a const expression — [flavor] does the lookup at first read.
  static const String flavorName = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'dev',
  );

  /// Django host, no trailing slash. Every path in [Endpoints] already starts
  /// with `/api/...`, so this must stay host-only — no `/api` suffix here, or
  /// requests double up to `/api/api/...`.
  ///
  /// Defaults to the production API so a bare `flutter run` works. Override it
  /// for a backend on your own machine — `10.0.2.2` is the dev machine as seen
  /// from the Android emulator, since `localhost` there is the emulator itself:
  ///
  /// ```
  /// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
  /// ```
  ///
  /// A plain-http override is rejected by [EnvLoader] in a release build — a
  /// release must pass an https URL explicitly. Android also refuses cleartext
  /// to any host not in `android/app/src/debug/res/xml/network_security_config.xml`.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://app.mykshethra.com',
  );

  /// Sentry client DSN. A DSN only lets a client *send* events to the project,
  /// so shipping it in the binary is expected. Pass an empty value to turn
  /// crash reporting off: `--dart-define=SENTRY_DSN=`.
  static const String sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue:
        'https://b30a26d473712460e1e15ed7c657d55c@o4510509677608960.ingest.us.sentry.io/4511392939442176',
  );

  static Flavor get flavor => Flavor.values.firstWhere(
    (f) => f.name == flavorName,
    orElse: () => Flavor.dev,
  );

  static bool get isProd => flavor == Flavor.prod;
}
