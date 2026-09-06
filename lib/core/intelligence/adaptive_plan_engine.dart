import 'dart:math' as math;

import '../models/health_intelligence.dart';

/// Builds a weekly training plan and reshapes it when readiness drops,
/// sessions get missed, or workload runs ahead of the target.
class AdaptivePlanEngine {
  static const _days = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  /// Baseline templates by goal. Load units approximate session strain.
  static const _templates = <String, List<(String, int, String)>>{
    'muscle': [
      ('Upper strength', 45, 'Hard'),
      ('Lower strength', 45, 'Hard'),
      ('Mobility', 25, 'Easy'),
      ('Push focus', 40, 'Moderate'),
      ('Pull focus', 40, 'Moderate'),
      ('Conditioning', 30, 'Moderate'),
      ('Rest', 0, 'Rest'),
    ],
    'cut': [
      ('Full body circuit', 40, 'Hard'),
      ('Zone 2 cardio', 45, 'Easy'),
      ('Upper strength', 40, 'Moderate'),
      ('Intervals', 25, 'Hard'),
      ('Lower strength', 40, 'Moderate'),
      ('Long walk', 50, 'Easy'),
      ('Rest', 0, 'Rest'),
    ],
    'endurance': [
      ('Easy run', 40, 'Easy'),
      ('Intervals', 35, 'Hard'),
      ('Strength support', 30, 'Moderate'),
      ('Easy run', 45, 'Easy'),
      ('Tempo', 35, 'Hard'),
      ('Long effort', 70, 'Moderate'),
      ('Rest', 0, 'Rest'),
    ],
    'maintain': [
      ('Full body', 40, 'Moderate'),
      ('Cardio', 35, 'Easy'),
      ('Core & mobility', 25, 'Easy'),
      ('Upper strength', 40, 'Moderate'),
      ('Lower strength', 40, 'Moderate'),
      ('Active recovery', 30, 'Easy'),
      ('Rest', 0, 'Rest'),
    ],
  };

  static AdaptivePlan build({
    required String goal,
    required ReadinessScore readiness,
    required int missedSessions,
    required int weeklyLoadTarget,
  }) {
    final template = _templates[goal] ?? _templates['maintain']!;

    var sessions = <PlannedSession>[
      for (var i = 0; i < template.length; i++)
        PlannedSession(
          day: _days[i],
          focus: template[i].$1,
          minutes: template[i].$2,
          intensity: template[i].$3,
        ),
    ];

    final adaptations = <String>[];

    // Low readiness pulls the hardest sessions back before anything else.
    if (readiness.recommendation == TrainingRecommendation.recover) {
      sessions = sessions
          .map((s) => s.intensity == 'Rest'
              ? s
              : s.copyWith(
                  focus: 'Recovery walk',
                  minutes: 25,
                  intensity: 'Easy',
                  adapted: true,
                  adaptationReason: 'Readiness ${readiness.score} — full recovery day',
                ))
          .toList();
      adaptations.add('all sessions dropped to recovery');
    } else if (readiness.recommendation == TrainingRecommendation.active) {
      sessions = sessions
          .map((s) => s.intensity == 'Hard'
              ? s.copyWith(
                  minutes: math.max(20, (s.minutes * 0.6).round()),
                  intensity: 'Easy',
                  adapted: true,
                  adaptationReason: 'Readiness ${readiness.score} — hard work deferred',
                )
              : s)
          .toList();
      adaptations.add('hard sessions softened');
    } else if (readiness.recommendation == TrainingRecommendation.moderate) {
      sessions = sessions
          .map((s) => s.intensity == 'Hard'
              ? s.copyWith(
                  minutes: math.max(25, (s.minutes * 0.8).round()),
                  intensity: 'Moderate',
                  adapted: true,
                  adaptationReason: 'Readiness ${readiness.score} — intensity capped',
                )
              : s)
          .toList();
      adaptations.add('intensity capped at moderate');
    } else if (readiness.recommendation == TrainingRecommendation.pushHard) {
      final index = sessions.indexWhere((s) => s.intensity == 'Moderate');
      if (index != -1) {
        sessions[index] = sessions[index].copyWith(
          intensity: 'Hard',
          minutes: sessions[index].minutes + 10,
          adapted: true,
          adaptationReason: 'Readiness ${readiness.score} — room to push',
        );
        adaptations.add('one session upgraded to hard');
      }
    }

    // Missed sessions get redistributed into the rest day rather than stacked.
    if (missedSessions > 0) {
      final restIndex = sessions.indexWhere((s) => s.intensity == 'Rest');
      if (restIndex != -1 && readiness.score >= 55) {
        sessions[restIndex] = sessions[restIndex].copyWith(
          focus: 'Make-up session',
          minutes: 35,
          intensity: 'Moderate',
          adapted: true,
          adaptationReason: '$missedSessions missed session(s) rescheduled here',
        );
        adaptations.add('$missedSessions missed session(s) rescheduled');
      }
    }

    final projectedLoad = sessions.fold<int>(
      0,
      (sum, s) => sum + _loadFor(s),
    );

    // Trim the longest session if the week overshoots the load target badly.
    if (weeklyLoadTarget > 0 && projectedLoad > weeklyLoadTarget * 1.35) {
      var longest = 0;
      for (var i = 1; i < sessions.length; i++) {
        if (sessions[i].minutes > sessions[longest].minutes) longest = i;
      }
      sessions[longest] = sessions[longest].copyWith(
        minutes: (sessions[longest].minutes * 0.7).round(),
        adapted: true,
        adaptationReason: 'Weekly load trimmed to protect recovery',
      );
      adaptations.add('weekly volume trimmed');
    }

    final finalLoad = sessions.fold<int>(0, (sum, s) => sum + _loadFor(s));

    return AdaptivePlan(
      sessions: sessions,
      summary: adaptations.isEmpty
          ? 'Plan is on track — no adaptations needed this week.'
          : 'Adapted: ${adaptations.join(', ')}.',
      weeklyLoadTarget: weeklyLoadTarget,
      projectedLoad: finalLoad,
    );
  }

  static int _loadFor(PlannedSession s) {
    final multiplier = switch (s.intensity) {
      'Hard' => 2.0,
      'Moderate' => 1.4,
      'Easy' => 0.8,
      _ => 0.0,
    };
    return (s.minutes * multiplier).round();
  }

  static TrendForecast forecast({
    required String metric,
    required List<double> history,
    required int weeksAhead,
  }) {
    if (history.length < 3) {
      return TrendForecast(
        metric: metric,
        history: history,
        projection: const [],
        slopePerWeek: 0,
        plateauDetected: false,
        insight: 'Log a few more weeks and I can project where $metric is heading.',
      );
    }

    final n = history.length;
    final meanX = (n - 1) / 2;
    final meanY = history.reduce((a, b) => a + b) / n;
    var num = 0.0;
    var den = 0.0;
    for (var i = 0; i < n; i++) {
      num += (i - meanX) * (history[i] - meanY);
      den += math.pow(i - meanX, 2);
    }
    final slope = den == 0 ? 0.0 : num / den;
    final intercept = meanY - slope * meanX;

    final projection = [
      for (var i = 0; i < weeksAhead; i++) intercept + slope * (n + i),
    ];

    // A plateau is a slope near zero relative to the metric's own scale.
    final scale = meanY.abs() < 1 ? 1 : meanY.abs();
    final plateau = (slope / scale).abs() < 0.005;

    return TrendForecast(
      metric: metric,
      history: history,
      projection: projection,
      slopePerWeek: slope,
      plateauDetected: plateau,
      insight: _forecastInsight(metric, slope, plateau, projection),
    );
  }

  static String _forecastInsight(
    String metric,
    double slope,
    bool plateau,
    List<double> projection,
  ) {
    if (plateau) {
      return '$metric has flattened out. A plateau usually means the stimulus needs to change — adjust volume, intensity, or intake rather than repeating the same week.';
    }
    final direction = slope > 0 ? 'rising' : 'falling';
    final target = projection.isEmpty ? null : projection.last;
    final projected = target == null ? '' : ' On the current path you land near ${target.toStringAsFixed(1)}.';
    return '$metric is $direction by ${slope.abs().toStringAsFixed(2)} per week.$projected';
  }
}
