import '../models/coach_context.dart';
import '../models/coach_persona.dart';

/// On-device coaching knowledge used when no language model is configured
/// or a request fails. Unlike simple keyword matching, answers are composed
/// from the user's live numbers so they stay specific and useful offline.
class CoachKnowledge {
  static String answer(String message, CoachContext ctx) {
    final q = message.toLowerCase();
    final caloriesLeft = ctx.calorieGoal - ctx.caloriesConsumed;
    final stepsLeft = ctx.stepGoal - ctx.steps;

    if (_matches(q, ['readiness', 'recovered', 'should i train', 'train today', 'rest day'])) {
      final r = ctx.readiness;
      if (r == null) {
        return 'I need a night of watch data to score your readiness. Pair your watch in the Watch Hub and wear it overnight, then I can tell you whether to push or hold back.';
      }
      return 'Your readiness is ${r.score} out of 100, which puts you in the ${r.bandLabel.toLowerCase()} range. ${r.detail}\n\nMy call for today: ${r.recommendationLabel.toLowerCase()}.';
    }

    if (_matches(q, ['calorie', 'how much can i eat', 'eat more', 'deficit', 'what to eat', 'dinner', 'lunch', 'breakfast', 'meal idea'])) {
      if (ctx.nextMealSuggestion != null) {
        final status = ctx.overTarget
            ? 'You are over target — here is a lighter close: '
            : ctx.hadMealSkip
                ? 'You skipped a meal — catch-up plate: '
                : 'Eat this next: ';
        return '$status${ctx.nextMealSuggestion}.\n\nYou have ${caloriesLeft > 0 ? caloriesLeft : 0} kcal and protein at ${ctx.proteinG.toStringAsFixed(0)} of ${ctx.proteinGoalG.toStringAsFixed(0)} g. Open Body Coach for vitamin-focused plates.';
      }
      if (caloriesLeft > 400) {
        return 'You have $caloriesLeft kcal left of your ${ctx.calorieGoal} target, and you are at ${ctx.proteinG.toStringAsFixed(0)} g protein.\n\nSpend most of that on protein and vegetables — a palm-sized portion of chicken, fish, or tofu with a big salad gets you close without much else.';
      }
      if (caloriesLeft > 0) {
        return 'Only $caloriesLeft kcal left today, so keep it light. Greek yoghurt or a protein shake fits and still adds to your ${ctx.proteinG.toStringAsFixed(0)} g protein total.';
      }
      return 'You are ${caloriesLeft.abs()} kcal over your target. Not a problem on its own — one day rarely moves the needle. Close the day with water and a walk, and reset tomorrow. Body Coach has lighter alternatives.';
    }

    if (_matches(q, ['skip', 'skipped', 'missed breakfast', 'missed lunch', 'missed dinner', 'ate too much', 'overeating', 'over ate'])) {
      return ctx.hadMealSkip || ctx.overTarget
          ? 'I already adapted your plan. ${ctx.nextMealSuggestion ?? 'Open Body Coach for catch-up or lighter plates.'}\n\nMark skips in Body Coach so the next suggestions stay accurate.'
          : 'Tell Body Coach which meal you skipped, or if you ate too much — I will redistribute protein/calories and suggest alternatives. You can also say what you ate and ask for a lighter close.';
    }

    if (_matches(q, ['protein'])) {
      return 'You are at ${ctx.proteinG.toStringAsFixed(0)} g of ${ctx.proteinGoalG.toStringAsFixed(0)} g protein today.\n\nAnchor every meal with eggs, yoghurt, chicken, fish, tofu, or lentils first — then build the plate. Body Coach lists vitamin-aware options that still hit protein.';
    }

    if (_matches(q, ['vitamin', 'supplement', 'micronutrient'])) {
      final meal = ctx.nextMealSuggestion;
      return 'Food first: colourful vegetables and fruit cover most micronutrients.\n\n${meal == null ? 'Open Body Coach for plates tagged with vitamins C, D, iron, and B12.' : 'Right now I would run: $meal'}\n\nEvidence-backed extras: creatine for training, vitamin D if you get little sun, protein powder for convenience.';
    }

    if (_matches(q, ['workout', 'exercise', 'routine', 'plan', 'session', 'gym', 'how long'])) {
      final mins = ctx.suggestedGymMinutes;
      final focus = ctx.trainingFocus;
      final r = ctx.readiness;
      final guard = r == null
          ? ''
          : ' Readiness ${r.score} → ${r.recommendationLabel.toLowerCase()}.';
      if (mins != null && focus != null) {
        return 'Based on what you have eaten today: about $mins minutes of $focus.$guard\n\n${ctx.suggestedSport == null ? '' : 'Or do ${ctx.suggestedSport} if you prefer that sport today. '}Open Body Coach or Train to start the session.';
      }
      return 'Open Train and generate today\'s session — it builds around your fuel and readiness.$guard';
    }

    if (_matches(q, ['swim', 'dance', 'sport', 'cycling', 'yoga instead'])) {
      return ctx.suggestedSport == null
          ? 'Add sports you like in Body Coach (swim, dance, cycle, run, yoga). I will suggest them when they fit your fuel and goal.'
          : 'Today I would pick ${ctx.suggestedSport}. ${ctx.suggestedGymMinutes ?? 30} minutes is enough if you keep a steady effort.';
    }

    if (_matches(q, ['weight', 'lose', 'fat loss', 'gain', 'plateau', 'progress', 'goal'])) {
      final goal = ctx.bodyGoalSummary;
      return '${goal == null ? 'Set a target weight in Body Coach to track fat-loss progress in real time.' : goal}\n\nWeight moves on weekly averages — weigh at the same time each morning. If the trend is flat for two weeks, change one lever: food, steps, or training volume.';
    }

    if (_matches(q, ['step', 'walk', 'cardio'])) {
      if (stepsLeft > 0) {
        return 'You are on ${ctx.steps} steps, so $stepsLeft short of your ${ctx.stepGoal} goal. A 20 minute walk usually covers about 2,000 of those.\n\nWalking after your largest meal gives you the best blood-sugar return for the time spent.';
      }
      return 'You have cleared your step goal with ${ctx.steps} steps. Anything past this is a bonus for recovery rather than something you need to chase.';
    }

    if (_matches(q, ['water', 'hydrat', 'drink'])) {
      return 'You are at ${ctx.hydrationLiters.toStringAsFixed(1)} L today. Aim for roughly 35 ml per kilogram of bodyweight, plus another 500 ml for each hour of hard training.';
    }

    if (_matches(q, ['sleep', 'tired', 'exhausted', 'insomnia'])) {
      if (ctx.sleepHours < 6.5) {
        return 'You logged ${ctx.sleepHours.toStringAsFixed(1)} hours, which is short. Treat today as moderate, and move bedtime earlier tonight.';
      }
      return 'At ${ctx.sleepHours.toStringAsFixed(1)} hours you are in decent shape. Consistency beats one long night.';
    }

    if (_matches(q, ['heart', 'bpm', 'hrv', 'pulse', 'watch', 'pair', 'connect'])) {
      if (!ctx.watchConnected) {
        return 'Pair a watch in the Watch Hub so I can read heart rate, HRV, and recovery live.';
      }
      return 'Your watch is reporting ${ctx.heartRate ?? '--'} bpm${ctx.hrv == null ? '' : ' with HRV at ${ctx.hrv} ms'}.';
    }

    if (_matches(q, ['hello', 'hi ', 'hey', 'morning', 'good evening'])) {
      return 'Hey ${ctx.userName}. You are on ${ctx.caloriesConsumed} kcal and ${ctx.steps} steps so far today.\n\nAsk me about food, training, sleep, or what your watch is picking up — I will use your actual numbers.';
    }

    if (_matches(q, ['thank', 'cheers', 'appreciate'])) {
      return 'Any time, ${ctx.userName}. Keep logging and I will keep the guidance specific to you.';
    }

    return 'I can help with nutrition, training, sleep, recovery, and anything your watch is measuring. Right now you are at ${ctx.caloriesConsumed} of ${ctx.calorieGoal} kcal and ${ctx.steps} of ${ctx.stepGoal} steps.\n\nAsk me something concrete — for example whether you should train today, or what to eat with the calories you have left.';
  }

  static bool _matches(String query, List<String> needles) =>
      needles.any(query.contains);

  /// Picks the orb's disposition for an exchange.
  static CoachMood moodFor(String userMessage, String reply) {
    final q = userMessage.toLowerCase();
    final r = reply.toLowerCase();

    if (r.contains('clinician') || r.contains('doctor')) {
      return CoachMood.alert;
    }
    if (_matches(q, ['pain', 'hurt', 'injur', 'sick', 'ill'])) {
      return CoachMood.concerned;
    }
    if (_matches(q, ['tired', 'exhausted', 'stress', 'anxious', 'overwhelm'])) {
      return CoachMood.focused;
    }
    if (_matches(q, [
      'smashed',
      'crushed',
      'did it',
      'finished',
      'pr',
      'record',
    ])) {
      return CoachMood.celebrating;
    }
    if (_matches(q, ['thank', 'cheers', 'appreciate', 'love'])) {
      return CoachMood.encouraging;
    }
    if (_matches(r, ['push', 'go hard', 'peak', 'strong'])) {
      return CoachMood.celebrating;
    }
    if (_matches(r, ['rest', 'hold back', 'ease', 'recover'])) {
      return CoachMood.focused;
    }
    return CoachMood.encouraging;
  }
}
