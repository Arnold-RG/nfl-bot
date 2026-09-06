import 'package:flutter/foundation.dart';

import '../intelligence/adaptive_plan_engine.dart';
import '../intelligence/anomaly_detector.dart';
import '../intelligence/readiness_engine.dart';
import '../intelligence/sleep_analyzer.dart';
import '../models/health_intelligence.dart';
import '../models/smart_watch_model.dart';
import 'local_storage_service.dart';
import 'smart_watch_service.dart';

/// Central intelligence layer: turns raw vitals and logs into readiness,
/// sleep architecture, health alerts, an adaptive plan, and trend forecasts.
class IntelligenceService extends ChangeNotifier {
  final LocalStorageService _storage;
  final SmartWatchService _watch;

  ReadinessScore? _readiness;
  SleepAnalysis? _sleep;
  List<HealthAlert> _alerts = const [];
  AdaptivePlan? _plan;
  TrendForecast? _weightForecast;
  TrendForecast? _loadForecast;

  ReadinessScore? get readiness => _readiness;
  SleepAnalysis? get sleep => _sleep;
  List<HealthAlert> get alerts => List.unmodifiable(_alerts);
  AdaptivePlan? get plan => _plan;
  TrendForecast? get weightForecast => _weightForecast;
  TrendForecast? get loadForecast => _loadForecast;

  /// Why readiness is unavailable, or null when a score was produced. Scoring
  /// against a baseline is meaningless before that baseline exists, so the
  /// app says so instead of publishing a number it cannot stand behind.
  String? get readinessUnavailableReason {
    if (_readiness != null) return null;
    if (!_watch.isConnected && !_storage.hasVitalsBaseline) {
      return 'Pair your watch to start building a recovery baseline. '
          'Readiness needs heart rate variability and resting heart rate data.';
    }
    if (!_storage.hasSleepLog && _storage.sleepHistory.isEmpty) {
      return 'Log a night of sleep to unlock your readiness score.';
    }
    return 'Not enough data yet for a readiness score.';
  }

  int get urgentAlertCount =>
      _alerts.where((a) => a.severity == AlertSeverity.urgent).length;
  int get actionableAlertCount =>
      _alerts.where((a) => a.severity != AlertSeverity.info).length;

  IntelligenceService({
    required LocalStorageService storage,
    required SmartWatchService watch,
  })  : _storage = storage,
        _watch = watch;

  /// Recomputes every derived metric. Cheap enough to call on any data change.
  void recompute({double? sleepHoursOverride, int? sleepQualityOverride}) {
    final vitals = _watch.vitals;
    final rhrHistory = _storage.restingHrHistory;
    final hrvHistory = _storage.hrvHistory;
    final sleepHistory = _storage.sleepHistory;
    final loadHistory = _storage.dailyLoadHistory;

    final sleepHours = sleepHoursOverride ??
        (_storage.hasSleepLog
            ? _storage.sleepHours.toDouble()
            : (sleepHistory.isNotEmpty ? sleepHistory.last : 0.0));
    final sleepQuality = sleepQualityOverride ?? _storage.sleepQuality;

    final workload = ReadinessEngine.workloadFrom(loadHistory);

    // Readiness is only published once there is real physiological input to
    // score. Otherwise every user would see the same synthetic number.
    final hasVitals = _watch.isConnected || _storage.hasVitalsBaseline;
    _readiness = (hasVitals && sleepHours > 0)
        ? ReadinessEngine.compute(
            hrvMs: _watch.isConnected
                ? vitals.hrvMs
                : ReadinessEngine.rollingBaseline(hrvHistory),
            hrvBaselineMs: ReadinessEngine.rollingBaseline(hrvHistory),
            restingHr: _watch.isConnected
                ? vitals.restingHeartRate
                : ReadinessEngine.rollingBaseline(rhrHistory),
            restingHrBaseline: ReadinessEngine.rollingBaseline(rhrHistory),
            sleepHours: sleepHours,
            sleepQualityPercent: sleepQuality,
            acuteLoad: workload.acute,
            chronicLoad: workload.chronic,
            stressScore: _watch.isConnected ? vitals.stressScore : 40,
          )
        : null;

    _sleep = sleepHours > 0
        ? SleepAnalyzer.analyze(
            totalHours: sleepHours,
            qualityPercent: sleepQuality,
            recentNights: sleepHistory,
            bedtimeMinutesFromMidnight: _storage.bedtimeHistory,
          )
        : null;

    _alerts = _watch.isConnected
        ? AnomalyDetector.analyze(
            vitals: vitals,
            restingHrHistory: rhrHistory,
            hrvHistory: hrvHistory,
            sleepHistory: sleepHistory,
            isResting: vitals.heartRateBpm < 100,
          )
        : [
            HealthAlert(
              id: 'no-watch',
              title: 'No watch connected',
              message:
                  'Pair a smart watch to unlock live anomaly detection for heart rate, oxygen, HRV, and temperature.',
              severity: AlertSeverity.info,
              metric: 'Overall',
              detectedAt: DateTime.now(),
              suggestedAction: 'Open the Watch Hub and pair a device.',
            ),
          ];

    _plan = _readiness == null
        ? null
        : AdaptivePlanEngine.build(
            goal: _storage.profile.goal.name,
            readiness: _readiness!,
            missedSessions: _storage.missedSessions,
            weeklyLoadTarget: workload.chronic == 0 ? 350 : workload.chronic,
          );

    _weightForecast = AdaptivePlanEngine.forecast(
      metric: 'Weight',
      history: _storage.weightHistory,
      weeksAhead: 4,
    );

    _loadForecast = AdaptivePlanEngine.forecast(
      metric: 'Training load',
      history: loadHistory.map((e) => e.toDouble()).toList(),
      weeksAhead: 3,
    );

    notifyListeners();
  }

  /// Persists a fresh vitals sample so baselines keep tracking the user.
  Future<void> recordVitalsSample(WatchVitals vitals) async {
    await _storage.appendVitalsSample(
      restingHr: vitals.restingHeartRate,
      hrv: vitals.hrvMs,
    );
    recompute();
  }

  Future<void> recordSleep(double hours, int bedtimeMinutesFromMidnight) async {
    await _storage.appendSleepSample(hours, bedtimeMinutesFromMidnight);
    recompute(sleepHoursOverride: hours);
  }

  Future<void> recordTrainingLoad(int load) async {
    await _storage.appendTrainingLoad(load);
    recompute();
  }

  Future<void> setMissedSessions(int count) async {
    await _storage.setMissedSessions(count);
    recompute();
  }
}
