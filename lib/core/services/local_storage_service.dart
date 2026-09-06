import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/user_profile.dart';

/// Offline-first local persistence for user wellness data.
///
/// Everything here starts empty. Nothing is pre-seeded, so a number shown in
/// the UI is always something the user or their watch actually produced.
class LocalStorageService {
  static const _boxName = 'nflbot_cache';

  late Box<dynamic> _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
    await _rollOverDayIfNeeded();
  }

  // ── Profile ─────────────────────────────────────────────────────

  UserProfile get profile {
    final raw = _box.get('user_profile');
    if (raw is! String) return UserProfile.empty;
    try {
      return UserProfile.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return UserProfile.empty;
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _box.put('user_profile', jsonEncode(profile.toJson()));
    // Weight is a tracked trend, so a profile update also extends the series.
    final history = weightHistory;
    if (history.isEmpty || history.last != profile.weightKg) {
      await appendWeight(profile.weightKg);
    }
  }

  // ── Today's totals ──────────────────────────────────────────────

  int get caloriesConsumed => _box.get('calories', defaultValue: 0) as int;
  double get proteinG => _double('protein');
  double get carbsG => _double('carbs');
  double get fatG => _double('fat');
  double get hydrationLiters => _double('hydration');

  /// Zero means "not logged yet" rather than "slept zero hours".
  int get sleepHours => _box.get('sleep_hours', defaultValue: 0) as int;
  int get sleepQuality => _box.get('sleep_quality', defaultValue: 0) as int;
  bool get hasSleepLog => sleepHours > 0;

  int get workoutsCompleted =>
      _box.get('workouts_completed', defaultValue: 0) as int;
  int get mealsLogged => _box.get('meals_logged', defaultValue: 0) as int;

  /// Consumed calories for the last seven days, oldest first. The final entry
  /// is today and updates live.
  List<double> get weeklyCalories {
    final raw = _box.get('weekly_calories');
    final stored = raw is List
        ? raw.map((v) => (v as num).toDouble()).toList()
        : <double>[];
    final week = List<double>.filled(7, 0);
    for (var i = 0; i < stored.length && i < 7; i++) {
      week[7 - stored.length + i] = stored[i];
    }
    week[6] = caloriesConsumed.toDouble();
    return week;
  }

  Future<void> saveNutrition({
    required int calories,
    required double protein,
    required double carbs,
    required double fat,
  }) async {
    await _box.putAll({
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    });
  }

  Future<void> saveHydration(double liters) => _box.put('hydration', liters);

  Future<void> saveSleep(int hours, int quality) async {
    await _box.put('sleep_hours', hours);
    await _box.put('sleep_quality', quality);
  }

  Future<void> recordWorkoutComplete() async {
    await _box.put('workouts_completed', workoutsCompleted + 1);
  }

  Future<void> recordMealLogged() async {
    await _box.put('meals_logged', mealsLogged + 1);
  }

  /// Moves today's totals into history and clears them when the date changes,
  /// so the dashboard never presents yesterday's food as today's.
  Future<void> _rollOverDayIfNeeded() async {
    final today = _dayKey(DateTime.now());
    final last = _box.get('last_active_day') as String?;
    if (last == today) return;

    if (last != null) {
      final raw = _box.get('weekly_calories');
      final history = raw is List
          ? raw.map((v) => (v as num).toDouble()).toList()
          : <double>[];
      history.add(caloriesConsumed.toDouble());
      await _box.put('weekly_calories', _capped(history, 6));

      await _box.putAll({
        'calories': 0,
        'protein': 0.0,
        'carbs': 0.0,
        'fat': 0.0,
        'hydration': 0.0,
        'meals_logged': 0,
        'sleep_hours': 0,
        'sleep_quality': 0,
      });
    }

    await _box.put('last_active_day', today);
  }

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── Intelligence history ────────────────────────────────────────
  // Rolling windows the readiness and anomaly engines score against. Empty
  // until real samples arrive; the engines fall back to neutral scoring and
  // the UI reports insufficient data.

  List<int> get restingHrHistory => _intList('rhr_history');
  List<int> get hrvHistory => _intList('hrv_history');
  List<double> get sleepHistory => _doubleList('sleep_history');
  List<int> get dailyLoadHistory => _intList('load_history');
  List<int> get bedtimeHistory => _intList('bedtime_history');
  List<double> get weightHistory => _doubleList('weight_history');

  /// True once there is enough history for baselines to mean anything.
  bool get hasVitalsBaseline => hrvHistory.length >= 3;

  Future<void> appendVitalsSample({
    required int restingHr,
    required int hrv,
  }) async {
    await _box.put('rhr_history', _capped([...restingHrHistory, restingHr]));
    await _box.put('hrv_history', _capped([...hrvHistory, hrv]));
  }

  Future<void> appendSleepSample(double hours, int bedtimeMinutes) async {
    await _box.put('sleep_history', _capped([...sleepHistory, hours]));
    await _box.put(
      'bedtime_history',
      _capped([...bedtimeHistory, bedtimeMinutes]),
    );
  }

  Future<void> appendTrainingLoad(int load) async {
    await _box.put('load_history', _capped([...dailyLoadHistory, load]));
  }

  Future<void> appendWeight(double kg) async {
    await _box.put('weight_history', _capped([...weightHistory, kg]));
  }

  int get missedSessions => _box.get('missed_sessions', defaultValue: 0) as int;
  Future<void> setMissedSessions(int count) =>
      _box.put('missed_sessions', count.clamp(0, 7));

  // ── Export / erase ──────────────────────────────────────────────

  /// Every stored value, for the data export feature.
  Map<String, dynamic> exportAll() => {
    'exported_at': DateTime.now().toIso8601String(),
    'profile': profile.toJson(),
    'today': {
      'date': _box.get('last_active_day'),
      'calories': caloriesConsumed,
      'protein_g': proteinG,
      'carbs_g': carbsG,
      'fat_g': fatG,
      'hydration_l': hydrationLiters,
      'sleep_hours': sleepHours,
      'sleep_quality': sleepQuality,
      'meals_logged': mealsLogged,
    },
    'totals': {'workouts_completed': workoutsCompleted},
    'history': {
      'weekly_calories': weeklyCalories,
      'resting_hr': restingHrHistory,
      'hrv_ms': hrvHistory,
      'sleep_hours': sleepHistory,
      'bedtime_minutes_from_midnight': bedtimeHistory,
      'training_load': dailyLoadHistory,
      'weight_kg': weightHistory,
    },
  };

  Future<void> eraseAll() => _box.clear();

  /// Keeps 28 days so the chronic-load window always has data.
  static List<T> _capped<T>(List<T> values, [int max = 28]) =>
      values.length <= max ? values : values.sublist(values.length - max);

  double _double(String key) =>
      (_box.get(key, defaultValue: 0.0) as num).toDouble();

  List<int> _intList(String key) {
    final raw = _box.get(key);
    if (raw is! List) return const [];
    return raw.map((v) => (v as num).round()).toList();
  }

  List<double> _doubleList(String key) {
    final raw = _box.get(key);
    if (raw is! List) return const [];
    return raw.map((v) => (v as num).toDouble()).toList();
  }
}
