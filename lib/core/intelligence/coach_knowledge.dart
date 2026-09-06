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

    if (_matches(q, ['calorie', 'how much can i eat', 'eat more', 'deficit'])) {
      if (caloriesLeft > 400) {
        return 'You have $caloriesLeft kcal left of your ${ctx.calorieGoal} target, and you are at ${ctx.proteinG.toStringAsFixed(0)} g protein.\n\nSpend most of that on protein and vegetables — a palm-sized portion of chicken, fish, or tofu with a big salad gets you close without much else.';
      }
      if (caloriesLeft > 0) {
        return 'Only $caloriesLeft kcal left today, so keep it light. Greek yoghurt or a protein shake fits and still adds to your ${ctx.proteinG.toStringAsFixed(0)} g protein total.';
      }
      return 'You are ${caloriesLeft.abs()} kcal over your target. Not a problem on its own — one day rarely moves the needle. Close the day with water and a walk, and reset tomorrow.';
    }

    if (_matches(q, ['protein'])) {
      return 'You are at ${ctx.proteinG.toStringAsFixed(0)} g protein so far. A good working range is 1.6 to 2.2 g per kilogram of bodyweight when you are training regularly.\n\nThe easiest fix is anchoring every meal with a protein source first — eggs, yoghurt, chicken, fish, lentils — then building the rest of the plate around it.';
    }

    if (_matches(q, ['step', 'walk', 'cardio'])) {
      if (stepsLeft > 0) {
        return 'You are on ${ctx.steps} steps, so $stepsLeft short of your ${ctx.stepGoal} goal. A 20 minute walk usually covers about 2,000 of those.\n\nWalking after your largest meal gives you the best blood-sugar return for the time spent.';
      }
      return 'You have cleared your step goal with ${ctx.steps} steps. Anything past this is a bonus for recovery rather than something you need to chase.';
    }

    if (_matches(q, ['water', 'hydrat', 'drink'])) {
      return 'You are at ${ctx.hydrationLiters.toStringAsFixed(1)} L today. Aim for roughly 35 ml per kilogram of bodyweight, plus another 500 ml for each hour of hard training.\n\nA practical check: pale straw-coloured urine means you are on track.';
    }

    if (_matches(q, ['sleep', 'tired', 'exhausted', 'insomnia'])) {
      if (ctx.sleepHours < 6.5) {
        return 'You logged ${ctx.sleepHours.toStringAsFixed(1)} hours, which is short. Under about seven hours, strength output drops and hunger signals get noisier the next day.\n\nTreat today as a moderate session rather than a hard one, and move bedtime 30 minutes earlier tonight instead of trying to bank it all at the weekend.';
      }
      return 'At ${ctx.sleepHours.toStringAsFixed(1)} hours you are in decent shape. The bigger lever now is consistency — going to bed within the same 30 minute window every night does more for recovery than one long night.';
    }

    if (_matches(q, ['workout', 'exercise', 'routine', 'plan', 'session'])) {
      final r = ctx.readiness;
      final guard = r == null
          ? ''
          : ' Your readiness is ${r.score}, so ${r.recommendationLabel.toLowerCase()}.';
      return 'Open the Workout tab and generate today\'s session — it builds around the time and equipment you actually have.$guard\n\nIf you only have 20 minutes, a full-body circuit beats an isolated body part every time.';
    }

    if (_matches(q, ['heart', 'bpm', 'hrv', 'pulse'])) {
      if (!ctx.watchConnected) {
        return 'I am not reading a watch right now. Pair one in the Watch Hub over Bluetooth, QR, Wi-Fi, or your health account and I can track heart rate, HRV, and oxygen live.';
      }
      final hr = ctx.heartRate;
      final hrv = ctx.hrv;
      return 'Your watch is reporting ${hr ?? '--'} bpm${hrv == null ? '' : ' with HRV at $hrv ms'}.\n\nHRV is most useful compared against your own average rather than anyone else\'s — a sustained drop usually means training load, alcohol, or illness rather than anything sinister.';
    }

    if (_matches(q, ['watch', 'pair', 'connect', 'bluetooth', 'sync'])) {
      return ctx.watchConnected
          ? 'Your watch is connected and syncing. You can force a fresh pull any time with Sync now in the Watch Hub.'
          : 'Head to the Watch Hub tab. You can pair four ways — Bluetooth scan, QR code, Wi-Fi with an IP and PIN, or signing into your health cloud account.';
    }

    if (_matches(q, ['weight', 'lose', 'fat loss', 'gain', 'plateau'])) {
      return 'Weight moves on weekly averages, not daily readings — water shifts easily hide real change. Weigh at the same time each morning and only judge the seven-day trend.\n\nIf that trend has been flat for two or more weeks, change one thing at a time: usually intake first, then step count, then training volume.';
    }

    if (_matches(q, ['sore', 'pain', 'hurt', 'injur'])) {
      return 'Muscle soreness that eases as you warm up is normal and safe to train around. Sharp, joint-centred, or one-sided pain is not — back off that movement and give it a few days.\n\nIf pain persists beyond a week or affects how you walk, get it looked at properly rather than pushing through.';
    }

    if (_matches(q, ['stress', 'anxious', 'overwhelm'])) {
      return 'Slow breathing is the fastest lever you have — four seconds in, six out, for five minutes. It shifts you out of a sympathetic state measurably.\n\nAfter that, a walk outdoors does more than another hard session when stress is already high.';
    }

    if (_matches(q, ['vitamin', 'supplement', 'micronutrient'])) {
      return 'Food first: varied colours across your vegetables and fruit covers most micronutrients without much thought.\n\nThe supplements with the strongest evidence are creatine for training output, vitamin D if you get little sun, and protein powder purely for convenience. Most of the rest are optional.';
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
