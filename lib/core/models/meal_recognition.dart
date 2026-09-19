import 'food_model.dart';

/// One food the model identified in a photo.
class RecognizedFood {
  final String name;
  final double portionG;
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;

  const RecognizedFood({
    required this.name,
    required this.portionG,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.fiberG = 0,
  });

  FoodItem toFoodItem() => FoodItem(
    id: 'vision_${DateTime.now().microsecondsSinceEpoch}',
    name: name,
    brand: 'Photo estimate',
    servingSizeG: portionG,
    calories: calories,
    proteinG: proteinG,
    carbsG: carbsG,
    fatG: fatG,
    fiberG: fiberG,
    vitamins: const {},
    minerals: const {},
  );

  factory RecognizedFood.fromJson(Map<String, dynamic> json) {
    double num_(String key) => (json[key] as num?)?.toDouble() ?? 0;
    return RecognizedFood(
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? (json['name'] as String).trim()
          : 'Unidentified food',
      portionG: num_('portion_g'),
      calories: ((json['calories'] as num?)?.toDouble() ?? 0).round(),
      proteinG: num_('protein_g'),
      carbsG: num_('carbs_g'),
      fatG: num_('fat_g'),
      fiberG: num_('fiber_g'),
    );
  }

  RecognizedFood copyWith({
    String? name,
    double? portionG,
    int? calories,
    double? proteinG,
    double? carbsG,
    double? fatG,
    double? fiberG,
  }) {
    return RecognizedFood(
      name: name ?? this.name,
      portionG: portionG ?? this.portionG,
      calories: calories ?? this.calories,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      fiberG: fiberG ?? this.fiberG,
    );
  }

  /// Scale macros when the user corrects portion size.
  RecognizedFood scaledToPortion(double newPortionG) {
    if (portionG <= 0 || newPortionG <= 0) {
      return copyWith(portionG: newPortionG);
    }
    final f = newPortionG / portionG;
    return RecognizedFood(
      name: name,
      portionG: newPortionG,
      calories: (calories * f).round(),
      proteinG: proteinG * f,
      carbsG: carbsG * f,
      fatG: fatG * f,
      fiberG: fiberG * f,
    );
  }
}

/// Outcome of a meal photo analysis. Carries its own failure reason so the UI
/// can be honest about what happened instead of inventing a result.
class MealRecognition {
  final List<RecognizedFood> items;
  final String? insight;

  /// Set when analysis could not run or produced nothing usable.
  final String? failure;

  const MealRecognition({
    this.items = const [],
    this.insight,
    this.failure,
  });

  const MealRecognition.failed(String reason)
    : items = const [],
      insight = null,
      failure = reason;

  bool get succeeded => failure == null && items.isNotEmpty;

  int get totalCalories => items.fold(0, (sum, i) => sum + i.calories);
  double get totalProteinG => items.fold(0.0, (sum, i) => sum + i.proteinG);
  double get totalCarbsG => items.fold(0.0, (sum, i) => sum + i.carbsG);
  double get totalFatG => items.fold(0.0, (sum, i) => sum + i.fatG);

  MealRecognition copyWith({
    List<RecognizedFood>? items,
    String? insight,
    String? failure,
  }) {
    return MealRecognition(
      items: items ?? this.items,
      insight: insight ?? this.insight,
      failure: failure,
    );
  }

  /// Combines a multi-item plate into a single loggable entry.
  FoodItem asSingleEntry() {
    if (items.length == 1) return items.first.toFoodItem();
    return FoodItem(
      id: 'vision_${DateTime.now().microsecondsSinceEpoch}',
      name: items.map((i) => i.name).join(', '),
      brand: 'Photo estimate',
      servingSizeG: items.fold(0.0, (sum, i) => sum + i.portionG),
      calories: totalCalories,
      proteinG: totalProteinG,
      carbsG: totalCarbsG,
      fatG: totalFatG,
      fiberG: items.fold(0.0, (sum, i) => sum + i.fiberG),
      vitamins: const {},
      minerals: const {},
    );
  }
}
