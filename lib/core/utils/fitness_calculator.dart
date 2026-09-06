/// Unique fitness & wellness calculators not found in typical apps.
class FitnessCalculator {
  static double bmi(double weightKg, double heightCm) {
    final m = heightCm / 100;
    return weightKg / (m * m);
  }

  static String bmiCategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Healthy';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  /// Mifflin-St Jeor equation for daily calories.
  static int dailyCalories({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
    required String activity,
  }) {
    double bmr;
    if (gender == 'male') {
      bmr = 10 * weightKg + 6.25 * heightCm - 5 * age + 5;
    } else {
      bmr = 10 * weightKg + 6.25 * heightCm - 5 * age - 161;
    }
    final multipliers = {
      'sedentary': 1.2,
      'light': 1.375,
      'moderate': 1.55,
      'active': 1.725,
      'athlete': 1.9,
    };
    return (bmr * (multipliers[activity] ?? 1.55)).round();
  }

  static Map<String, double> macroSplit(int calories, String goal) {
    final splits = switch (goal) {
      'muscle' => {'protein': 0.30, 'carbs': 0.45, 'fat': 0.25},
      'cut' => {'protein': 0.35, 'carbs': 0.35, 'fat': 0.30},
      'endurance' => {'protein': 0.20, 'carbs': 0.55, 'fat': 0.25},
      _ => {'protein': 0.25, 'carbs': 0.50, 'fat': 0.25},
    };
    return {
      'protein': calories * splits['protein']! / 4,
      'carbs': calories * splits['carbs']! / 4,
      'fat': calories * splits['fat']! / 9,
    };
  }

  static int waterGoalMl(double weightKg, String climate) {
    final base = weightKg * 35;
    return climate == 'hot' ? (base * 1.2).round() : base.round();
  }

  static int sleepScore(int hours, int qualityPercent) {
    final hourScore = hours >= 7 && hours <= 9 ? 100 : (hours * 12).clamp(40, 90);
    return ((hourScore + qualityPercent) / 2).round();
  }
}
