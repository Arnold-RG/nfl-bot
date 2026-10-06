/// Adaptive nutrition coach — what to eat next, protein/vitamins, skip/overeat recovery.
library;

enum MealSlot { breakfast, lunch, dinner, snack }

enum MealSlotStatus { pending, logged, skipped }

class MealSuggestion {
  final String title;
  final String reason;
  final int calories;
  final double proteinG;
  final String vitaminsHint;
  final List<String> plate;

  const MealSuggestion({
    required this.title,
    required this.reason,
    required this.calories,
    required this.proteinG,
    required this.vitaminsHint,
    required this.plate,
  });
}

class NutritionDayPlan {
  final int caloriesLeft;
  final double proteinLeftG;
  final bool overTarget;
  final bool hadSkip;
  final String headline;
  final String coachNote;
  final List<MealSuggestion> suggestions;
  final Map<String, double> vitaminFocus; // A, C, D, iron, etc. as relative need 0–1

  const NutritionDayPlan({
    required this.caloriesLeft,
    required this.proteinLeftG,
    required this.overTarget,
    required this.hadSkip,
    required this.headline,
    required this.coachNote,
    required this.suggestions,
    required this.vitaminFocus,
  });
}

class NutritionPlanEngine {
  NutritionPlanEngine._();

  static NutritionDayPlan build({
    required int calorieGoal,
    required int caloriesConsumed,
    required double proteinGoalG,
    required double proteinConsumedG,
    required int mealsLogged,
    required Set<MealSlot> skippedSlots,
    required FitnessGoalHint goal,
    Set<String> dietPrefs = const {},
  }) {
    final calLeft = calorieGoal - caloriesConsumed;
    final proteinLeft = (proteinGoalG - proteinConsumedG).clamp(0.0, 999.0);
    final over = calLeft < 0;
    final hadSkip = skippedSlots.isNotEmpty;
    final hour = DateTime.now().hour;

    final vitaminFocus = <String, double>{
      'C': mealsLogged == 0 ? 0.9 : 0.45,
      'D': 0.55,
      'Iron': goal == FitnessGoalHint.cut || goal == FitnessGoalHint.muscle
          ? 0.7
          : 0.4,
      'A': 0.35,
      'B12': proteinLeft > 40 ? 0.6 : 0.3,
    };

    final suggestions = <MealSuggestion>[];

    if (over) {
      suggestions.addAll(_overeatAlternatives(proteinLeft, dietPrefs));
    } else if (hadSkip) {
      suggestions.addAll(
        _skipRecovery(
          caloriesLeft: calLeft.clamp(0, 9999),
          proteinLeft: proteinLeft,
          skipped: skippedSlots,
          dietPrefs: dietPrefs,
        ),
      );
    } else {
      suggestions.addAll(
        _nextMeals(
          caloriesLeft: calLeft.clamp(0, 9999),
          proteinLeft: proteinLeft,
          hour: hour,
          mealsLogged: mealsLogged,
          goal: goal,
          dietPrefs: dietPrefs,
        ),
      );
    }

    final headline = over
        ? 'Over target — lighter alternatives'
        : hadSkip
            ? 'Meal skipped — catch-up plate'
            : mealsLogged == 0
                ? 'What to eat today'
                : 'Next plate for your goal';

    final coachNote = over
        ? 'You went ${(-calLeft)} kcal over. Not a failed day — close with water, a walk, and a protein-forward light option below. Tomorrow resets.'
        : hadSkip
            ? 'You skipped ${skippedSlots.map((s) => s.name).join(', ')}. I redistributed the remaining budget into denser plates so protein and vitamins still land.'
            : 'Aim for ~${proteinLeft.round()} g protein and ${calLeft.clamp(0, 9999)} kcal left. Plates below also cover vitamins C, D, iron, and B12 from food first.';

    return NutritionDayPlan(
      caloriesLeft: calLeft,
      proteinLeftG: proteinLeft,
      overTarget: over,
      hadSkip: hadSkip,
      headline: headline,
      coachNote: coachNote,
      suggestions: suggestions.take(3).toList(),
      vitaminFocus: vitaminFocus,
    );
  }

  static List<MealSuggestion> _nextMeals({
    required int caloriesLeft,
    required double proteinLeft,
    required int hour,
    required int mealsLogged,
    required FitnessGoalHint goal,
    required Set<String> dietPrefs,
  }) {
    final veg = dietPrefs.contains('vegan') || dietPrefs.contains('vegetarian');
    final budget = caloriesLeft <= 0
        ? 350
        : (caloriesLeft / (mealsLogged >= 2 ? 1 : (hour < 14 ? 2 : 1)))
            .round()
            .clamp(280, 750);

    if (hour < 11 || mealsLogged == 0) {
      return [
        MealSuggestion(
          title: veg ? 'Tofu scramble + fruit' : 'Eggs + oats + berries',
          reason: 'Morning protein + fibre to steady energy for your ${goal.label}.',
          calories: budget.clamp(320, 520),
          proteinG: veg ? 28 : 32,
          vitaminsHint: 'Vitamins C · B12 · iron',
          plate: veg
              ? ['Firm tofu', 'Spinach', 'Tomato', 'Berries']
              : ['2–3 eggs', 'Oats', 'Berries', 'Greek yoghurt'],
        ),
        MealSuggestion(
          title: veg ? 'Protein smoothie bowl' : 'Greek yoghurt bowl',
          reason: 'Fast plate when time is short — still hits protein.',
          calories: (budget * 0.85).round().clamp(280, 450),
          proteinG: 30,
          vitaminsHint: 'Vitamin D · calcium · C',
          plate: ['Yoghurt or soy yoghurt', 'Banana', 'Seeds', 'Berries'],
        ),
      ];
    }

    if (hour < 16) {
      return [
        MealSuggestion(
          title: veg ? 'Lentil bowl + greens' : 'Chicken rice bowl',
          reason: 'Midday fuel: protein first, then carbs for training later.',
          calories: budget.clamp(400, 650),
          proteinG: veg ? 34 : 42,
          vitaminsHint: 'Iron · B12 · vitamin A',
          plate: veg
              ? ['Lentils', 'Brown rice', 'Broccoli', 'Olive oil']
              : ['Chicken breast', 'Rice', 'Broccoli', 'Olive oil'],
        ),
        MealSuggestion(
          title: veg ? 'Chickpea wrap' : 'Tuna wrap + salad',
          reason: 'Portable lunch that protects the protein target.',
          calories: (budget * 0.9).round().clamp(380, 580),
          proteinG: veg ? 28 : 38,
          vitaminsHint: 'Vitamin C · iron',
          plate: veg
              ? ['Chickpeas', 'Whole wrap', 'Pepper', 'Hummus']
              : ['Tuna', 'Whole wrap', 'Salad', 'Lemon'],
        ),
      ];
    }

    return [
      MealSuggestion(
        title: veg ? 'Tempeh stir-fry' : 'Salmon + vegetables',
        reason: proteinLeft > 40
            ? 'Dinner closes a large protein gap (~${proteinLeft.round()} g left).'
            : 'Balanced dinner for recovery and tomorrow’s readiness.',
        calories: budget.clamp(380, 620),
        proteinG: veg ? 36 : 40,
        vitaminsHint: 'Vitamin D · omega-3 · C',
        plate: veg
            ? ['Tempeh', 'Mixed veg', 'Quinoa']
            : ['Salmon', 'Greens', 'Sweet potato'],
      ),
      MealSuggestion(
        title: veg ? 'Bean chilli' : 'Lean beef + salad',
        reason: 'Alternative if you prefer hearty evening meals.',
        calories: (budget * 0.95).round().clamp(400, 640),
        proteinG: veg ? 32 : 44,
        vitaminsHint: 'Iron · B12 · vitamin A',
        plate: veg
            ? ['Black beans', 'Tomato', 'Peppers', 'Rice']
            : ['Lean beef', 'Salad', 'Potato'],
      ),
    ];
  }

  static List<MealSuggestion> _skipRecovery({
    required int caloriesLeft,
    required double proteinLeft,
    required Set<MealSlot> skipped,
    required Set<String> dietPrefs,
  }) {
    final veg = dietPrefs.contains('vegan') || dietPrefs.contains('vegetarian');
    final dense = caloriesLeft.clamp(450, 800);
    return [
      MealSuggestion(
        title: veg ? 'Dense tofu rice plate' : 'Dense chicken plate',
        reason:
            'Catch-up after skipping ${skipped.map((s) => s.name).join('/')}: higher protein density in one sitting.',
        calories: dense,
        proteinG: (proteinLeft * 0.7).clamp(35, 55),
        vitaminsHint: 'Iron · B12 · vitamin C',
        plate: veg
            ? ['Extra tofu', 'Rice', 'Greens', 'Nuts']
            : ['Extra chicken', 'Rice', 'Greens', 'Fruit'],
      ),
      MealSuggestion(
        title: 'Protein + fruit rescue',
        reason: 'If a full meal is hard, this recovers protein and vitamin C quickly.',
        calories: (dense * 0.55).round().clamp(250, 420),
        proteinG: 28,
        vitaminsHint: 'Vitamin C · D',
        plate: veg
            ? ['Soy yoghurt', 'Protein powder', 'Orange']
            : ['Greek yoghurt', 'Whey / milk', 'Orange'],
      ),
    ];
  }

  static List<MealSuggestion> _overeatAlternatives(
    double proteinLeft,
    Set<String> dietPrefs,
  ) {
    final veg = dietPrefs.contains('vegan') || dietPrefs.contains('vegetarian');
    return [
      MealSuggestion(
        title: 'Light protein close',
        reason: 'Stay under extra calories while still feeding muscle recovery.',
        calories: 180,
        proteinG: proteinLeft > 15 ? 25 : 18,
        vitaminsHint: 'Vitamin D · calcium',
        plate: veg
            ? ['Soy yoghurt', 'Cucumber', 'Tea']
            : ['Greek yoghurt', 'Cucumber', 'Tea'],
      ),
      MealSuggestion(
        title: 'Broth + greens',
        reason: 'Volume without a second surplus — helps you feel finished.',
        calories: 120,
        proteinG: 8,
        vitaminsHint: 'Vitamin A · C',
        plate: ['Clear broth', 'Leafy greens', 'Lemon'],
      ),
      MealSuggestion(
        title: 'Walk + water instead',
        reason: 'Best “alternative” after a surplus: 15–20 min walk, no more food needed.',
        calories: 0,
        proteinG: 0,
        vitaminsHint: 'Hydration · movement',
        plate: ['Water', '10–20 min walk'],
      ),
    ];
  }
}

/// Lightweight goal hint so the engine stays free of Flutter/UI imports.
enum FitnessGoalHint { maintain, muscle, cut, endurance }

extension FitnessGoalHintLabel on FitnessGoalHint {
  String get label => switch (this) {
        FitnessGoalHint.maintain => 'maintain goal',
        FitnessGoalHint.muscle => 'muscle goal',
        FitnessGoalHint.cut => 'fat-loss goal',
        FitnessGoalHint.endurance => 'endurance goal',
      };
}
