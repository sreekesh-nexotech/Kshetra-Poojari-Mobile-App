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

  /// Django host, no trailing slash. `10.0.2.2` is the dev machine as seen
  /// from the Android emulator — `localhost` there is the emulator itself.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static Flavor get flavor => Flavor.values.firstWhere(
    (f) => f.name == flavorName,
    orElse: () => Flavor.dev,
  );

  static bool get isProd => flavor == Flavor.prod;
}
