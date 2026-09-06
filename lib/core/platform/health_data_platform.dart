import 'package:flutter/foundation.dart';

import '../engines/activity_engine.dart';
import '../engines/body_engine.dart';
import '../engines/calorie_engine.dart';
import '../engines/fasting_engine.dart';
import '../engines/overload_engine.dart';
import '../providers/app_state.dart';
import 'ai_memory.dart';
import 'data_source.dart';
import 'now_decision.dart';

/// Central NFL BOT Health Data Platform.
///
/// Engines do not own isolated truth. They read/write through this profile so
/// activity, food, training and recovery stay one coherent loop.
class HealthDataPlatform extends ChangeNotifier {
  HealthDataPlatform(this._state);

  final AppState _state;
  final AiMemory memory = AiMemory();
  final List<HealthEvent> _events = [];

  List<HealthEvent> get recentEvents => List.unmodifiable(_events.take(40));

  BodyDaySnapshot get day => BodyEngine.snapshot(_state);

  CaloriePlan get caloriePlan => CalorieEngine.plan(
        targets: _state.targets,
        sessionsToday: _state.todayActivitySessions,
        pedometerSteps: _state.steps,
        watchConnected: _state.watchConnected,
      );

  FastingStatus get fasting => _state.fastingStatus;

  OverloadPrescription nextLift({
    required double lastWeightKg,
    required int lastReps,
    required int rpe,
    String exercise = 'Compound lift',
  }) {
    return OverloadEngine.next(
      OverloadInput(
        lastWeightKg: lastWeightKg,
        lastReps: lastReps,
        rpe: rpe.toDouble(),
        recoveryPercent: day.recoveryPercent,
        exercise: exercise,
      ),
    );
  }

  NowDecision whatShouldIDoNow() => NowDecisionEngine.decide(_state, day);

  MorningBrief morningBrief() => MorningBriefEngine.build(_state, day);

  /// Records a canonical event and keeps a short audit trail (source + confidence).
  void ingest(HealthEvent event) {
    if (event.duplicateOfPrior) {
      _events.insert(0, event);
      notifyListeners();
      return;
    }
    final merged = DataSourcePriority.merge(_events, event);
    _events.insert(0, merged);
    if (_events.length > 200) {
      _events.removeRange(200, _events.length);
    }
    if (!merged.duplicateOfPrior) {
      _apply(merged);
    }
    notifyListeners();
  }

  void _apply(HealthEvent event) {
    switch (event.kind) {
      case HealthEventKind.steps:
        final v = (event.payload['steps'] as num?)?.toInt();
        if (v != null && v > _state.steps) _state.updateSteps(v);
      case HealthEventKind.activity:
        final typeName = event.payload['type'] as String? ?? 'walk';
        final type = ActivityType.values.firstWhere(
          (t) => t.name == typeName,
          orElse: () => ActivityType.walk,
        );
        final minutes = (event.payload['minutes'] as num?)?.toInt() ?? 30;
        final steps = (event.payload['steps'] as num?)?.toInt() ?? 0;
        _state.logActivity(type: type, minutes: minutes, steps: steps);
      case HealthEventKind.meal:
        break;
      case HealthEventKind.workout:
        break;
      case HealthEventKind.sleep:
        final hours = (event.payload['hours'] as num?)?.toInt() ?? 0;
        final quality = (event.payload['quality'] as num?)?.toInt() ?? 70;
        if (hours > 0) _state.logSleep(hours, quality);
      case HealthEventKind.water:
        final liters = (event.payload['liters'] as num?)?.toDouble() ?? 0;
        if (liters > 0) _state.addHydration(liters);
      case HealthEventKind.preference:
        memory.apply(event.payload);
    }
  }

  Map<String, dynamic> exportProfileJson() {
    final d = day;
    return {
      'personal': {
        'name': _state.userName,
        'age': _state.profile.age,
        'sex': _state.profile.sex.name,
        'height_cm': _state.profile.heightCm,
        'weight_kg': _state.profile.weightKg,
      },
      'goals': {
        'fitness_goal': _state.profile.goal.name,
        'activity': _state.profile.activity.name,
      },
      'activity': {
        'steps': d.steps,
        'step_goal': d.stepGoal,
        'sessions_today': _state.todayActivitySessions.length,
      },
      'nutrition': {
        'calories': d.caloriesConsumed,
        'calorie_goal': d.calorieGoal,
        'protein_g': d.proteinG,
        'carbs_g': d.carbsG,
        'fat_g': d.fatG,
        'water_l': d.waterLiters,
      },
      'training': {
        'equipment': _state.equipmentProfile,
        'experience': _state.trainingExperience,
        'frequency': _state.trainingFrequency,
        'workouts_completed': _state.workoutsCompleted,
        'today_plan': d.workoutTitle,
      },
      'recovery': {
        'score': d.recoveryPercent,
        'readiness': d.trainingReadiness,
        'sleep_h': d.sleepHours,
        'hr': _state.watchHeartRate,
        'hrv': _state.watchHrv,
      },
      'ai_profile': memory.toJson(),
      'health_score': d.healthScore,
      'disclaimer':
          'Wellness score and estimates are not medical diagnosis or treatment.',
    };
  }
}

class MorningBrief {
  final int recovery;
  final String training;
  final int calories;
  final int proteinG;
  final int steps;
  final String sleepLabel;
  final String narrative;

  const MorningBrief({
    required this.recovery,
    required this.training,
    required this.calories,
    required this.proteinG,
    required this.steps,
    required this.sleepLabel,
    required this.narrative,
  });
}

class MorningBriefEngine {
  static MorningBrief build(AppState state, BodyDaySnapshot day) {
    final plan = CalorieEngine.plan(
      targets: state.targets,
      sessionsToday: state.todayActivitySessions,
      pedometerSteps: state.steps,
      watchConnected: state.watchConnected,
    );
    final sleepH = day.sleepHours.floor();
    final sleepM = ((day.sleepHours % 1) * 60).round();
    return MorningBrief(
      recovery: day.recoveryPercent,
      training: day.workoutTitle,
      calories: plan.adjustedTarget,
      proteinG: day.proteinGoal.round(),
      steps: day.stepGoal,
      sleepLabel: '${sleepH}h ${sleepM.toString().padLeft(2, '0')}m',
      narrative: day.coachBrief,
    );
  }
}
