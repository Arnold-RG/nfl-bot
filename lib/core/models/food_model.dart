// Food and nutrition domain models

class FoodItem {
  final String id;
  final String name;
  final String brand;
  final double servingSizeG;
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;
  final Map<String, double> vitamins; // A, C, D, B12, etc.
  final Map<String, double> minerals; // Iron, Calcium, etc.

  FoodItem({
    required this.id,
    required this.name,
    required this.brand,
    required this.servingSizeG,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
    required this.vitamins,
    required this.minerals,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String? ?? 'Generic',
      servingSizeG: (json['serving_size_g'] as num).toDouble(),
      calories: json['calories'] as int,
      proteinG: (json['protein_g'] as num).toDouble(),
      carbsG: (json['carbs_g'] as num).toDouble(),
      fatG: (json['fat_g'] as num).toDouble(),
      fiberG: (json['fiber_g'] as num).toDouble(),
      vitamins: Map<String, double>.from(
        (json['vitamins'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
      ),
      minerals: Map<String, double>.from(
        (json['minerals'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'brand': brand,
    'serving_size_g': servingSizeG,
    'calories': calories,
    'protein_g': proteinG,
    'carbs_g': carbsG,
    'fat_g': fatG,
    'fiber_g': fiberG,
    'vitamins': vitamins,
    'minerals': minerals,
  };
}

class MealLog {
  final String id;
  final String userId;
  final DateTime timestamp;
  final String type; // 'breakfast', 'lunch', 'dinner', 'snack'
  final List<MealLogItem> items;

  MealLog({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.type,
    required this.items,
  });

  int get totalCalories => items.fold(0, (sum, item) => sum + item.calories);
  double get totalProteinG =>
      items.fold(0.0, (sum, item) => sum + item.proteinG);
  double get totalCarbsG => items.fold(0.0, (sum, item) => sum + item.carbsG);
  double get totalFatG => items.fold(0.0, (sum, item) => sum + item.fatG);

  factory MealLog.fromJson(Map<String, dynamic> json) {
    return MealLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: json['type'] as String,
      items:
          (json['items'] as List?)
              ?.map((e) => MealLogItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'timestamp': timestamp.toIso8601String(),
    'type': type,
    'items': items.map((e) => e.toJson()).toList(),
  };
}

class MealLogItem {
  final String id;
  final String foodItemId;
  final String foodName;
  final double quantityG;
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;

  /// When the user actually logged this, so the UI never has to guess.
  final DateTime loggedAt;

  MealLogItem({
    required this.id,
    required this.foodItemId,
    required this.foodName,
    required this.quantityG,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    DateTime? loggedAt,
  }) : loggedAt = loggedAt ?? DateTime.now();

  factory MealLogItem.fromJson(Map<String, dynamic> json) {
    return MealLogItem(
      id: json['id'] as String,
      foodItemId: json['food_item_id'] as String,
      foodName: json['food_name'] as String,
      quantityG: (json['quantity_g'] as num).toDouble(),
      calories: json['calories'] as int,
      proteinG: (json['protein_g'] as num).toDouble(),
      carbsG: (json['carbs_g'] as num).toDouble(),
      fatG: (json['fat_g'] as num).toDouble(),
      loggedAt: json['logged_at'] != null
          ? DateTime.parse(json['logged_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'food_item_id': foodItemId,
    'food_name': foodName,
    'quantity_g': quantityG,
    'calories': calories,
    'protein_g': proteinG,
    'carbs_g': carbsG,
    'fat_g': fatG,
    'logged_at': loggedAt.toIso8601String(),
  };
}

class DailySummary {
  final String id;
  final String userId;
  final DateTime date;
  final int totalCalories;
  final double totalProteinG;
  final double totalCarbsG;
  final double totalFatG;
  final int targetCalories;
  final double targetProteinG;
  final double targetCarbsG;
  final double targetFatG;

  DailySummary({
    required this.id,
    required this.userId,
    required this.date,
    required this.totalCalories,
    required this.totalProteinG,
    required this.totalCarbsG,
    required this.totalFatG,
    required this.targetCalories,
    required this.targetProteinG,
    required this.targetCarbsG,
    required this.targetFatG,
  });

  double get caloriePercent => totalCalories / targetCalories;
  double get proteinPercent => totalProteinG / targetProteinG;
  double get carbsPercent => totalCarbsG / targetCarbsG;
  double get fatPercent => totalFatG / targetFatG;

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      totalCalories: json['total_calories'] as int,
      totalProteinG: (json['total_protein_g'] as num).toDouble(),
      totalCarbsG: (json['total_carbs_g'] as num).toDouble(),
      totalFatG: (json['total_fat_g'] as num).toDouble(),
      targetCalories: json['target_calories'] as int,
      targetProteinG: (json['target_protein_g'] as num).toDouble(),
      targetCarbsG: (json['target_carbs_g'] as num).toDouble(),
      targetFatG: (json['target_fat_g'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'date': date.toIso8601String(),
    'total_calories': totalCalories,
    'total_protein_g': totalProteinG,
    'total_carbs_g': totalCarbsG,
    'total_fat_g': totalFatG,
    'target_calories': targetCalories,
    'target_protein_g': targetProteinG,
    'target_carbs_g': targetCarbsG,
    'target_fat_g': targetFatG,
  };
}
