import '../models/user_profile.dart';
import 'activity_engine.dart';

/// Deterministic calorie targets. Label estimates; avoid double-counting.

class CaloriePlan {
  final int baseTarget;
  final int activityAdjustment;
  final int adjustedTarget;
  final int estimatedBurnFromActivity;
  final String note;
  final bool estimatesOnly;

  const CaloriePlan({
    required this.baseTarget,
    required this.activityAdjustment,
    required this.adjustedTarget,
    required this.estimatedBurnFromActivity,
    required this.note,
    required this.estimatesOnly,
  });
}

class CalorieEngine {
  /// [baseTarget] comes from [UserProfile.targets] (BMR × activity × goal).
  ///
  /// Activity sessions adjust the day target. If pedometer steps already
  /// inform the profile activity level, do not also add a large step burn —
  /// that would double-count NEAT.
  static CaloriePlan plan({
    required DailyTargets targets,
    required List<ActivitySession> sessionsToday,
    required int pedometerSteps,
    required bool watchConnected,
  }) {
    final sessionBurn = sessionsToday.fold<int>(
      0,
      (sum, s) => sum + s.caloriesEst,
    );

    // Only credit deliberate logged sessions beyond the profile activity factor.
    // Pedometer NEAT is already reflected in ActivityLevel — do not add again.
    final activityAdj = sessionBurn;
    final adjusted = (targets.calories + activityAdj).clamp(1200, 6000);

    final note = sessionBurn > 0
        ? 'Base ${targets.calories} kcal + $sessionBurn kcal from logged '
            'activity (estimate). Pedometer steps are not added again — that '
            'would double-count NEAT already in your activity level.'
        : 'Base target ${targets.calories} kcal from body metrics. '
            'Log a walk/run/gym session to raise todays target. '
            'Do not add step-burn on top of this target (avoids double-count).';

    return CaloriePlan(
      baseTarget: targets.calories,
      activityAdjustment: activityAdj,
      adjustedTarget: adjusted,
      estimatedBurnFromActivity: sessionBurn,
      note: note,
      estimatesOnly: !watchConnected,
    );
  }
}
