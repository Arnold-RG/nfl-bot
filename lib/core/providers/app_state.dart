import 'package:flutter/foundation.dart';
import '../engines/activity_engine.dart';
import '../engines/body_engine.dart';
import '../engines/calorie_engine.dart';
import '../engines/fasting_engine.dart';
import '../engines/overload_engine.dart';
import '../models/coach_context.dart';
import '../models/coach_persona.dart';
import '../models/smart_watch_model.dart';
import '../models/user_profile.dart';
import '../models/food_model.dart';
import '../data/workout_database.dart';
import '../services/app_services.dart';

class AppState extends ChangeNotifier {
  // Account
  String _userName = 'Athlete';
  CoachVoice _coachVoice = CoachVoice.nova;
  bool _darkMode = false;
  bool _voiceEnabled = true;
  bool _biometricEnabled = false;

  String get userName => _userName;
  CoachVoice get coachVoice => _coachVoice;
  CoachPersona get coach => CoachPersona.forVoice(_coachVoice);
  bool get darkMode => _darkMode;

  /// When on, every coach reply is spoken aloud.
  bool get voiceEnabled => _voiceEnabled;
  bool get biometricEnabled => _biometricEnabled;

  // Body profile — the source of every personalized target below.
  UserProfile _profile = UserProfile.empty;
  UserProfile get profile => _profile;
  bool get hasProfile => _profile.isComplete;
  DailyTargets get targets => _profile.targets;

  // Training profile
  String _equipmentProfile = 'home';
  int _trainingFrequency = 3;
  String _trainingExperience = 'intermediate';

  String get equipmentProfile => _equipmentProfile;
  int get trainingFrequency => _trainingFrequency;
  String get trainingExperience => _trainingExperience;

  // Fasting
  FastingProtocol _fastingProtocol = FastingProtocol.sixteenEight;
  DateTime? _fastingStartedAt;
  int _customFastHours = 16;

  FastingProtocol get fastingProtocol => _fastingProtocol;
  DateTime? get fastingStartedAt => _fastingStartedAt;
  int get customFastHours => _customFastHours;

  FastingStatus get fastingStatus => FastingEngine.status(
        protocol: _fastingProtocol,
        startedAt: _fastingStartedAt,
        customFastHours: _customFastHours,
      );

  // Activity
  final List<ActivitySession> _activitySessions = [];
  List<ActivitySession> get activitySessions =>
      List.unmodifiable(_activitySessions);

  List<ActivitySession> get todayActivitySessions {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return _activitySessions
        .where((s) => !s.startedAt.isBefore(start))
        .toList();
  }

  // Steps
  int _steps = 0;
  String _stepStatus = 'unknown';
  int get steps => _steps;
  int get stepGoal => targets.stepGoal;
  String get stepStatus => _stepStatus;
  double get stepProgress => (_steps / stepGoal).clamp(0.0, 1.0);

  // Hydration & sleep
  double _hydrationLiters = 0;
  int _sleepHours = 0;
  int _sleepQuality = 0;
  double get hydrationLiters => _hydrationLiters;
  double get hydrationGoal => targets.waterLiters;
  int get sleepHours => _sleepHours;
  int get sleepQuality => _sleepQuality;
  bool get hasSleepLog => _sleepHours > 0;

  // Progress tracking
  int _workoutsCompleted = 0;
  int _mealsLogged = 0;
  List<double> _weeklyCalories = List<double>.filled(7, 0);
  int get workoutsCompleted => _workoutsCompleted;
  int get mealsLogged => _mealsLogged;
  List<double> get weeklyCalories => List.unmodifiable(_weeklyCalories);

  // Nutrition
  int _caloriesConsumed = 0;
  double _proteinG = 0;
  double _carbsG = 0;
  double _fatG = 0;
  final List<MealLogItem> _todayMeals = [];

  int get caloriesConsumed => _caloriesConsumed;
  int get calorieGoal => caloriePlan.adjustedTarget;
  double get proteinG => _proteinG;
  double get carbsG => _carbsG;
  double get fatG => _fatG;
  List<MealLogItem> get todayMeals => List.unmodifiable(_todayMeals);

  CaloriePlan get caloriePlan => CalorieEngine.plan(
        targets: targets,
        sessionsToday: todayActivitySessions,
        pedometerSteps: _steps,
        watchConnected: _watchConnected,
      );

  List<ActivityChallenge> get activityChallenges {
    final week = ActivityEngine.weekStepsFrom(_activitySessions, _steps);
    final month = ActivityEngine.monthStepsFrom(_activitySessions, _steps);
    return ActivityEngine.challenges(
      todaySteps: _steps,
      weekSteps: week,
      monthSteps: month,
    );
  }

  int get lifestyleStreak => ActivityEngine.lifestyleStreak(
        workoutsCompleted: _workoutsCompleted,
        daysWithSteps: _steps > 1000 ? 1 : 0,
        restDaysLogged: 0,
      );

  /// Strength composite from workouts, experience, and recovery readiness.
  int get strengthScore {
    final day = BodyEngine.snapshot(this);
    final exp = switch (_trainingExperience.toLowerCase()) {
      'beginner' => 8,
      'advanced' => 22,
      _ => 15,
    };
    final load = (_workoutsCompleted * 3).clamp(0, 30);
    final freq = (_trainingFrequency * 4).clamp(0, 20);
    return (40 + exp + load + freq + (day.trainingReadiness * 0.15))
        .round()
        .clamp(35, 99);
  }

  /// Fitness composite from steps, cardio sessions, and health score.
  int get fitnessScore {
    final day = BodyEngine.snapshot(this);
    final stepPart = ((_steps / stepGoal).clamp(0, 1.2) * 25);
    final sessionPart = (todayActivitySessions.length * 8).clamp(0, 20);
    return (35 + stepPart + sessionPart + day.healthScore * 0.3)
        .round()
        .clamp(35, 99);
  }

  String get weeklyReportBrief {
    final day = BodyEngine.snapshot(this);
    final challenges = activityChallenges;
    final daily = challenges.first;
    return 'Week brief: Health ${day.healthScore}, Strength $strengthScore, '
        'Fitness $fitnessScore. Streak $lifestyleStreak days (rest counts). '
        'Steps ${daily.label}. Equipment: $_equipmentProfile · '
        '$_trainingFrequency×/week · $_trainingExperience. '
        '${day.coachBrief}';
  }

  OverloadPrescription get overloadPreview =>
      OverloadEngine.previewForProfile(
        equipment: _equipmentProfile,
        experience: _trainingExperience,
        recoveryPercent: BodyEngine.snapshot(this).recoveryPercent,
      );

  // Coach state
  CoachMood _mood = CoachMood.neutral;
  String _coachMessage = 'Tap the orb and talk to me.';
  CoachMood get coachMood => _mood;
  String get coachMessage => _coachMessage;

  // Smart watch bridge
  bool _watchConnected = false;
  String? _watchName;
  int _watchHeartRate = 0;
  int _watchSpo2 = 0;
  int _watchHrv = 0;
  int _watchBattery = 0;

  bool get watchConnected => _watchConnected;
  String? get watchName => _watchName;
  int get watchHeartRate => _watchHeartRate;
  int get watchSpo2 => _watchSpo2;
  int get watchHrv => _watchHrv;
  int get watchBattery => _watchBattery;

  void onWatchConnected(String name, WatchVitals vitals) {
    _watchConnected = true;
    _watchName = name;
    _applyVitals(vitals);
    setCoachState(
      CoachMood.celebrating,
      'Watch linked: $name. I can read your live vitals now.',
    );
  }

  void onWatchDisconnected() {
    _watchConnected = false;
    _watchName = null;
    setCoachState(
      CoachMood.focused,
      'Watch disconnected. Pair again any time from the Watch Hub.',
    );
  }

  void syncWatchVitals(WatchVitals vitals) {
    if (!_watchConnected) return;
    _applyVitals(vitals);
    notifyListeners();
  }

  void _applyVitals(WatchVitals vitals) {
    _watchHeartRate = vitals.heartRateBpm;
    _watchSpo2 = vitals.spo2Percent;
    _watchHrv = vitals.hrvMs;
    _watchBattery =
        AppServices.watch.pairedDevice?.batteryPercent ?? _watchBattery;
    if (vitals.steps > _steps) _steps = vitals.steps;
  }

  // Workout
  WorkoutPlan? _currentWorkout;
  WorkoutPlan? get currentWorkout => _currentWorkout;

  // Chat
  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  bool _coachThinking = false;
  bool get coachThinking => _coachThinking;

  /// Context handed to the AI coach so answers reference real numbers.
  CoachContext get coachContext => CoachContext(
        userName: _userName,
        coach: coach,
        caloriesConsumed: _caloriesConsumed,
        calorieGoal: calorieGoal,
        proteinG: _proteinG,
        steps: _steps,
        stepGoal: stepGoal,
        hydrationLiters: _hydrationLiters,
        sleepHours: _sleepHours.toDouble(),
        workoutsCompleted: _workoutsCompleted,
        watchConnected: _watchConnected,
        heartRate: _watchConnected ? _watchHeartRate : null,
        spo2: _watchConnected ? _watchSpo2 : null,
        hrv: _watchConnected ? _watchHrv : null,
        readiness: AppServices.intelligence.readiness,
        languageName: AppServices.locale.language.englishName,
        languageCode: AppServices.locale.language.code,
        countryName: AppServices.locale.country.name,
      );

  bool _initialized = false;
  bool get initialized => _initialized;

  void initFromPrefs({
    required String userName,
    required CoachVoice voice,
    required bool darkMode,
    required bool voiceEnabled,
    required bool biometricEnabled,
  }) {
    _userName = userName;
    _coachVoice = voice;
    _darkMode = darkMode;
    _voiceEnabled = voiceEnabled;
    _biometricEnabled = biometricEnabled;
    try {
      final prefs = AppServices.prefs;
      _equipmentProfile = prefs.equipmentProfile;
      _trainingExperience = prefs.trainingExperience;
      _trainingFrequency = prefs.trainingFrequency;
      _fastingProtocol = FastingProtocol.values.firstWhere(
        (p) => p.name == prefs.fastingProtocol,
        orElse: () => FastingProtocol.sixteenEight,
      );
      _customFastHours = prefs.customFastHours;
      final startedMs = prefs.fastingStartedAtMs;
      _fastingStartedAt =
          startedMs > 0 ? DateTime.fromMillisecondsSinceEpoch(startedMs) : null;
    } catch (_) {
      // Unit tests / early boot may not have AppServices wired yet.
    }
    if (_messages.isEmpty) {
      _messages.add(
        ChatMessage(
          text: CoachPersona.forVoice(voice).greeting,
          isUser: false,
          mood: CoachMood.encouraging,
        ),
      );
    }
    _initialized = true;
    notifyListeners();
  }

  void loadFromStorage() {
    final s = AppServices.storage;
    _profile = s.profile;
    _caloriesConsumed = s.caloriesConsumed;
    _proteinG = s.proteinG;
    _carbsG = s.carbsG;
    _fatG = s.fatG;
    _hydrationLiters = s.hydrationLiters;
    _sleepHours = s.sleepHours;
    _sleepQuality = s.sleepQuality;
    _workoutsCompleted = s.workoutsCompleted;
    _mealsLogged = s.mealsLogged;
    _weeklyCalories = s.weeklyCalories;
    notifyListeners();
  }

  Future<void> _persist() async {
    await AppServices.storage.saveNutrition(
      calories: _caloriesConsumed,
      protein: _proteinG,
      carbs: _carbsG,
      fat: _fatG,
    );
    await AppServices.storage.saveHydration(_hydrationLiters);
    await AppServices.storage.saveSleep(_sleepHours, _sleepQuality);
  }

  Future<void> saveProfile(UserProfile profile) async {
    _profile = profile.copyWith(isComplete: true);
    await AppServices.storage.saveProfile(_profile);
    AppServices.intelligence.recompute();
    notifyListeners();
  }

  Future<void> setEquipmentProfile(String profile) async {
    _equipmentProfile = profile;
    await AppServices.prefs.setEquipmentProfile(profile);
    notifyListeners();
  }

  Future<void> setTrainingExperience(String experience) async {
    _trainingExperience = experience;
    await AppServices.prefs.setTrainingExperience(experience);
    notifyListeners();
  }

  Future<void> setTrainingFrequency(int days) async {
    _trainingFrequency = days.clamp(1, 7);
    await AppServices.prefs.setTrainingFrequency(_trainingFrequency);
    notifyListeners();
  }

  Future<void> startFasting({
    FastingProtocol? protocol,
    int? customHours,
  }) async {
    if (protocol != null) {
      _fastingProtocol = protocol;
      await AppServices.prefs.setFastingProtocol(protocol.name);
    }
    if (customHours != null) {
      _customFastHours = customHours;
      await AppServices.prefs.setCustomFastHours(customHours);
    }
    _fastingStartedAt = DateTime.now();
    await AppServices.prefs
        .setFastingStartedAtMs(_fastingStartedAt!.millisecondsSinceEpoch);
    setCoachState(
      CoachMood.focused,
      'Fast started · ${_fastingProtocol.label}. I\'ll track elapsed time.',
    );
    notifyListeners();
  }

  Future<void> stopFasting() async {
    _fastingStartedAt = null;
    await AppServices.prefs.setFastingStartedAtMs(0);
    setCoachState(CoachMood.encouraging, 'Fast ended. Eating window is open.');
    notifyListeners();
  }

  Future<void> setFastingProtocol(FastingProtocol protocol) async {
    _fastingProtocol = protocol;
    await AppServices.prefs.setFastingProtocol(protocol.name);
    notifyListeners();
  }

  void logActivity({
    required ActivityType type,
    required int minutes,
    int steps = 0,
  }) {
    final session = ActivityEngine.buildSession(
      type: type,
      minutes: minutes,
      steps: steps,
    );
    _activitySessions.insert(0, session);
    setCoachState(
      CoachMood.celebrating,
      '${type.label} logged · ~${session.caloriesEst} kcal (estimate).',
    );
    notifyListeners();
  }

  Future<void> completeWorkout(WorkoutPlan plan) async {
    _workoutsCompleted++;
    await AppServices.storage.recordWorkoutComplete();
    // Session intensity feeds the acute:chronic load model.
    await AppServices.intelligence.recordTrainingLoad(plan.totalCalories ~/ 10);
    setCoachState(
      CoachMood.celebrating,
      'Workout complete. You burned about ${plan.totalCalories} calories.',
    );
    notifyListeners();
  }

  void setUserName(String name) {
    _userName = name;
    notifyListeners();
  }

  Future<void> setCoachVoice(CoachVoice v) async {
    _coachVoice = v;
    await AppServices.prefs.setCoachVoice(v);
    final persona = CoachPersona.forVoice(v);
    setCoachState(CoachMood.encouraging, persona.greeting);
    // Speaking the greeting is how the user auditions the new voice.
    if (_voiceEnabled) {
      await AppServices.voice.speak(persona.greeting, voice: v);
    }
  }

  void setDarkMode(bool v) {
    _darkMode = v;
    AppServices.prefs.setDarkMode(v);
    notifyListeners();
  }

  void setVoiceEnabled(bool v) {
    _voiceEnabled = v;
    AppServices.prefs.setVoiceEnabled(v);
    if (!v) AppServices.voice.stopSpeaking();
    notifyListeners();
  }

  void setBiometricEnabled(bool v) {
    _biometricEnabled = v;
    notifyListeners();
  }

  void updateSteps(int newSteps) {
    final previous = _steps;
    _steps = newSteps;
    if (previous < stepGoal && _steps >= stepGoal) {
      setCoachState(CoachMood.celebrating, 'Step goal cleared. Nicely done.');
    }
    notifyListeners();
  }

  void updateStepStatus(String status) {
    _stepStatus = status;
    notifyListeners();
  }

  void addHydration(double liters) {
    _hydrationLiters = (_hydrationLiters + liters).clamp(0, 10);
    setCoachState(
      CoachMood.encouraging,
      'Hydration logged. ${_hydrationLiters.toStringAsFixed(1)} litres today.',
    );
    _persist();
    notifyListeners();
  }

  void logSleep(int hours, int quality) {
    _sleepHours = hours;
    _sleepQuality = quality;
    setCoachState(
      CoachMood.encouraging,
      'Sleep logged: $hours hours at $quality percent quality.',
    );
    _persist();
    AppServices.intelligence.recordSleep(hours.toDouble(), 30);
    notifyListeners();
  }

  void logMeal(FoodItem food) {
    _caloriesConsumed += food.calories;
    _proteinG += food.proteinG;
    _carbsG += food.carbsG;
    _fatG += food.fatG;
    _todayMeals.add(
      MealLogItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        foodItemId: food.id,
        foodName: food.name,
        quantityG: food.servingSizeG,
        calories: food.calories,
        proteinG: food.proteinG,
        carbsG: food.carbsG,
        fatG: food.fatG,
      ),
    );
    final left = (calorieGoal - _caloriesConsumed).clamp(0, 99999);
    setCoachState(
      CoachMood.encouraging,
      '${food.name} logged. $left calories left today.',
    );
    _mealsLogged++;
    AppServices.storage.recordMealLogged();
    _persist();
    notifyListeners();
  }

  void generateWorkout({
    String focus = 'Full Body',
    int minutes = 25,
    String level = 'Medium',
  }) {
    _currentWorkout = WorkoutDatabase.generateDailyWorkout(
      focus: focus,
      targetMinutes: minutes,
      fitnessLevel: level,
    );
    setCoachState(
      CoachMood.celebrating,
      'Your $focus session is ready. $minutes minutes of work.',
    );
    notifyListeners();
  }

  void setCoachState(CoachMood mood, [String message = '']) {
    _mood = mood;
    if (message.isNotEmpty) _coachMessage = message;
    notifyListeners();
  }

  /// Sends a message to the AI coach and returns the reply text.
  ///
  /// Falls back to on-device knowledge when no model is configured or the
  /// request fails, so there is always an answer. When voice is enabled the
  /// reply is spoken aloud and this future only completes once the coach has
  /// finished talking, which is what lets the hands-free loop take turns.
  Future<String?> sendChatMessage(String text, {bool speak = true}) async {
    final message = text.trim();
    if (message.isEmpty || _coachThinking) return null;

    _messages.add(ChatMessage(text: message, isUser: true));
    _coachThinking = true;
    setCoachState(CoachMood.focused);
    AppServices.voice.markThinking();
    notifyListeners();

    // Prefer grounded Health Data Platform answers before calling the LLM.
    final grounded = AppServices.orchestrator.groundedReply(message, this);
    if (grounded != null) {
      _coachThinking = false;
      _messages.add(
        ChatMessage(
          text: grounded,
          isUser: false,
          mood: CoachMood.focused,
          fromModel: false,
        ),
      );
      setCoachState(CoachMood.focused, grounded);
      if (speak && _voiceEnabled) {
        await AppServices.voice.speak(grounded, voice: _coachVoice);
      } else {
        AppServices.voice.markIdle();
      }
      return grounded;
    }

    // Only the recent exchange is sent, which keeps prompts small and cheap.
    final history = _messages
        .where((m) => !m.hasImage)
        .toList()
        .reversed
        .take(7)
        .toList()
        .reversed
        .where((m) => m.text != message)
        .map((m) => (role: m.isUser ? 'user' : 'assistant', text: m.text))
        .toList();

    final reply = await AppServices.coach.ask(
      userMessage: message,
      context: coachContext,
      history: history,
    );

    _coachThinking = false;
    _messages.add(
      ChatMessage(
        text: reply.text,
        isUser: false,
        mood: reply.mood,
        fromModel: reply.fromModel,
        notice: reply.error,
      ),
    );
    setCoachState(reply.mood, reply.text);

    if (speak && _voiceEnabled) {
      await AppServices.voice.speak(reply.text, voice: _coachVoice);
    } else {
      AppServices.voice.markIdle();
    }
    return reply.text;
  }

  /// Runs a meal photo through the vision model from inside the chat. On
  /// failure the reason is surfaced rather than replaced with a guess.
  Future<void> analyzeImageInChat(Uint8List bytes) async {
    _messages.add(
      ChatMessage(text: 'Meal photo attached', isUser: true, hasImage: true),
    );
    _coachThinking = true;
    setCoachState(CoachMood.focused, 'Looking at your meal...');
    AppServices.voice.markThinking();
    notifyListeners();

    final result = await AppServices.foodVision.analyze(bytes);
    _coachThinking = false;

    if (!result.succeeded) {
      _messages.add(
        ChatMessage(
          text: result.failure!,
          isUser: false,
          mood: CoachMood.concerned,
        ),
      );
      setCoachState(CoachMood.concerned);
      AppServices.voice.markIdle();
      notifyListeners();
      return;
    }

    final lines = result.items
        .map(
          (i) =>
              '• ${i.name} (~${i.portionG.toStringAsFixed(0)}g) — '
              '${i.calories} kcal, ${i.proteinG.toStringAsFixed(0)}g protein',
        )
        .join('\n');
    final response =
        'Here is what I can see:\n\n$lines\n\n'
        'Plate total: ${result.totalCalories} kcal, '
        '${result.totalProteinG.toStringAsFixed(0)}g protein, '
        '${result.totalCarbsG.toStringAsFixed(0)}g carbs, '
        '${result.totalFatG.toStringAsFixed(0)}g fat.'
        '${result.insight != null ? '\n\n${result.insight}' : ''}';

    _messages.add(
      ChatMessage(
        text: response,
        isUser: false,
        mood: CoachMood.celebrating,
        fromModel: true,
      ),
    );
    setCoachState(CoachMood.celebrating, response);
    notifyListeners();

    if (_voiceEnabled) {
      // The itemised list reads poorly aloud, so only the totals are spoken.
      await AppServices.voice.speak(
        'That plate comes to about ${result.totalCalories} calories with '
        '${result.totalProteinG.toStringAsFixed(0)} grams of protein.',
        voice: _coachVoice,
      );
    }
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final CoachMood? mood;
  final bool hasImage;

  /// True when the reply came from the language model rather than the
  /// on-device knowledge fallback.
  final bool fromModel;

  /// Optional banner shown under the bubble, e.g. a degraded-mode notice.
  final String? notice;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.mood,
    this.hasImage = false,
    this.fromModel = false,
    this.notice,
  }) : timestamp = DateTime.now();
}
