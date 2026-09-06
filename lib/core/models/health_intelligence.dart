/// Models for the intelligence layer: readiness, sleep analysis, anomalies,
/// adaptive training, and trend forecasting.
library;

enum ReadinessBand { peak, ready, moderate, compromised, rest }

enum TrainingRecommendation { pushHard, train, moderate, active, recover }

class ReadinessScore {
  /// 0–100 composite readiness.
  final int score;
  final ReadinessBand band;
  final TrainingRecommendation recommendation;

  /// Individual normalized contributions (0–100) for the breakdown chart.
  final int hrvComponent;
  final int restingHrComponent;
  final int sleepComponent;
  final int loadComponent;
  final int stressComponent;

  final String headline;
  final String detail;
  final DateTime computedAt;

  const ReadinessScore({
    required this.score,
    required this.band,
    required this.recommendation,
    required this.hrvComponent,
    required this.restingHrComponent,
    required this.sleepComponent,
    required this.loadComponent,
    required this.stressComponent,
    required this.headline,
    required this.detail,
    required this.computedAt,
  });

  String get bandLabel {
    switch (band) {
      case ReadinessBand.peak:
        return 'Peak';
      case ReadinessBand.ready:
        return 'Ready';
      case ReadinessBand.moderate:
        return 'Moderate';
      case ReadinessBand.compromised:
        return 'Compromised';
      case ReadinessBand.rest:
        return 'Rest';
    }
  }

  String get recommendationLabel {
    switch (recommendation) {
      case TrainingRecommendation.pushHard:
        return 'Push hard';
      case TrainingRecommendation.train:
        return 'Train as planned';
      case TrainingRecommendation.moderate:
        return 'Keep it moderate';
      case TrainingRecommendation.active:
        return 'Active recovery';
      case TrainingRecommendation.recover:
        return 'Full recovery day';
    }
  }
}

enum SleepStage { awake, light, deep, rem }

class SleepSegment {
  final SleepStage stage;
  final int minutes;

  const SleepSegment({required this.stage, required this.minutes});
}

class SleepAnalysis {
  final double totalHours;
  final int efficiencyPercent;
  final int consistencyScore;
  final double debtHours;
  final List<SleepSegment> segments;
  final String insight;
  final DateTime night;

  const SleepAnalysis({
    required this.totalHours,
    required this.efficiencyPercent,
    required this.consistencyScore,
    required this.debtHours,
    required this.segments,
    required this.insight,
    required this.night,
  });

  int minutesIn(SleepStage stage) => segments
      .where((s) => s.stage == stage)
      .fold<int>(0, (sum, s) => sum + s.minutes);

  double percentIn(SleepStage stage) {
    final total = segments.fold<int>(0, (sum, s) => sum + s.minutes);
    if (total == 0) return 0;
    return minutesIn(stage) / total * 100;
  }
}

enum AlertSeverity { info, watch, urgent }

class HealthAlert {
  final String id;
  final String title;
  final String message;
  final AlertSeverity severity;
  final String metric;
  final DateTime detectedAt;
  final String suggestedAction;

  const HealthAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.metric,
    required this.detectedAt,
    required this.suggestedAction,
  });
}

class PlannedSession {
  final String day;
  final String focus;
  final int minutes;
  final String intensity;
  final bool adapted;
  final String? adaptationReason;

  const PlannedSession({
    required this.day,
    required this.focus,
    required this.minutes,
    required this.intensity,
    this.adapted = false,
    this.adaptationReason,
  });

  PlannedSession copyWith({
    String? focus,
    int? minutes,
    String? intensity,
    bool? adapted,
    String? adaptationReason,
  }) {
    return PlannedSession(
      day: day,
      focus: focus ?? this.focus,
      minutes: minutes ?? this.minutes,
      intensity: intensity ?? this.intensity,
      adapted: adapted ?? this.adapted,
      adaptationReason: adaptationReason ?? this.adaptationReason,
    );
  }
}

class AdaptivePlan {
  final List<PlannedSession> sessions;
  final String summary;
  final int weeklyLoadTarget;
  final int projectedLoad;

  const AdaptivePlan({
    required this.sessions,
    required this.summary,
    required this.weeklyLoadTarget,
    required this.projectedLoad,
  });
}

class TrendForecast {
  final String metric;
  final List<double> history;
  final List<double> projection;
  final double slopePerWeek;
  final bool plateauDetected;
  final String insight;

  const TrendForecast({
    required this.metric,
    required this.history,
    required this.projection,
    required this.slopePerWeek,
    required this.plateauDetected,
    required this.insight,
  });
}
