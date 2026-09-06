import 'dart:math' as math;

import '../models/health_intelligence.dart';

/// Computes a composite recovery/readiness score from wearable vitals.
///
/// Each input is scored against a personal baseline rather than a fixed
/// threshold, because absolute HRV and resting heart rate vary widely
/// between individuals. Components are then weighted and combined.
class ReadinessEngine {
  /// Relative weights. Sleep and HRV dominate; stress is a modifier.
  static const _wHrv = 0.30;
  static const _wRestingHr = 0.20;
  static const _wSleep = 0.28;
  static const _wLoad = 0.14;
  static const _wStress = 0.08;

  static ReadinessScore compute({
    required int hrvMs,
    required int hrvBaselineMs,
    required int restingHr,
    required int restingHrBaseline,
    required double sleepHours,
    required int sleepQualityPercent,
    required int acuteLoad,
    required int chronicLoad,
    required int stressScore,
  }) {
    final hrvComponent = _scoreHrv(hrvMs, hrvBaselineMs);
    final rhrComponent = _scoreRestingHr(restingHr, restingHrBaseline);
    final sleepComponent = _scoreSleep(sleepHours, sleepQualityPercent);
    final loadComponent = _scoreLoad(acuteLoad, chronicLoad);
    final stressComponent = _scoreStress(stressScore);

    final raw = hrvComponent * _wHrv +
        rhrComponent * _wRestingHr +
        sleepComponent * _wSleep +
        loadComponent * _wLoad +
        stressComponent * _wStress;

    final score = raw.round().clamp(1, 100);
    final band = _bandFor(score);

    return ReadinessScore(
      score: score,
      band: band,
      recommendation: _recommendationFor(band, loadComponent),
      hrvComponent: hrvComponent.round(),
      restingHrComponent: rhrComponent.round(),
      sleepComponent: sleepComponent.round(),
      loadComponent: loadComponent.round(),
      stressComponent: stressComponent.round(),
      headline: _headlineFor(band, score),
      detail: _detailFor(
        band: band,
        hrv: hrvComponent,
        rhr: rhrComponent,
        sleep: sleepComponent,
        load: loadComponent,
        stress: stressComponent,
      ),
      computedAt: DateTime.now(),
    );
  }

  /// HRV above baseline is good. Scored on percent deviation, saturating
  /// at ±25% so one unusual night can't dominate the score.
  static double _scoreHrv(int hrv, int baseline) {
    if (baseline <= 0) return 60;
    final deviation = (hrv - baseline) / baseline;
    final normalized = (deviation / 0.25).clamp(-1.0, 1.0);
    return (60 + normalized * 40).clamp(0, 100);
  }

  /// Resting heart rate *below* baseline is good, so the sign is inverted.
  static double _scoreRestingHr(int rhr, int baseline) {
    if (baseline <= 0) return 60;
    final deviation = (rhr - baseline) / baseline;
    final normalized = (deviation / 0.15).clamp(-1.0, 1.0);
    return (65 - normalized * 45).clamp(0, 100);
  }

  /// Combines duration (target 8h, credit from 5h up) with reported quality.
  static double _scoreSleep(double hours, int qualityPercent) {
    final durationScore = (hours / 8.0 * 100).clamp(0, 100).toDouble();
    final shortfallPenalty = hours < 6 ? (6 - hours) * 8 : 0.0;
    final combined = durationScore * 0.6 + qualityPercent * 0.4 - shortfallPenalty;
    return combined.clamp(0, 100);
  }

  /// Acute:chronic workload ratio. The 0.8–1.3 window is the sweet spot;
  /// well below means detraining, well above means injury risk.
  static double _scoreLoad(int acute, int chronic) {
    if (chronic <= 0) return 70;
    final ratio = acute / chronic;
    if (ratio >= 0.8 && ratio <= 1.3) return 90;
    if (ratio < 0.8) {
      final gap = (0.8 - ratio).clamp(0.0, 0.8);
      return (90 - gap * 50).clamp(35, 90);
    }
    final excess = (ratio - 1.3).clamp(0.0, 1.2);
    return (90 - excess * 55).clamp(10, 90);
  }

  static double _scoreStress(int stressScore) =>
      (100 - stressScore).clamp(0, 100).toDouble();

  static ReadinessBand _bandFor(int score) {
    if (score >= 85) return ReadinessBand.peak;
    if (score >= 70) return ReadinessBand.ready;
    if (score >= 55) return ReadinessBand.moderate;
    if (score >= 40) return ReadinessBand.compromised;
    return ReadinessBand.rest;
  }

  static TrainingRecommendation _recommendationFor(
    ReadinessBand band,
    double loadComponent,
  ) {
    // A high band with an overreaching load signal still gets pulled back.
    if (loadComponent < 45) {
      return band == ReadinessBand.peak || band == ReadinessBand.ready
          ? TrainingRecommendation.moderate
          : TrainingRecommendation.active;
    }
    switch (band) {
      case ReadinessBand.peak:
        return TrainingRecommendation.pushHard;
      case ReadinessBand.ready:
        return TrainingRecommendation.train;
      case ReadinessBand.moderate:
        return TrainingRecommendation.moderate;
      case ReadinessBand.compromised:
        return TrainingRecommendation.active;
      case ReadinessBand.rest:
        return TrainingRecommendation.recover;
    }
  }

  static String _headlineFor(ReadinessBand band, int score) {
    switch (band) {
      case ReadinessBand.peak:
        return 'Peak readiness — $score';
      case ReadinessBand.ready:
        return 'Recovered and ready — $score';
      case ReadinessBand.moderate:
        return 'Partially recovered — $score';
      case ReadinessBand.compromised:
        return 'Recovery is lagging — $score';
      case ReadinessBand.rest:
        return 'Your body needs rest — $score';
    }
  }

  static String _detailFor({
    required ReadinessBand band,
    required double hrv,
    required double rhr,
    required double sleep,
    required double load,
    required double stress,
  }) {
    final weakest = <String, double>{
      'heart rate variability': hrv,
      'resting heart rate': rhr,
      'sleep': sleep,
      'training load': load,
      'stress': stress,
    }.entries.reduce((a, b) => a.value <= b.value ? a : b);

    final strongest = <String, double>{
      'heart rate variability': hrv,
      'resting heart rate': rhr,
      'sleep': sleep,
      'training load': load,
      'stress': stress,
    }.entries.reduce((a, b) => a.value >= b.value ? a : b);

    if (band == ReadinessBand.peak || band == ReadinessBand.ready) {
      return 'Your ${strongest.key} is leading the way. '
          'Keep an eye on ${weakest.key} — it is your lowest input today.';
    }
    return 'The main drag is your ${weakest.key}. '
        'Address that first; ${strongest.key} is already in good shape.';
  }

  /// Rolling baseline helper — exponentially weighted so recent days matter
  /// more, which tracks fitness changes without overreacting to one outlier.
  static int rollingBaseline(List<int> history, {double alpha = 0.25}) {
    if (history.isEmpty) return 0;
    var baseline = history.first.toDouble();
    for (final value in history.skip(1)) {
      baseline = alpha * value + (1 - alpha) * baseline;
    }
    return baseline.round();
  }

  /// Acute load = last 7 days, chronic load = last 28 days (daily average
  /// scaled to a week) — the standard acute:chronic workload approach.
  static ({int acute, int chronic}) workloadFrom(List<int> dailyLoad) {
    if (dailyLoad.isEmpty) return (acute: 0, chronic: 0);
    final recent = dailyLoad.length <= 7
        ? dailyLoad
        : dailyLoad.sublist(dailyLoad.length - 7);
    final window = dailyLoad.length <= 28
        ? dailyLoad
        : dailyLoad.sublist(dailyLoad.length - 28);
    final acute = recent.fold<int>(0, (a, b) => a + b);
    final chronicAvg = window.fold<int>(0, (a, b) => a + b) / window.length;
    return (acute: acute, chronic: (chronicAvg * 7).round());
  }

  /// Simple least-squares slope used by the trend forecaster.
  static double linearSlope(List<double> values) {
    if (values.length < 2) return 0;
    final n = values.length;
    final meanX = (n - 1) / 2;
    final meanY = values.reduce((a, b) => a + b) / n;
    var numerator = 0.0;
    var denominator = 0.0;
    for (var i = 0; i < n; i++) {
      numerator += (i - meanX) * (values[i] - meanY);
      denominator += math.pow(i - meanX, 2);
    }
    if (denominator == 0) return 0;
    return numerator / denominator;
  }
}
