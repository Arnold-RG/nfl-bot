import '../engines/body_engine.dart';
import '../platform/health_data_platform.dart';
import '../providers/app_state.dart';
import '../services/app_services.dart';

enum AiIntent {
  foodVision,
  nutritionAdvice,
  trainingAdvice,
  recoveryAdvice,
  progressExplain,
  now,
  generalChat,
  medicalRedirect,
}

/// Routes questions to deterministic engines first; LLM only explains.
class AiOrchestrator {
  AiOrchestrator(this.platform);

  final HealthDataPlatform platform;

  static const medicalDisclaimer =
      'NFL BOT provides wellness and fitness guidance and is not a substitute '
      'for professional medical advice, diagnosis or treatment.';

  AiIntent classify(String raw) {
    final q = raw.toLowerCase();
    if (_looksMedical(q)) return AiIntent.medicalRedirect;
    if (q.contains('what should i do now') || q.contains('what do i do now')) {
      return AiIntent.now;
    }
    if (q.contains('should i train') ||
        q.contains('workout') ||
        q.contains('legs') ||
        q.contains('bench') ||
        q.contains('what should i train')) {
      return AiIntent.trainingAdvice;
    }
    if (q.contains('eat') ||
        q.contains('protein') ||
        q.contains('calorie') ||
        q.contains('pizza') ||
        q.contains('dinner') ||
        q.contains('food') ||
        q.contains('hitting protein')) {
      return AiIntent.nutritionAdvice;
    }
    if (q.contains('tired') ||
        q.contains('recover') ||
        q.contains('sleep') ||
        q.contains('sore') ||
        q.contains('how recovered')) {
      return AiIntent.recoveryAdvice;
    }
    if (q.contains('progress') ||
        q.contains('weight') ||
        q.contains('summarize') ||
        q.contains('why')) {
      return AiIntent.progressExplain;
    }
    return AiIntent.generalChat;
  }

  /// Builds a grounded answer. For general chat, returns null so the LLM can run.
  String? groundedReply(String userMessage, AppState state) {
    final intent = classify(userMessage);
    final day = platform.day;
    final memory = platform.memory.promptBlock();

    switch (intent) {
      case AiIntent.medicalRedirect:
        return '$medicalDisclaimer If you have severe or persistent symptoms, '
            'contact a qualified clinician. I can help adjust today’s training '
            'or nutrition plan within wellness limits.';
      case AiIntent.now:
        final d = platform.whatShouldIDoNow();
        return '${d.title}. ${d.reason}';
      case AiIntent.trainingAdvice:
        return '${_training(day, state)}\n\nPreferences: $memory';
      case AiIntent.nutritionAdvice:
        return '${_nutrition(day, userMessage)}\n\nPreferences: $memory';
      case AiIntent.recoveryAdvice:
        return 'Recovery is about ${day.recoveryPercent}% and training readiness '
            'is ${day.trainingReadiness}%. ${day.coachBrief} '
            'I am not diagnosing fatigue — treat this as a wellness signal.';
      case AiIntent.progressExplain:
        return 'Health score ${day.healthScore}/100 (wellness score, not a medical '
            'assessment). Steps ${day.steps}/${day.stepGoal}, protein '
            '${day.proteinG.toStringAsFixed(0)}/${day.proteinGoal.toStringAsFixed(0)} g, '
            'calories ${day.caloriesConsumed}/${day.calorieGoal}.';
      case AiIntent.foodVision:
      case AiIntent.generalChat:
        return null;
    }
  }

  String _training(BodyDaySnapshot day, AppState state) {
    final quads =
        day.muscles.where((m) => m.name == 'Quads').firstOrNull?.percent ?? 40;
    if (quads < 45) {
      return 'I would avoid heavy leg training today. Quads are around $quads% '
          'recovered. ${day.workoutTitle} (${day.workoutFocus}) is the safer plan. '
          'If a joint hurts sharply, stop and seek clinical advice.';
    }
    return 'Readiness ${day.trainingReadiness}%. Today’s plan is ${day.workoutTitle} '
        '— ${day.workoutFocus}, about ${day.workoutMinutes} minutes.';
  }

  String _nutrition(BodyDaySnapshot day, String q) {
    final proteinLeft = (day.proteinGoal - day.proteinG).clamp(0, 999).round();
    final calLeft = day.caloriesRemaining;
    final allergies = platform.memory.allergies;
    if (allergies.isNotEmpty) {
      final hit = allergies.any((a) => q.toLowerCase().contains(a));
      if (hit) {
        return '⚠️ ALLERGY WARNING: your profile lists ${allergies.join(', ')}. '
            'I will not recommend those ingredients. Confirm labels yourself.';
      }
    }
    if (q.toLowerCase().contains('pizza')) {
      return 'Yes, you can. You have about $calLeft kcal left. If pizza is around '
          '700 kcal you still fit the day. You are also about $proteinLeft g short '
          'of protein — add a protein-rich side if you can.';
    }
    return 'About $calLeft kcal and $proteinLeft g protein remain. '
        'I would aim for a balanced plate that closes the protein gap first. '
        'Food camera estimates are editable before you log.';
  }

  Future<String> answer(String userMessage, {bool speak = true}) async {
    final text =
        await AppServices.appState.sendChatMessage(userMessage, speak: speak);
    return text ?? 'I am here when you are ready.';
  }

  static bool _looksMedical(String q) {
    const flags = [
      'chest pain',
      'can\'t breathe',
      'cannot breathe',
      'suicidal',
      'stroke',
      'heart attack',
      'diagnose',
      'prescription',
      'blood in',
      'unconscious',
    ];
    return flags.any(q.contains);
  }
}
