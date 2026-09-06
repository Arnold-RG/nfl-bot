import 'dart:math' as math;

import '../models/health_intelligence.dart';

/// Derives sleep architecture, efficiency, debt, and bedtime consistency.
class SleepAnalyzer {
  static const _targetHours = 7.5;

  /// Healthy adult stage distribution used to shape the estimate when the
  /// watch reports only total duration and a quality percentage.
  static const _deepShare = 0.19;
  static const _remShare = 0.23;
  static const _awakeShare = 0.06;

  static SleepAnalysis analyze({
    required double totalHours,
    required int qualityPercent,
    required List<double> recentNights,
    required List<int> bedtimeMinutesFromMidnight,
  }) {
    final totalMinutes = (totalHours * 60).round();

    // Higher quality shifts minutes from awake/light into deep and REM.
    final qualityFactor = (qualityPercent / 100).clamp(0.3, 1.0);
    final awakeMinutes = (totalMinutes * _awakeShare * (2 - qualityFactor)).round();
    final deepMinutes = (totalMinutes * _deepShare * qualityFactor).round();
    final remMinutes = (totalMinutes * _remShare * qualityFactor).round();
    final lightMinutes =
        math.max(0, totalMinutes - awakeMinutes - deepMinutes - remMinutes);

    final segments = [
      SleepSegment(stage: SleepStage.deep, minutes: deepMinutes),
      SleepSegment(stage: SleepStage.rem, minutes: remMinutes),
      SleepSegment(stage: SleepStage.light, minutes: lightMinutes),
      SleepSegment(stage: SleepStage.awake, minutes: awakeMinutes),
    ];

    final asleepMinutes = totalMinutes - awakeMinutes;
    final efficiency = totalMinutes == 0
        ? 0
        : (asleepMinutes / totalMinutes * 100).round().clamp(0, 100);

    return SleepAnalysis(
      totalHours: totalHours,
      efficiencyPercent: efficiency,
      consistencyScore: _consistency(bedtimeMinutesFromMidnight),
      debtHours: _debt(recentNights),
      segments: segments,
      insight: _insight(
        totalHours: totalHours,
        deepMinutes: deepMinutes,
        remMinutes: remMinutes,
        efficiency: efficiency,
        debt: _debt(recentNights),
        consistency: _consistency(bedtimeMinutesFromMidnight),
      ),
      night: DateTime.now(),
    );
  }

  /// Accumulated shortfall against the target over the trailing week.
  static double _debt(List<double> nights) {
    if (nights.isEmpty) return 0;
    final window = nights.length <= 7
        ? nights
        : nights.sublist(nights.length - 7);
    return window.fold<double>(
      0,
      (sum, hours) => sum + math.max(0, _targetHours - hours),
    );
  }

  /// Consistency rewards a stable bedtime. A standard deviation of 0 minutes
  /// scores 100; 90+ minutes of drift scores 0.
  static int _consistency(List<int> bedtimes) {
    if (bedtimes.length < 2) return 70;
    final mean = bedtimes.fold<double>(0, (a, b) => a + b) / bedtimes.length;
    final variance = bedtimes
            .map((b) => math.pow(b - mean, 2).toDouble())
            .fold<double>(0, (a, b) => a + b) /
        (bedtimes.length - 1);
    final sd = math.sqrt(variance);
    return (100 - sd / 90 * 100).round().clamp(0, 100);
  }

  static String _insight({
    required double totalHours,
    required int deepMinutes,
    required int remMinutes,
    required int efficiency,
    required double debt,
    required int consistency,
  }) {
    if (totalHours < 6) {
      return 'Only ${totalHours.toStringAsFixed(1)} hours last night. Short sleep blunts strength output and appetite control the next day — treat today as a lighter session.';
    }
    if (debt >= 6) {
      return 'You are carrying roughly ${debt.toStringAsFixed(1)} hours of sleep debt. Recovering it gradually beats one long weekend lie-in.';
    }
    if (deepMinutes < 60) {
      return 'Deep sleep came in at $deepMinutes minutes, below the 60–110 range most adults need for physical repair. Cooler room and no late alcohol usually help most.';
    }
    if (remMinutes < 70) {
      return 'REM was $remMinutes minutes. REM concentrates in the second half of the night, so cutting sleep short trims it first.';
    }
    if (consistency < 55) {
      return 'Your bedtime varies a lot night to night. Anchoring it within a 30-minute window tends to lift both HRV and deep sleep.';
    }
    if (efficiency >= 90) {
      return 'Strong night — ${totalHours.toStringAsFixed(1)} hours at $efficiency% efficiency. This is a good window for a hard session.';
    }
    return 'Solid sleep at ${totalHours.toStringAsFixed(1)} hours. Efficiency of $efficiency% leaves a little room; limit screens in the final hour before bed.';
  }
}
