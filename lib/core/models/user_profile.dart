import '../utils/fitness_calculator.dart';

enum BiologicalSex { male, female }

enum ActivityLevel { sedentary, light, moderate, active, athlete }

enum FitnessGoal { maintain, muscle, cut, endurance }

extension BiologicalSexLabel on BiologicalSex {
  String get label => this == BiologicalSex.male ? 'Male' : 'Female';
}

extension ActivityLevelLabel on ActivityLevel {
  String get label => switch (this) {
    ActivityLevel.sedentary => 'Sedentary',
    ActivityLevel.light => 'Lightly active',
    ActivityLevel.moderate => 'Moderately active',
    ActivityLevel.active => 'Very active',
    ActivityLevel.athlete => 'Athlete',
  };

  String get description => switch (this) {
    ActivityLevel.sedentary => 'Desk job, little deliberate exercise',
    ActivityLevel.light => 'Light movement or exercise 1-3 days a week',
    ActivityLevel.moderate => 'Exercise 3-5 days a week',
    ActivityLevel.active => 'Hard exercise 6-7 days a week',
    ActivityLevel.athlete => 'Twice-daily training or physical job',
  };

  /// Daily step target that matches this activity level.
  int get stepGoal => switch (this) {
    ActivityLevel.sedentary => 6000,
    ActivityLevel.light => 8000,
    ActivityLevel.moderate => 10000,
    ActivityLevel.active => 12000,
    ActivityLevel.athlete => 14000,
  };
}

extension FitnessGoalLabel on FitnessGoal {
  String get label => switch (this) {
    FitnessGoal.maintain => 'Maintain weight',
    FitnessGoal.muscle => 'Build muscle',
    FitnessGoal.cut => 'Lose fat',
    FitnessGoal.endurance => 'Build endurance',
  };

  /// Calories added to (or removed from) maintenance to reach the goal.
  /// Deliberately conservative: roughly 0.25-0.5 kg per week.
  int get calorieOffset => switch (this) {
    FitnessGoal.maintain => 0,
    FitnessGoal.muscle => 250,
    FitnessGoal.cut => -450,
    FitnessGoal.endurance => 100,
  };
}

/// Nutrition and activity targets derived from the user's own body metrics
/// rather than one-size-fits-all constants.
class DailyTargets {
  final int maintenanceCalories;
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double waterLiters;
  final int stepGoal;

  const DailyTargets({
    required this.maintenanceCalories,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.waterLiters,
    required this.stepGoal,
  });
}

/// The body metrics the app needs before any of its numbers mean anything.
class UserProfile {
  final BiologicalSex sex;
  final int age;
  final double heightCm;
  final double weightKg;
  final ActivityLevel activity;
  final FitnessGoal goal;

  /// False until the user has actually entered their metrics, so the UI can
  /// prompt instead of presenting defaults as if they were real.
  final bool isComplete;

  const UserProfile({
    required this.sex,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.activity,
    required this.goal,
    this.isComplete = true,
  });

  /// Placeholder used only until onboarding collects the real values.
  static const UserProfile empty = UserProfile(
    sex: BiologicalSex.male,
    age: 30,
    heightCm: 175,
    weightKg: 75,
    activity: ActivityLevel.moderate,
    goal: FitnessGoal.maintain,
    isComplete: false,
  );

  double get bmi => FitnessCalculator.bmi(weightKg, heightCm);
  String get bmiCategory => FitnessCalculator.bmiCategory(bmi);

  DailyTargets get targets {
    final maintenance = FitnessCalculator.dailyCalories(
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      gender: sex.name,
      activity: activity.name,
    );

    // Never prescribe below the floor considered safe without supervision.
    final floor = sex == BiologicalSex.male ? 1500 : 1200;
    final target = (maintenance + goal.calorieOffset).clamp(floor, 6000);
    final macros = FitnessCalculator.macroSplit(target, goal.name);

    return DailyTargets(
      maintenanceCalories: maintenance,
      calories: target,
      proteinG: macros['protein']!,
      carbsG: macros['carbs']!,
      fatG: macros['fat']!,
      waterLiters: FitnessCalculator.waterGoalMl(weightKg, 'normal') / 1000,
      stepGoal: activity.stepGoal,
    );
  }

  UserProfile copyWith({
    BiologicalSex? sex,
    int? age,
    double? heightCm,
    double? weightKg,
    ActivityLevel? activity,
    FitnessGoal? goal,
    bool? isComplete,
  }) {
    return UserProfile(
      sex: sex ?? this.sex,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      activity: activity ?? this.activity,
      goal: goal ?? this.goal,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  Map<String, dynamic> toJson() => {
    'sex': sex.name,
    'age': age,
    'height_cm': heightCm,
    'weight_kg': weightKg,
    'activity': activity.name,
    'goal': goal.name,
    'is_complete': isComplete,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      sex: BiologicalSex.values.firstWhere(
        (e) => e.name == json['sex'],
        orElse: () => BiologicalSex.male,
      ),
      age: (json['age'] as num?)?.toInt() ?? 30,
      heightCm: (json['height_cm'] as num?)?.toDouble() ?? 175,
      weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 75,
      activity: ActivityLevel.values.firstWhere(
        (e) => e.name == json['activity'],
        orElse: () => ActivityLevel.moderate,
      ),
      goal: FitnessGoal.values.firstWhere(
        (e) => e.name == json['goal'],
        orElse: () => FitnessGoal.maintain,
      ),
      isComplete: json['is_complete'] as bool? ?? true,
    );
  }
}
