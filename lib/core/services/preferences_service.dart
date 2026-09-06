import 'package:shared_preferences/shared_preferences.dart';
import '../models/coach_persona.dart';

/// Persists user preferences locally for offline-first experience.
class PreferencesService {
  static const _keyCoachVoice = 'coach_voice';
  static const _keyDarkMode = 'dark_mode';
  static const _keyBiometric = 'biometric_enabled';
  static const _keyOnboardingDone = 'onboarding_done';
  static const _keyUserName = 'user_name';
  static const _keyVoiceEnabled = 'voice_enabled';
  static const _keyHandsFree = 'hands_free_voice';
  static const _keyLanguage = 'language_code';
  static const _keyCountry = 'country_code';
  static const _keyCurrency = 'currency_code';
  static const _keyEmail = 'account_email';
  static const _keyPlan = 'plan_id';
  static const _keyPlanUntil = 'plan_renews_ms';
  static const _keyUsageDay = 'usage_day';
  static const _keyUsageVoice = 'usage_voice_today';
  static const _keyUsageScans = 'usage_scans_today';
  static const _keyLanguageTouched = 'language_touched';
  static const _keyCountryChosen = 'country_chosen';
  static const _keyEquipment = 'equipment_profile';
  static const _keyExperience = 'training_experience';
  static const _keyFrequency = 'training_frequency';
  static const _keyFastingProtocol = 'fasting_protocol';
  static const _keyFastingStarted = 'fasting_started_ms';
  static const _keyCustomFastHours = 'custom_fast_hours';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool get onboardingDone => _prefs.getBool(_keyOnboardingDone) ?? false;
  Future<void> setOnboardingDone(bool v) =>
      _prefs.setBool(_keyOnboardingDone, v);

  CoachVoice get coachVoice {
    final v = _prefs.getString(_keyCoachVoice);
    return v == CoachVoice.atlas.name ? CoachVoice.atlas : CoachVoice.nova;
  }

  Future<void> setCoachVoice(CoachVoice v) =>
      _prefs.setString(_keyCoachVoice, v.name);

  /// When on, the coach reopens the microphone after each spoken reply so the
  /// conversation continues without tapping.
  bool get handsFree => _prefs.getBool(_keyHandsFree) ?? true;
  Future<void> setHandsFree(bool v) => _prefs.setBool(_keyHandsFree, v);

  bool get darkMode => _prefs.getBool(_keyDarkMode) ?? false;
  Future<void> setDarkMode(bool v) => _prefs.setBool(_keyDarkMode, v);

  bool get biometricEnabled => _prefs.getBool(_keyBiometric) ?? false;
  Future<void> setBiometricEnabled(bool v) =>
      _prefs.setBool(_keyBiometric, v);

  bool get voiceEnabled => _prefs.getBool(_keyVoiceEnabled) ?? true;
  Future<void> setVoiceEnabled(bool v) => _prefs.setBool(_keyVoiceEnabled, v);

  String get userName => _prefs.getString(_keyUserName) ?? 'Alex';
  Future<void> setUserName(String name) => _prefs.setString(_keyUserName, name);

  String get languageCode => _prefs.getString(_keyLanguage) ?? 'en';
  Future<void> setLanguageCode(String v) async {
    await _prefs.setString(_keyLanguage, v);
    await _prefs.setBool(_keyLanguageTouched, true);
  }

  bool get languageUntouched => !(_prefs.getBool(_keyLanguageTouched) ?? false);

  String get countryCode => _prefs.getString(_keyCountry) ?? 'PL';
  Future<void> setCountryCode(String v) async {
    await _prefs.setString(_keyCountry, v);
    await _prefs.setBool(_keyCountryChosen, true);
  }

  bool get countryChosen => _prefs.getBool(_keyCountryChosen) ?? false;

  String get currencyCode => _prefs.getString(_keyCurrency) ?? 'PLN';
  Future<void> setCurrencyCode(String v) => _prefs.setString(_keyCurrency, v);

  String get email => _prefs.getString(_keyEmail) ?? '';
  Future<void> setEmail(String v) => _prefs.setString(_keyEmail, v);

  String get planId => _prefs.getString(_keyPlan) ?? 'free';
  Future<void> setPlanId(String v) => _prefs.setString(_keyPlan, v);

  int get planRenewsAtMs => _prefs.getInt(_keyPlanUntil) ?? 0;
  Future<void> setPlanRenewsAtMs(int v) => _prefs.setInt(_keyPlanUntil, v);

  int get usageVoiceToday => _prefs.getInt(_keyUsageVoice) ?? 0;
  Future<void> setUsageVoiceToday(int v) => _prefs.setInt(_keyUsageVoice, v);

  int get usageScansToday => _prefs.getInt(_keyUsageScans) ?? 0;
  Future<void> setUsageScansToday(int v) => _prefs.setInt(_keyUsageScans, v);

  Future<void> rollUsageDay() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (_prefs.getString(_keyUsageDay) == today) return;
    await _prefs.setString(_keyUsageDay, today);
    await _prefs.setInt(_keyUsageVoice, 0);
    await _prefs.setInt(_keyUsageScans, 0);
  }

  String get equipmentProfile =>
      _prefs.getString(_keyEquipment) ?? 'home';
  Future<void> setEquipmentProfile(String v) =>
      _prefs.setString(_keyEquipment, v);

  String get trainingExperience =>
      _prefs.getString(_keyExperience) ?? 'intermediate';
  Future<void> setTrainingExperience(String v) =>
      _prefs.setString(_keyExperience, v);

  int get trainingFrequency => _prefs.getInt(_keyFrequency) ?? 3;
  Future<void> setTrainingFrequency(int v) =>
      _prefs.setInt(_keyFrequency, v);

  String get fastingProtocol =>
      _prefs.getString(_keyFastingProtocol) ?? 'sixteenEight';
  Future<void> setFastingProtocol(String v) =>
      _prefs.setString(_keyFastingProtocol, v);

  int get fastingStartedAtMs => _prefs.getInt(_keyFastingStarted) ?? 0;
  Future<void> setFastingStartedAtMs(int v) =>
      _prefs.setInt(_keyFastingStarted, v);

  int get customFastHours => _prefs.getInt(_keyCustomFastHours) ?? 16;
  Future<void> setCustomFastHours(int v) =>
      _prefs.setInt(_keyCustomFastHours, v);

  /// Granular NFL BOT data permissions (product controls; OS still gates sensors).
  bool dataPerm(String key, {bool fallback = true}) =>
      _prefs.getBool('data_perm_$key') ?? fallback;

  Future<void> setDataPerm(String key, bool v) =>
      _prefs.setBool('data_perm_$key', v);
}
