import 'coach_persona.dart';
import 'health_intelligence.dart';

enum AiProvider { anthropic, openai, offline }

/// Snapshot of everything the coach should know before answering.
class CoachContext {
  final String userName;
  final CoachPersona coach;
  final int caloriesConsumed;
  final int calorieGoal;
  final double proteinG;
  final int steps;
  final int stepGoal;
  final double hydrationLiters;
  final double sleepHours;
  final int workoutsCompleted;
  final bool watchConnected;
  final int? heartRate;
  final int? spo2;
  final int? hrv;
  final ReadinessScore? readiness;
  final String languageName;
  final String languageCode;
  final String countryName;

  const CoachContext({
    required this.userName,
    required this.coach,
    required this.caloriesConsumed,
    required this.calorieGoal,
    required this.proteinG,
    required this.steps,
    required this.stepGoal,
    required this.hydrationLiters,
    required this.sleepHours,
    required this.workoutsCompleted,
    required this.watchConnected,
    this.heartRate,
    this.spo2,
    this.hrv,
    this.readiness,
    this.languageName = 'English',
    this.languageCode = 'en',
    this.countryName = 'Poland',
  });

  String toPromptBlock() {
    final lines = <String>[
      'User name: $userName',
      'Calories: $caloriesConsumed of $calorieGoal kcal today',
      'Protein so far: ${proteinG.toStringAsFixed(0)} g',
      'Steps: $steps of $stepGoal',
      'Hydration: ${hydrationLiters.toStringAsFixed(1)} L',
      'Last night sleep: ${sleepHours.toStringAsFixed(1)} h',
      'Workouts completed all-time: $workoutsCompleted',
      'Smart watch connected: ${watchConnected ? 'yes' : 'no'}',
      'Reply language: $languageName ($languageCode)',
      'Member country: $countryName',
    ];
    if (heartRate != null) lines.add('Current heart rate: $heartRate bpm');
    if (spo2 != null) lines.add('Blood oxygen: $spo2%');
    if (hrv != null) lines.add('HRV: $hrv ms');
    if (readiness != null) {
      lines.add(
        'Readiness score: ${readiness!.score}/100 (${readiness!.bandLabel}) — '
        'recommendation: ${readiness!.recommendationLabel}',
      );
    }
    return lines.join('\n');
  }
}

class CoachReply {
  final String text;
  final CoachMood mood;
  final bool fromModel;
  final String? error;

  const CoachReply({
    required this.text,
    required this.mood,
    required this.fromModel,
    this.error,
  });
}
