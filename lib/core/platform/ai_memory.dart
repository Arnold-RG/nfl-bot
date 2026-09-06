/// Soft personalization memory — not medical records.
/// Users can reset this from Privacy controls.
class AiMemory {
  final Set<String> dislikedFoods = {};
  final Set<String> allergies = {};
  String? preferredTrainingWindow; // morning | afternoon | evening
  final List<int> usualTrainingWeekdays = [];
  bool eveningWorkouts = true;

  void apply(Map<String, dynamic> payload) {
    final dislike = payload['dislike_food'] as String?;
    if (dislike != null && dislike.trim().isNotEmpty) {
      dislikedFoods.add(dislike.trim().toLowerCase());
    }
    final allergy = payload['allergy'] as String?;
    if (allergy != null && allergy.trim().isNotEmpty) {
      allergies.add(allergy.trim().toLowerCase());
    }
    final window = payload['training_window'] as String?;
    if (window != null) preferredTrainingWindow = window;
    if (payload['evening_workouts'] is bool) {
      eveningWorkouts = payload['evening_workouts'] as bool;
    }
  }

  void reset() {
    dislikedFoods.clear();
    allergies.clear();
    preferredTrainingWindow = null;
    usualTrainingWeekdays.clear();
    eveningWorkouts = true;
  }

  Map<String, dynamic> toJson() => {
        'disliked_foods': dislikedFoods.toList(),
        'allergies': allergies.toList(),
        'preferred_training_window': preferredTrainingWindow,
        'usual_training_weekdays': usualTrainingWeekdays,
        'evening_workouts': eveningWorkouts,
      };

  String promptBlock() {
    final lines = <String>[];
    if (dislikedFoods.isNotEmpty) {
      lines.add('Avoid foods: ${dislikedFoods.join(', ')}');
    }
    if (allergies.isNotEmpty) {
      lines.add('ALLERGIES (hard restriction): ${allergies.join(', ')}');
    }
    if (preferredTrainingWindow != null) {
      lines.add('Preferred training window: $preferredTrainingWindow');
    }
    return lines.isEmpty ? 'No stored preferences yet.' : lines.join('\n');
  }
}
