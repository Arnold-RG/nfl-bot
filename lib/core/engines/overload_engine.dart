// Progressive overload prescriptions from last set + recovery — deterministic.

class OverloadInput {
  final double lastWeightKg;
  final int lastReps;
  final double rpe; // 1–10
  final int recoveryPercent; // 0–100
  final String exercise;

  const OverloadInput({
    required this.lastWeightKg,
    required this.lastReps,
    required this.rpe,
    required this.recoveryPercent,
    this.exercise = 'Compound lift',
  });
}

class OverloadPrescription {
  final String exercise;
  final double weightKg;
  final int reps;
  final int sets;
  final String cue;
  final String rationale;

  const OverloadPrescription({
    required this.exercise,
    required this.weightKg,
    required this.reps,
    required this.sets,
    required this.cue,
    required this.rationale,
  });

  String get summary =>
      '${weightKg.toStringAsFixed(weightKg % 1 == 0 ? 0 : 1)} kg × '
      '$sets×$reps · $cue';
}

class OverloadEngine {
  /// Next session target from last performance, RPE, and recovery.
  static OverloadPrescription next(OverloadInput input) {
    final recovery = input.recoveryPercent.clamp(0, 100);
    final rpe = input.rpe.clamp(1, 10);
    final reps = input.lastReps.clamp(1, 30);
    var weight = input.lastWeightKg;
    var nextReps = reps;
    var sets = 3;
    late String cue;
    late String rationale;

    if (recovery < 45) {
      weight = (weight * 0.9).clamp(0, 999);
      nextReps = (reps - 2).clamp(5, 12);
      sets = 2;
      cue = 'Deload';
      rationale =
          'Recovery is low ($recovery%). Drop ~10% load and keep technique crisp.';
    } else if (rpe >= 9 || reps < 6) {
      weight = weight;
      nextReps = (reps + 1).clamp(5, 12);
      cue = 'Add reps';
      rationale =
          'Last set felt hard (RPE ${rpe.toStringAsFixed(1)}). Hold weight, chase +1–2 reps.';
    } else if (rpe <= 7 && reps >= 8 && recovery >= 70) {
      final bump = weight >= 60 ? 2.5 : 1.25;
      weight = weight + bump;
      nextReps = (reps - 1).clamp(6, 10);
      cue = 'Add load';
      rationale =
          'Solid recovery ($recovery%) and manageable RPE. Add $bump kg.';
    } else {
      nextReps = (reps + 1).clamp(6, 12);
      cue = 'Progress reps';
      rationale =
          'Steady progress: same weight, one more quality rep before loading up.';
    }

    return OverloadPrescription(
      exercise: input.exercise,
      weightKg: double.parse(weight.toStringAsFixed(2)),
      reps: nextReps,
      sets: sets,
      cue: cue,
      rationale: rationale,
    );
  }

  /// Default preview when the member has not logged a set yet.
  static OverloadPrescription previewForProfile({
    required String equipment,
    required String experience,
    required int recoveryPercent,
  }) {
    final home = equipment.toLowerCase() == 'home';
    final beginner = experience.toLowerCase().contains('begin');
    return next(
      OverloadInput(
        lastWeightKg: home ? (beginner ? 12 : 20) : (beginner ? 40 : 60),
        lastReps: beginner ? 10 : 8,
        rpe: 7.5,
        recoveryPercent: recoveryPercent,
        exercise: home ? 'Goblet squat' : 'Barbell squat',
      ),
    );
  }
}
