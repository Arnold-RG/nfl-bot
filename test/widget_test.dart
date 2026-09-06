import 'package:flutter_test/flutter_test.dart';
import 'package:nfbot_app/core/models/coach_persona.dart';
import 'package:nfbot_app/core/models/user_profile.dart';
import 'package:nfbot_app/core/providers/app_state.dart';
import 'package:nfbot_app/core/data/world_countries.dart';
import 'package:nfbot_app/core/data/world_currencies.dart';
import 'package:nfbot_app/core/data/world_languages.dart';
import 'package:nfbot_app/core/utils/fitness_calculator.dart';
import 'package:nfbot_app/core/utils/pairing_link.dart';

void main() {
  test('AppState boots from prefs without a cartoon trainer', () {
    final state = AppState();
    state.initFromPrefs(
      userName: 'Alex',
      voice: CoachVoice.nova,
      darkMode: false,
      voiceEnabled: true,
      biometricEnabled: false,
    );

    expect(state.userName, 'Alex');
    expect(state.coach.name, 'NOVA');
    expect(state.caloriesConsumed, 0);
    expect(state.steps, 0);
  });

  test('personalized targets come from the body profile, not a hardcoded 2200', () {
    final profile = UserProfile(
      sex: BiologicalSex.male,
      age: 34,
      heightCm: 182,
      weightKg: 84,
      activity: ActivityLevel.moderate,
      goal: FitnessGoal.maintain,
    );

    expect(profile.targets.calories, 2809);
    expect(
      FitnessCalculator.dailyCalories(
        weightKg: 84,
        heightCm: 182,
        age: 34,
        gender: 'male',
        activity: 'moderate',
      ),
      2809,
    );
  });

  test('membership prices convert from PLN into the member currency', () {
    final usd = WorldCurrencies.byCode('USD');
    expect(usd.fromPln(22), closeTo(5.61, 0.05));
    expect(WorldLanguages.byCode('fr').speechLocale, 'fr-FR');
    expect(WorldCountries.byIso('PL').currencyCode, 'PLN');
  });

  test('pairing QR decodes http links and legacy nfbot schemes', () {
    expect(
      PairingLink.decode(
        'http://192.168.0.107:8080/pair.html?watch=garmin-venu-3&ts=1',
      ),
      'garmin-venu-3',
    );
    expect(
      PairingLink.decode('nfbot://watch/apple-watch-ultra?ts=1'),
      'apple-watch-ultra',
    );
    expect(PairingLink.decode('BRAND|MODEL|SERIAL'), isNull);
  });
}
