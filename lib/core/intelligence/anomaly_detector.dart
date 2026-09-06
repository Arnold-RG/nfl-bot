import 'dart:math' as math;

import '../models/health_intelligence.dart';
import '../models/smart_watch_model.dart';

/// Flags physiological readings that deviate from the user's own baseline.
///
/// This is a wellness signal, not a diagnosis — every alert carries a
/// suggested action rather than a medical conclusion.
class AnomalyDetector {
  /// Number of standard deviations from baseline before a reading is flagged.
  static const _watchSigma = 2.0;
  static const _urgentSigma = 3.0;

  static List<HealthAlert> analyze({
    required WatchVitals vitals,
    required List<int> restingHrHistory,
    required List<int> hrvHistory,
    required List<double> sleepHistory,
    required bool isResting,
  }) {
    final alerts = <HealthAlert>[];
    final now = DateTime.now();

    // Oxygen saturation is judged against clinical guidance, not baseline,
    // because low SpO2 is meaningful regardless of an individual's average.
    if (vitals.spo2Percent < 90) {
      alerts.add(HealthAlert(
        id: 'spo2-critical',
        title: 'Low blood oxygen',
        message:
            'Your watch reported ${vitals.spo2Percent}% oxygen saturation, which is well below the typical range.',
        severity: AlertSeverity.urgent,
        metric: 'SpO₂',
        detectedAt: now,
        suggestedAction:
            'Sit upright, breathe slowly, and re-measure. If it stays low or you feel short of breath, contact a clinician.',
      ));
    } else if (vitals.spo2Percent < 94) {
      alerts.add(HealthAlert(
        id: 'spo2-watch',
        title: 'Oxygen slightly low',
        message: 'Oxygen saturation is ${vitals.spo2Percent}%.',
        severity: AlertSeverity.watch,
        metric: 'SpO₂',
        detectedAt: now,
        suggestedAction:
            'Check your watch fit and re-measure while still. Cold hands and loose straps cause false lows.',
      ));
    }

    // Elevated heart rate while at rest.
    final rhrBaseline = _mean(restingHrHistory);
    final rhrSigma = _stdDev(restingHrHistory);
    if (isResting && rhrBaseline > 0 && rhrSigma > 0) {
      final delta = vitals.heartRateBpm - rhrBaseline;
      final z = delta / rhrSigma;
      if (z >= _urgentSigma) {
        alerts.add(HealthAlert(
          id: 'hr-high-urgent',
          title: 'Resting heart rate spike',
          message:
              'At rest your heart rate is ${vitals.heartRateBpm} bpm versus a usual ${rhrBaseline.round()} bpm.',
          severity: AlertSeverity.urgent,
          metric: 'Heart rate',
          detectedAt: now,
          suggestedAction:
              'Rest for 10 minutes and re-check. Persistent unexplained spikes are worth discussing with a clinician.',
        ));
      } else if (z >= _watchSigma) {
        alerts.add(HealthAlert(
          id: 'hr-high-watch',
          title: 'Heart rate above your normal',
          message:
              'Resting heart rate is ${vitals.heartRateBpm} bpm, above your ${rhrBaseline.round()} bpm baseline.',
          severity: AlertSeverity.watch,
          metric: 'Heart rate',
          detectedAt: now,
          suggestedAction:
              'Common causes are caffeine, poor sleep, dehydration, or illness onset. Hydrate and keep training easy today.',
        ));
      }
    }

    // Suppressed heart rate variability suggests accumulated strain.
    final hrvBaseline = _mean(hrvHistory);
    final hrvSigma = _stdDev(hrvHistory);
    if (hrvBaseline > 0 && hrvSigma > 0) {
      final z = (vitals.hrvMs - hrvBaseline) / hrvSigma;
      if (z <= -_watchSigma) {
        alerts.add(HealthAlert(
          id: 'hrv-suppressed',
          title: 'Heart rate variability suppressed',
          message:
              'HRV is ${vitals.hrvMs} ms against a baseline of ${hrvBaseline.round()} ms.',
          severity: z <= -_urgentSigma ? AlertSeverity.urgent : AlertSeverity.watch,
          metric: 'HRV',
          detectedAt: now,
          suggestedAction:
              'Your nervous system is still under load. Swap intensity for a walk or mobility session.',
        ));
      }
    }

    // Sustained high stress.
    if (vitals.stressScore >= 80) {
      alerts.add(HealthAlert(
        id: 'stress-high',
        title: 'Stress running high',
        message: 'Stress index is ${vitals.stressScore} out of 100.',
        severity: AlertSeverity.watch,
        metric: 'Stress',
        detectedAt: now,
        suggestedAction:
            'Try five minutes of slow breathing — four seconds in, six seconds out — then reassess.',
      ));
    }

    // Cumulative sleep debt.
    if (sleepHistory.length >= 3) {
      final recent = sleepHistory.length <= 7
          ? sleepHistory
          : sleepHistory.sublist(sleepHistory.length - 7);
      final debt = recent.fold<double>(0, (sum, h) => sum + math.max(0, 7.5 - h));
      if (debt >= 6) {
        alerts.add(HealthAlert(
          id: 'sleep-debt',
          title: 'Sleep debt building',
          message:
              'You are about ${debt.toStringAsFixed(1)} hours short over the past week.',
          severity: debt >= 10 ? AlertSeverity.urgent : AlertSeverity.watch,
          metric: 'Sleep',
          detectedAt: now,
          suggestedAction:
              'Move bedtime 30–45 minutes earlier for the next three nights rather than chasing one long lie-in.',
        ));
      }
    }

    // Skin temperature elevation often precedes illness.
    if (vitals.skinTempC >= 37.4) {
      alerts.add(HealthAlert(
        id: 'temp-elevated',
        title: 'Skin temperature elevated',
        message:
            'Wrist temperature is ${vitals.skinTempC.toStringAsFixed(1)}°C, above your typical range.',
        severity: AlertSeverity.watch,
        metric: 'Temperature',
        detectedAt: now,
        suggestedAction:
            'Often an early illness or overreaching signal. Prioritise fluids and sleep, and hold off on hard sessions.',
      ));
    }

    if (alerts.isEmpty) {
      alerts.add(HealthAlert(
        id: 'all-clear',
        title: 'Nothing unusual detected',
        message:
            'Heart rate, oxygen, HRV, stress, and temperature are all tracking within your normal ranges.',
        severity: AlertSeverity.info,
        metric: 'Overall',
        detectedAt: now,
        suggestedAction: 'Carry on with your planned session.',
      ));
    }

    alerts.sort((a, b) => b.severity.index.compareTo(a.severity.index));
    return alerts;
  }

  static double _mean(List<num> values) {
    if (values.isEmpty) return 0;
    return values.fold<double>(0, (a, b) => a + b) / values.length;
  }

  static double _stdDev(List<num> values) {
    if (values.length < 2) return 0;
    final mean = _mean(values);
    final variance = values
            .map((v) => math.pow(v - mean, 2).toDouble())
            .fold<double>(0, (a, b) => a + b) /
        (values.length - 1);
    return math.sqrt(variance);
  }
}
