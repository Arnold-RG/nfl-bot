/// Home workout exercises requiring zero gym equipment.
class Exercise {
  final String name;
  final String muscleGroup;
  final int durationSec;
  final int reps;
  final String instructions;
  final String difficulty;
  final int caloriesBurn;

  const Exercise({
    required this.name,
    required this.muscleGroup,
    required this.durationSec,
    required this.reps,
    required this.instructions,
    required this.difficulty,
    required this.caloriesBurn,
  });
}

class WorkoutPlan {
  final String id;
  final String title;
  final String description;
  final int totalMinutes;
  final int totalCalories;
  final List<Exercise> exercises;
  final String focus;

  const WorkoutPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.totalMinutes,
    required this.totalCalories,
    required this.exercises,
    required this.focus,
  });
}

class WorkoutDatabase {
  static const List<Exercise> allExercises = [
    Exercise(
      name: 'Jumping Jacks',
      muscleGroup: 'Full body',
      durationSec: 45,
      reps: 0,
      instructions:
          'Feet together, arms at sides. Jump while spreading legs and raising arms overhead. Return and repeat.',
      difficulty: 'Easy',
      caloriesBurn: 45,
    ),
    Exercise(
      name: 'Push-ups',
      muscleGroup: 'Chest, Triceps, Core',
      durationSec: 0,
      reps: 15,
      instructions:
          'Hands shoulder-width, body straight plank. Lower chest to floor, push back up. Knee modification OK.',
      difficulty: 'Medium',
      caloriesBurn: 35,
    ),
    Exercise(
      name: 'Bodyweight Squats',
      muscleGroup: 'Quads, Glutes',
      durationSec: 0,
      reps: 20,
      instructions:
          'Feet hip-width, chest up. Sit back as if into a chair, thighs parallel to floor, drive through heels.',
      difficulty: 'Easy',
      caloriesBurn: 40,
    ),
    Exercise(
      name: 'Plank Hold',
      muscleGroup: 'Core',
      durationSec: 45,
      reps: 0,
      instructions:
          'Forearms on floor, body straight line head to heels. Squeeze glutes, don\'t let hips sag.',
      difficulty: 'Medium',
      caloriesBurn: 25,
    ),
    Exercise(
      name: 'Lunges',
      muscleGroup: 'Legs, Glutes',
      durationSec: 0,
      reps: 12,
      instructions:
          'Step forward, lower back knee toward floor. Front knee over ankle. Alternate legs.',
      difficulty: 'Medium',
      caloriesBurn: 35,
    ),
    Exercise(
      name: 'Mountain Climbers',
      muscleGroup: 'Core, Cardio',
      durationSec: 30,
      reps: 0,
      instructions:
          'Plank position. Drive knees alternately toward chest rapidly. Keep core tight.',
      difficulty: 'Hard',
      caloriesBurn: 50,
    ),
    Exercise(
      name: 'Burpees',
      muscleGroup: 'Full body',
      durationSec: 0,
      reps: 10,
      instructions:
          'Squat, jump feet back to plank, push-up optional, jump feet forward, explosive jump up.',
      difficulty: 'Hard',
      caloriesBurn: 60,
    ),
    Exercise(
      name: 'Glute Bridges',
      muscleGroup: 'Glutes, Hamstrings',
      durationSec: 0,
      reps: 15,
      instructions:
          'Lie on back, knees bent. Drive hips up squeezing glutes at top. Lower with control.',
      difficulty: 'Easy',
      caloriesBurn: 20,
    ),
    Exercise(
      name: 'High Knees',
      muscleGroup: 'Cardio, Hip flexors',
      durationSec: 30,
      reps: 0,
      instructions:
          'Run in place driving knees to hip height. Pump arms. Land on balls of feet.',
      difficulty: 'Medium',
      caloriesBurn: 40,
    ),
    Exercise(
      name: 'Tricep Dips (Chair)',
      muscleGroup: 'Triceps',
      durationSec: 0,
      reps: 12,
      instructions:
          'Hands on chair edge behind you. Lower body by bending elbows to 90°, push back up.',
      difficulty: 'Medium',
      caloriesBurn: 25,
    ),
    Exercise(
      name: 'Bicycle Crunches',
      muscleGroup: 'Abs, Obliques',
      durationSec: 0,
      reps: 20,
      instructions:
          'Lie on back, hands behind head. Bring opposite elbow to knee alternately in cycling motion.',
      difficulty: 'Medium',
      caloriesBurn: 30,
    ),
    Exercise(
      name: 'Wall Sit',
      muscleGroup: 'Quads',
      durationSec: 45,
      reps: 0,
      instructions:
          'Back against wall, slide down until thighs parallel. Hold. Breathe steadily.',
      difficulty: 'Hard',
      caloriesBurn: 30,
    ),
    Exercise(
      name: 'Superman Hold',
      muscleGroup: 'Lower back',
      durationSec: 30,
      reps: 0,
      instructions:
          'Lie face down, arms extended. Lift arms, chest, and legs off floor simultaneously. Hold.',
      difficulty: 'Easy',
      caloriesBurn: 15,
    ),
    Exercise(
      name: 'Side Plank',
      muscleGroup: 'Obliques',
      durationSec: 30,
      reps: 0,
      instructions:
          'On side, forearm down, body straight. Hold hips elevated. Switch sides.',
      difficulty: 'Medium',
      caloriesBurn: 20,
    ),
    Exercise(
      name: 'Calf Raises',
      muscleGroup: 'Calves',
      durationSec: 0,
      reps: 20,
      instructions:
          'Stand tall, rise onto toes, hold 1 sec, lower slowly. Use stairs edge for extra range.',
      difficulty: 'Easy',
      caloriesBurn: 15,
    ),
  ];

  static WorkoutPlan generateDailyWorkout({
    String focus = 'Full Body',
    int targetMinutes = 25,
    String fitnessLevel = 'Medium',
  }) {
    final shuffled = List<Exercise>.from(allExercises)..shuffle();
    final selected = <Exercise>[];
    var minutes = 0;
    var calories = 0;

    for (final ex in shuffled) {
      if (minutes >= targetMinutes) break;
      if (fitnessLevel == 'Easy' && ex.difficulty == 'Hard') continue;
      selected.add(ex);
      minutes += ex.durationSec > 0 ? (ex.durationSec / 60).ceil() : 2;
      calories += ex.caloriesBurn;
    }

    if (selected.length < 4) {
      selected.addAll(shuffled.take(6 - selected.length));
    }

    final titles = {
      'Full Body': 'Home Power Circuit',
      'Upper Body': 'Upper Body Blast',
      'Lower Body': 'Leg Day at Home',
      'Core': 'Core Crusher',
      'Cardio': 'Cardio Burn',
    };

    return WorkoutPlan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: titles[focus] ?? 'Daily Home Workout',
      description:
          'AI-generated $targetMinutes-min $focus workout — zero equipment needed. Perfect for your living room!',
      totalMinutes: minutes.clamp(15, 45),
      totalCalories: calories,
      exercises: selected.take(8).toList(),
      focus: focus,
    );
  }

  static const List<String> focusOptions = [
    'Full Body',
    'Upper Body',
    'Lower Body',
    'Core',
    'Cardio',
  ];

  static const List<String> levelOptions = ['Easy', 'Medium', 'Hard'];
}
