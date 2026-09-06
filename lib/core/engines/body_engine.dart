import '../models/user_profile.dart';
import '../providers/app_state.dart';
import 'activity_engine.dart';

enum MuscleStatus { fresh, ready, tired, sore }

class MuscleRecovery {
  final String name;
  final int percent;
  const MuscleRecovery(this.name, this.percent);

  MuscleStatus get status {
    if (percent >= 85) return MuscleStatus.fresh;
    if (percent >= 70) return MuscleStatus.ready;
    if (percent >= 45) return MuscleStatus.tired;
    return MuscleStatus.sore;
  }

  String get emoji => switch (status) {
    MuscleStatus.fresh || MuscleStatus.ready => '🟢',
    MuscleStatus.tired => '🟡',
    MuscleStatus.sore => '🔴',
  };
}

/// Canonical day snapshot: BODY → MOVEMENT → FOOD → TRAINING → RECOVERY → AI.
class BodyDaySnapshot {
  final int healthScore;
  final int recoveryPercent;
  final double sleepHours;
  final int sleepMinutes;
  final int steps;
  final int stepGoal;
  final int caloriesBurned;
  final int caloriesRemaining;
  final int caloriesConsumed;
  final int calorieGoal;
  final int trainingReadiness;
  final double waterLiters;
  final double waterGoal;
  final double proteinG;
  final double proteinGoal;
  final double carbsG;
  final double carbsGoal;
  final double fatG;
  final double fatGoal;
  final String workoutTitle;
  final String workoutFocus;
  final int workoutMinutes;
  final String coachBrief;
  final List<MuscleRecovery> muscles;
  final int streakDays;
  final bool estimatesOnly;

  const BodyDaySnapshot({
    required this.healthScore,
    required this.recoveryPercent,
    required this.sleepHours,
    required this.sleepMinutes,
    required this.steps,
    required this.stepGoal,
    required this.caloriesBurned,
    required this.caloriesRemaining,
    required this.caloriesConsumed,
    required this.calorieGoal,
    required this.trainingReadiness,
    required this.waterLiters,
    required this.waterGoal,
    required this.proteinG,
    required this.proteinGoal,
    required this.carbsG,
    required this.carbsGoal,
    required this.fatG,
    required this.fatGoal,
    required this.workoutTitle,
    required this.workoutFocus,
    required this.workoutMinutes,
    required this.coachBrief,
    required this.muscles,
    required this.streakDays,
    required this.estimatesOnly,
  });
}

class BodyEngine {
  /// Deterministic wellness score — not a medical diagnosis.
  static BodyDaySnapshot snapshot(AppState state) {
    final t = state.targets;
    final sleepH = state.hasSleepLog ? state.sleepHours.toDouble() : 7.5;
    final sleepM = state.hasSleepLog ? ((state.sleepQuality / 100) * 60).round().clamp(0, 59) : 42;
    final recovery = _recovery(state, sleepH);
    final readiness = _readiness(recovery, state);
    final burned = _burnEstimate(state);
    final remaining = (state.calorieGoal - state.caloriesConsumed).clamp(0, 99999);
    final health = _healthScore(
      recovery: recovery,
      readiness: readiness,
      steps: state.steps,
      stepGoal: t.stepGoal,
      protein: state.proteinG,
      proteinGoal: t.proteinG,
      water: state.hydrationLiters,
      waterGoal: t.waterLiters,
      calories: state.caloriesConsumed,
      calorieGoal: state.calorieGoal,
    );

    final plan = _todayPlan(state.profile.goal, readiness);
    final muscles = _muscles(readiness);
    final brief = _brief(state, recovery, readiness, plan.$1, plan.$2);

    return BodyDaySnapshot(
      healthScore: health,
      recoveryPercent: recovery,
      sleepHours: sleepH,
      sleepMinutes: sleepM,
      steps: state.steps,
      stepGoal: t.stepGoal,
      caloriesBurned: burned,
      caloriesRemaining: remaining,
      caloriesConsumed: state.caloriesConsumed,
      calorieGoal: state.calorieGoal,
      trainingReadiness: readiness,
      waterLiters: state.hydrationLiters,
      waterGoal: t.waterLiters,
      proteinG: state.proteinG,
      proteinGoal: t.proteinG,
      carbsG: state.carbsG,
      carbsGoal: t.carbsG,
      fatG: state.fatG,
      fatGoal: t.fatG,
      workoutTitle: plan.$1,
      workoutFocus: plan.$2,
      workoutMinutes: plan.$3,
      coachBrief: brief,
      muscles: muscles,
      streakDays: ActivityEngine.lifestyleStreak(
        workoutsCompleted: state.workoutsCompleted,
        daysWithSteps: state.steps > 1000 ? 1 : 0,
        restDaysLogged: 0,
      ),
      estimatesOnly: !state.watchConnected,
    );
  }

  static int _recovery(AppState state, double sleepH) {
    var score = 55;
    score += ((sleepH - 6) * 8).round().clamp(-20, 25);
    if (state.watchHrv > 0) score += ((state.watchHrv - 40) / 4).round().clamp(-10, 15);
    if (state.watchHeartRate > 0 && state.watchHeartRate < 70) score += 8;
    if (state.steps > state.stepGoal) score -= 4; // high load
    return score.clamp(20, 98);
  }

  static int _readiness(int recovery, AppState state) {
    var score = recovery;
    if (state.profile.goal == FitnessGoal.cut) score -= 3;
    if (state.profile.goal == FitnessGoal.muscle) score += 2;
    return score.clamp(15, 99);
  }

  static int _burnEstimate(AppState state) {
    // Transparent estimate — not wearable truth when watch is absent.
    final base = 450;
    final fromSteps = (state.steps * 0.04).round();
    final fromWatch = state.watchConnected
        ? (state.watchHeartRate.clamp(50, 160) * 4)
        : 0;
    return base + fromSteps + (fromWatch ~/ 10);
  }

  static int _healthScore({
    required int recovery,
    required int readiness,
    required int steps,
    required int stepGoal,
    required double protein,
    required double proteinGoal,
    required double water,
    required double waterGoal,
    required int calories,
    required int calorieGoal,
  }) {
    final stepPart = ((steps / stepGoal).clamp(0, 1.2) * 20);
    final proteinPart = ((protein / proteinGoal).clamp(0, 1.2) * 20);
    final waterPart = ((water / waterGoal).clamp(0, 1.2) * 15);
    final caloriePart = calories == 0
        ? 8.0
        : (1 - ((calories - calorieGoal).abs() / calorieGoal).clamp(0, 1)) * 15;
    final recoveryPart = recovery * 0.15;
    final readinessPart = readiness * 0.15;
    return (stepPart + proteinPart + waterPart + caloriePart + recoveryPart + readinessPart)
        .round()
        .clamp(35, 99);
  }

  static (String, String, int) _todayPlan(FitnessGoal goal, int readiness) {
    if (readiness < 45) {
      return ('Active Recovery', 'Walk + mobility', 25);
    }
    return switch (goal) {
      FitnessGoal.muscle => ('Upper Body', 'Chest + Back + Shoulders', 52),
      FitnessGoal.cut => ('Full Body Conditioning', 'Circuits + core', 40),
      FitnessGoal.endurance => ('Cardio Builder', 'Intervals + easy miles', 45),
      FitnessGoal.maintain => ('Strength Maintain', 'Push + pull + legs', 45),
    };
  }

  static List<MuscleRecovery> _muscles(int readiness) {
    final base = readiness;
    return [
      MuscleRecovery('Chest', (base + 8).clamp(20, 98)),
      MuscleRecovery('Back', (base + 2).clamp(20, 98)),
      MuscleRecovery('Shoulders', (base - 12).clamp(20, 98)),
      MuscleRecovery('Biceps', (base + 6).clamp(20, 98)),
      MuscleRecovery('Triceps', (base - 8).clamp(20, 98)),
      MuscleRecovery('Quads', (base - 40).clamp(15, 98)),
      MuscleRecovery('Hamstrings', (base - 5).clamp(20, 98)),
      MuscleRecovery('Glutes', (base + 4).clamp(20, 98)),
    ];
  }

  static String _brief(
    AppState state,
    int recovery,
    int readiness,
    String title,
    String focus,
  ) {
    final name = state.userName;
    if (readiness < 45) {
      return 'Recovery is lower than usual, $name. Keep today light — '
          'a walk or mobility beats forcing a hard session.';
    }
    final walkNote = state.steps > state.stepGoal * 0.4
        ? ' You\'ve already moved more than usual, so I kept volume moderate.'
        : '';
    return 'You\'re well recovered today ($recovery%). $focus are ready. '
        'I\'ve queued $title.$walkNote';
  }
}
