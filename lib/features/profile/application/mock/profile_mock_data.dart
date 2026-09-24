/// Static app copy for the account screen that isn't backend data. The
/// profile, month KPIs and week strip used to live here too — they now come
/// from the session and `ProfileRepository` (see `profile_providers.dart`).
abstract final class ProfileMockData {
  ProfileMockData._();

  static const String monthLabel = 'ഈ മാസം — സെപ്റ്റംബർ';
}
