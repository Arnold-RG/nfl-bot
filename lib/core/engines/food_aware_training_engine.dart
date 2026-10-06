import 'activity_engine.dart';
import 'nutrition_plan_engine.dart';

/// Turns today's food intake into gym duration, exercise focus, and sport ideas.
class FoodAwareTrainingAdvice {
  final int gymMinutes;
  final String focus;
  final List<String> exerciseTypes;
  final String reason;
  final ActivityType? suggestedSport;
  final String sportReason;

  const FoodAwareTrainingAdvice({
    required this.gymMinutes,
    required this.focus,
    required this.exerciseTypes,
    required this.reason,
    this.suggestedSport,
    required this.sportReason,
  });
}

class FoodAwareTrainingEngine {
  FoodAwareTrainingEngine._();

  static FoodAwareTrainingAdvice build({
    required int caloriesConsumed,
    required int calorieGoal,
    required double proteinG,
    required double proteinGoalG,
    required FitnessGoalHint goal,
    required int readinessScore,
    required List<ActivityType> preferredSports,
    bool workoutAlreadyDone = false,
  }) {
    if (workoutAlreadyDone) {
      return FoodAwareTrainingAdvice(
        gymMinutes: 0,
        focus: 'Recovery',
        exerciseTypes: const ['Walk', 'Mobility', 'Breathing'],
        reason: 'You already trained today. Keep movement easy so tomorrow’s session stays high quality.',
        suggestedSport: preferredSports.isEmpty
            ? ActivityType.walk
            : preferredSports.first,
        sportReason: 'Prefer light movement you enjoy — that still counts.',
      );
    }

    final calRatio =
        calorieGoal <= 0 ? 0.5 : (caloriesConsumed / calorieGoal).clamp(0.0, 1.6);
    final proteinRatio =
        proteinGoalG <= 0 ? 0.5 : (proteinG / proteinGoalG).clamp(0.0, 1.5);

    // Under-fueled → shorter session; well-fueled → full work; surplus → more cardio option.
    var minutes = switch (goal) {
      FitnessGoalHint.cut => 35,
      FitnessGoalHint.muscle => 45,
      FitnessGoalHint.endurance => 40,
      FitnessGoalHint.maintain => 30,
    };

    if (calRatio < 0.35 && DateTime.now().hour >= 14) {
      minutes = (minutes * 0.65).round();
    } else if (calRatio > 1.05) {
      minutes = (minutes * 1.1).round().clamp(25, 55);
    }

    if (readinessScore < 45) {
      minutes = (minutes * 0.7).round().clamp(15, 35);
    } else if (readinessScore >= 75 && proteinRatio >= 0.5) {
      minutes = (minutes * 1.05).round().clamp(20, 60);
    }

    final focus = readinessScore < 45
        ? 'Mobility + easy cardio'
        : goal == FitnessGoalHint.muscle
            ? (proteinRatio < 0.4 ? 'Full body (moderate)' : 'Strength focus')
            : goal == FitnessGoalHint.cut
                ? (calRatio > 1.0 ? 'Metabolic + strength' : 'Strength + zone-2')
                : goal == FitnessGoalHint.endurance
                    ? 'Cardio + core'
                    : 'Full body';

    final exercises = <String>[];
    if (focus.contains('Strength') || focus.contains('Full body')) {
      exercises.addAll(const [
        'Squat / hinge pattern',
        'Push (press or push-up)',
        'Pull (row)',
        'Carry or core finisher',
      ]);
    }
    if (focus.contains('Metabolic') || focus.contains('zone-2') || focus.contains('Cardio')) {
      exercises.addAll(const [
        'Zone-2 cardio block',
        'Short intervals (optional)',
      ]);
    }
    if (focus.contains('Mobility')) {
      exercises.addAll(const [
        'Hip + thoracic mobility',
        'Easy walk or cycle',
      ]);
    }
    if (exercises.isEmpty) {
      exercises.addAll(const ['Full-body circuit', 'Core', 'Cool-down walk']);
    }

    final sport = _pickSport(preferredSports, goal, calRatio);
    final sportReason = sport == null
        ? 'Add sports you like in Account → Sports — Bot will prefer those.'
        : switch (sport) {
            ActivityType.swim =>
              'Swimming fits your prefs and burns well without joint stress — ${minutes.clamp(20, 45)} min is enough.',
            ActivityType.dance =>
              'Dancing counts as real training. Aim for ${minutes.clamp(25, 50)} min at a pace that raises your heart rate.',
            ActivityType.cycle =>
              'Cycling matches your preference — use it for the cardio block today.',
            ActivityType.yoga =>
              'Yoga supports recovery and mobility on this fuel level.',
            ActivityType.run =>
              'A run you enjoy beats a gym session you dread — keep easy if fuel is low.',
            _ =>
              '${sport.label} is on your list — swap it in for part of today’s work if that keeps you consistent.',
          };

    final reason = calRatio < 0.35
        ? 'Fuel is still low (${caloriesConsumed}/$calorieGoal kcal). Shorter session protects performance.'
        : calRatio > 1.05
            ? 'Intake is above target — keep strength, add a bit more cardio to balance the day.'
            : proteinRatio < 0.45
                ? 'Protein is behind (${proteinG.toStringAsFixed(0)} g). Train moderately and prioritise a protein meal after.'
                : 'Fuel looks solid for a ${minutes}-minute $focus session.';

    return FoodAwareTrainingAdvice(
      gymMinutes: minutes,
      focus: focus,
      exerciseTypes: exercises.take(5).toList(),
      reason: reason,
      suggestedSport: sport,
      sportReason: sportReason,
    );
  }

  static ActivityType? _pickSport(
    List<ActivityType> prefs,
    FitnessGoalHint goal,
    double calRatio,
  ) {
    if (prefs.isEmpty) {
      if (goal == FitnessGoalHint.cut && calRatio > 0.9) return ActivityType.swim;
      return null;
    }
    // Prefer enjoyable cardio when surplus; otherwise first preference.
    if (calRatio > 1.05) {
      for (final p in prefs) {
        if (p == ActivityType.swim ||
            p == ActivityType.dance ||
            p == ActivityType.cycle ||
            p == ActivityType.run) {
          return p;
        }
      }
    }
    return prefs.first;
  }
}
