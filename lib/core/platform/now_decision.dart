import '../engines/body_engine.dart';
import '../providers/app_state.dart';

enum NowActionKind {
  eat,
  train,
  walk,
  recover,
  hydrate,
  sleepWindDown,
  celebrate,
}

class NowDecision {
  final NowActionKind kind;
  final String title;
  final String reason;
  final String cta;
  final int? openTab; // 0 Home, 1 Train, 2 Nutrition, 3 Progress, 4 Coach

  const NowDecision({
    required this.kind,
    required this.title,
    required this.reason,
    required this.cta,
    this.openTab,
  });
}

/// Deterministic "What should I do now?" — explains itself from live body data.
class NowDecisionEngine {
  static NowDecision decide(AppState state, BodyDaySnapshot day) {
    final hour = DateTime.now().hour;
    final proteinLeft = (day.proteinGoal - day.proteinG).clamp(0, 999);
    final calLeft = day.caloriesRemaining;

    if (hour >= 21 && day.steps >= day.stepGoal * 0.85) {
      return const NowDecision(
        kind: NowActionKind.sleepWindDown,
        title: 'Wind down for sleep',
        reason:
            'You hit most of today’s movement target. Start winding down so recovery stays high tomorrow.',
        cta: 'Open recovery tips',
        openTab: 4,
      );
    }

    if (day.waterLiters < day.waterGoal * 0.4 && hour >= 11) {
      return NowDecision(
        kind: NowActionKind.hydrate,
        title: 'Drink water',
        reason:
            'Hydration is at ${day.waterLiters.toStringAsFixed(1)} L of ${day.waterGoal.toStringAsFixed(1)} L. A glass now helps the rest of the day.',
        cta: 'Log +250 ml',
        openTab: 0,
      );
    }

    if (day.trainingReadiness >= 70 &&
        hour >= 16 &&
        hour <= 20 &&
        state.workoutsCompleted == 0) {
      return NowDecision(
        kind: NowActionKind.train,
        title: 'Start ${day.workoutTitle}',
        reason:
            'Readiness is ${day.trainingReadiness}% and ${day.workoutFocus} look ready. '
            'Legs are ${day.muscles.where((m) => m.name == 'Quads').firstOrNull?.percent ?? 40}% recovered — plan respects that.',
        cta: 'Open Train',
        openTab: 1,
      );
    }

    if (proteinLeft >= 35 && hour >= 11 && calLeft > 400) {
      return NowDecision(
        kind: NowActionKind.eat,
        title: 'Eat a protein-forward meal',
        reason:
            'About ${proteinLeft.round()} g protein and $calLeft kcal remain. '
            'A chicken/rice/veg plate or Greek yogurt bowl fits without guessing.',
        cta: 'Open Nutrition',
        openTab: 2,
      );
    }

    if (day.steps < day.stepGoal * 0.55 && hour >= 12 && hour <= 19) {
      return NowDecision(
        kind: NowActionKind.walk,
        title: 'Take a 10–20 minute walk',
        reason:
            'Steps are at ${day.steps} of ${day.stepGoal}. A short walk raises activity without crushing recovery.',
        cta: 'Log a walk',
        openTab: 0,
      );
    }

    if (day.trainingReadiness < 50) {
      return const NowDecision(
        kind: NowActionKind.recover,
        title: 'Keep today light',
        reason:
            'Recovery is lower than usual. Prefer walking, mobility, or an easy upper-body session — not another hard lower-body day.',
        cta: 'Ask AI Coach',
        openTab: 4,
      );
    }

    if (day.healthScore >= 85) {
      return NowDecision(
        kind: NowActionKind.celebrate,
        title: 'You’re on track',
        reason: day.coachBrief,
        cta: 'See Progress',
        openTab: 3,
      );
    }

    return NowDecision(
      kind: NowActionKind.eat,
      title: 'Check today’s plan',
      reason:
          'Health score ${day.healthScore}. ${day.coachBrief}',
      cta: 'Ask AI Coach',
      openTab: 4,
    );
  }
}
