import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../../config/app_theme.dart';
import '../../../../../config/routes.dart';
import '../../../../../core/models/health_intelligence.dart';
import '../../../../../core/providers/app_state.dart';
import '../../../../../core/services/app_services.dart';
import '../../../../../core/theme/app_layout.dart';
import '../components/live_coach_orb.dart';

/// Intelligence hub: readiness, sleep architecture, health alerts,
/// the adaptive weekly plan, and trend forecasting.
class IntelligenceScreen extends StatelessWidget {
  const IntelligenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppServices.intelligence,
      builder: (context, _) {
        final intel = AppServices.intelligence;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [AppTheme.darkBg, const Color(0xFF101A16)]
                  : [const Color(0xFFE9F5F0), AppTheme.backgroundColor],
            ),
          ),
          child: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async => intel.recompute(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                children: [
                  const _Header(),
                  const SizedBox(height: 18),
                  if (intel.readiness != null) ...[
                    _ReadinessCard(readiness: intel.readiness!),
                    const SizedBox(height: 14),
                    _ComponentBreakdown(readiness: intel.readiness!),
                  ] else
                    _AwaitingData(
                      reason: intel.readinessUnavailableReason ??
                          'Not enough data yet for a readiness score.',
                      needsSleepLog: !context.watch<AppState>().hasSleepLog,
                    ),
                  const SizedBox(height: 18),
                  _SectionTitle('Health alerts', badge: intel.actionableAlertCount),
                  const SizedBox(height: 10),
                  ...intel.alerts.map((a) => _AlertCard(alert: a)),
                  const SizedBox(height: 18),
                  if (intel.sleep != null) ...[
                    const _SectionTitle('Sleep lab'),
                    const SizedBox(height: 10),
                    _SleepCard(sleep: intel.sleep!),
                  ],
                  const SizedBox(height: 18),
                  if (intel.plan != null) ...[
                    const _SectionTitle('Adaptive week'),
                    const SizedBox(height: 10),
                    _PlanCard(plan: intel.plan!),
                  ],
                  const SizedBox(height: 18),
                  if (intel.weightForecast != null) ...[
                    const _SectionTitle('Trend forecast'),
                    const SizedBox(height: 10),
                    _ForecastCard(forecast: intel.weightForecast!),
                  ],
                  const SizedBox(height: 16),
                  const _Disclaimer(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Explains exactly which inputs are still missing, rather than hiding the
/// whole screen or showing a score with nothing behind it.
class _AwaitingData extends StatelessWidget {
  final String reason;
  final bool needsSleepLog;

  const _AwaitingData({required this.reason, required this.needsSleepLog});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppLayout.cardDecoration(context, radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CC9A8).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: Color(0xFF4CC9A8),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Building your baseline',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            reason,
            style: AppLayout.subtitleStyle(context).copyWith(height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.watch),
                  icon: const Icon(Icons.watch_rounded, size: 18),
                  label: const Text('Pair watch'),
                ),
              ),
              if (needsSleepLog) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _logSleep(context),
                    icon: const Icon(Icons.bedtime_rounded, size: 18),
                    label: const Text('Log sleep'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C853),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _logSleep(BuildContext context) async {
    final state = context.read<AppState>();
    var hours = 7.0;
    var quality = 75.0;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(sheetContext).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Last night',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 18),
              Text('Time asleep: ${hours.toStringAsFixed(1)} h'),
              Slider(
                value: hours,
                min: 3,
                max: 12,
                divisions: 18,
                activeColor: const Color(0xFF00C853),
                onChanged: (v) => setSheetState(() => hours = v),
              ),
              Text('How rested do you feel: ${quality.round()}%'),
              Slider(
                value: quality,
                min: 20,
                max: 100,
                divisions: 16,
                activeColor: const Color(0xFF00C853),
                onChanged: (v) => setSheetState(() => quality = v),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(sheetContext).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (saved == true) {
      state.logSleep(hours.round(), quality.round());
    }
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final connected = state.watchConnected;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Intelligence', style: AppLayout.screenTitleStyle(context)),
              const SizedBox(height: 4),
              Text(
                connected
                    ? 'Scored from your live watch data'
                    : 'Pair a watch for live scoring',
                style: AppLayout.subtitleStyle(context),
              ),
            ],
          ),
        ),
        const LiveCoachOrb(size: 58),
      ],
    );
  }
}

class _ReadinessCard extends StatelessWidget {
  final ReadinessScore readiness;
  const _ReadinessCard({required this.readiness});

  Color get _color {
    switch (readiness.band) {
      case ReadinessBand.peak:
        return const Color(0xFF2BD9A0);
      case ReadinessBand.ready:
        return const Color(0xFF4CC9A8);
      case ReadinessBand.moderate:
        return const Color(0xFFFFB347);
      case ReadinessBand.compromised:
        return const Color(0xFFFF8A5C);
      case ReadinessBand.rest:
        return const Color(0xFFFF6B6B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [_color.withValues(alpha: 0.92), _color.withValues(alpha: 0.62)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _color.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 92,
                height: 92,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: readiness.score / 100,
                        strokeWidth: 9,
                        backgroundColor: Colors.white.withValues(alpha: 0.25),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${readiness.score}',
                          style: GoogleFonts.syne(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                        Text(
                          readiness.bandLabel,
                          style: GoogleFonts.dmSans(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Readiness',
                      style: GoogleFonts.dmSans(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      readiness.recommendationLabel,
                      style: GoogleFonts.syne(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            readiness.detail,
            style: GoogleFonts.dmSans(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComponentBreakdown extends StatelessWidget {
  final ReadinessScore readiness;
  const _ComponentBreakdown({required this.readiness});

  @override
  Widget build(BuildContext context) {
    final rows = <(String, int, Color)>[
      ('Heart rate variability', readiness.hrvComponent, const Color(0xFF4CC9A8)),
      ('Resting heart rate', readiness.restingHrComponent, const Color(0xFFFF6B6B)),
      ('Sleep', readiness.sleepComponent, const Color(0xFF7C6CF0)),
      ('Training load', readiness.loadComponent, const Color(0xFFFFB347)),
      ('Stress', readiness.stressComponent, const Color(0xFF5B8DEF)),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppLayout.cardDecoration(context, radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What is driving the score',
            style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          for (final (label, value, color) in rows) ...[
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    label,
                    style: GoogleFonts.dmSans(fontSize: 13),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: value / 100,
                      minHeight: 8,
                      backgroundColor: color.withValues(alpha: 0.14),
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 28,
                  child: Text(
                    '$value',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final HealthAlert alert;
  const _AlertCard({required this.alert});

  (Color, IconData) get _style {
    switch (alert.severity) {
      case AlertSeverity.urgent:
        return (const Color(0xFFFF5252), Icons.warning_amber_rounded);
      case AlertSeverity.watch:
        return (const Color(0xFFFFA726), Icons.info_outline_rounded);
      case AlertSeverity.info:
        return (const Color(0xFF4CC9A8), Icons.check_circle_outline_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _style;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: AppLayout.cardDecoration(context, radius: 18).copyWith(
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        alert.title,
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        alert.metric,
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  alert.message,
                  style: GoogleFonts.dmSans(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 8),
                Text(
                  alert.suggestedAction,
                  style: GoogleFonts.dmSans(
                    fontSize: 12.5,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: AppLayout.subtitleColor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SleepCard extends StatelessWidget {
  final SleepAnalysis sleep;
  const _SleepCard({required this.sleep});

  static const _stageColors = {
    SleepStage.deep: Color(0xFF3B4FD9),
    SleepStage.rem: Color(0xFF7C6CF0),
    SleepStage.light: Color(0xFF5B8DEF),
    SleepStage.awake: Color(0xFFFFB347),
  };

  static const _stageLabels = {
    SleepStage.deep: 'Deep',
    SleepStage.rem: 'REM',
    SleepStage.light: 'Light',
    SleepStage.awake: 'Awake',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppLayout.cardDecoration(context, radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                height: 120,
                width: 120,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 34,
                    sections: [
                      for (final segment in sleep.segments)
                        if (segment.minutes > 0)
                          PieChartSectionData(
                            value: segment.minutes.toDouble(),
                            color: _stageColors[segment.stage],
                            radius: 22,
                            showTitle: false,
                          ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${sleep.totalHours.toStringAsFixed(1)} h',
                      style: GoogleFonts.syne(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${sleep.efficiencyPercent}% efficiency',
                      style: AppLayout.subtitleStyle(context).copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    for (final segment in sleep.segments)
                      if (segment.minutes > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: _stageColors[segment.stage],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${_stageLabels[segment.stage]} · ${segment.minutes} min',
                                style: GoogleFonts.dmSans(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricChip(
                  label: 'Sleep debt',
                  value: '${sleep.debtHours.toStringAsFixed(1)} h',
                  color: sleep.debtHours >= 6
                      ? const Color(0xFFFF6B6B)
                      : const Color(0xFF4CC9A8),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricChip(
                  label: 'Consistency',
                  value: '${sleep.consistencyScore}/100',
                  color: sleep.consistencyScore >= 60
                      ? const Color(0xFF4CC9A8)
                      : const Color(0xFFFFB347),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            sleep.insight,
            style: GoogleFonts.dmSans(fontSize: 13.5, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final AdaptivePlan plan;
  const _PlanCard({required this.plan});

  Color _intensityColor(String intensity) {
    switch (intensity) {
      case 'Hard':
        return const Color(0xFFFF6B6B);
      case 'Moderate':
        return const Color(0xFFFFB347);
      case 'Easy':
        return const Color(0xFF4CC9A8);
      default:
        return const Color(0xFF9AA5A1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppLayout.cardDecoration(context, radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plan.summary,
            style: GoogleFonts.dmSans(
              fontSize: 13.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Projected load ${plan.projectedLoad} against a ${plan.weeklyLoadTarget} target',
            style: AppLayout.subtitleStyle(context).copyWith(fontSize: 12),
          ),
          const SizedBox(height: 14),
          for (final session in plan.sessions)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _intensityColor(session.intensity).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: session.adapted
                    ? Border.all(
                        color: _intensityColor(session.intensity)
                            .withValues(alpha: 0.45),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text(
                      session.day,
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.focus,
                          style: GoogleFonts.dmSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (session.adaptationReason != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              session.adaptationReason!,
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: AppLayout.subtitleColor(context),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (session.minutes > 0)
                    Text(
                      '${session.minutes} min',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppLayout.subtitleColor(context),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _intensityColor(session.intensity)
                          .withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      session.intensity,
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: _intensityColor(session.intensity),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ForecastCard extends StatelessWidget {
  final TrendForecast forecast;
  const _ForecastCard({required this.forecast});

  @override
  Widget build(BuildContext context) {
    final history = forecast.history;
    final projection = forecast.projection;
    final all = [...history, ...projection];
    final minY = all.isEmpty ? 0.0 : all.reduce((a, b) => a < b ? a : b) - 1;
    final maxY = all.isEmpty ? 1.0 : all.reduce((a, b) => a > b ? a : b) + 1;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppLayout.cardDecoration(context, radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                forecast.metric,
                style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (forecast.plateauDetected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB347).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'PLATEAU',
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFC97F1F),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 130,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minY: minY,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < history.length; i++)
                        FlSpot(i.toDouble(), history[i]),
                    ],
                    isCurved: true,
                    color: AppTheme.primaryColor,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primaryColor.withValues(alpha: 0.12),
                    ),
                  ),
                  if (projection.isNotEmpty)
                    LineChartBarData(
                      spots: [
                        FlSpot((history.length - 1).toDouble(), history.last),
                        for (var i = 0; i < projection.length; i++)
                          FlSpot((history.length + i).toDouble(), projection[i]),
                      ],
                      isCurved: true,
                      color: const Color(0xFF7C6CF0),
                      barWidth: 3,
                      dashArray: const [6, 4],
                      dotData: const FlDotData(show: false),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            forecast.insight,
            style: GoogleFonts.dmSans(fontSize: 13.5, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppLayout.subtitleStyle(context).copyWith(fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.syne(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final int badge;
  const _SectionTitle(this.title, {this.badge = 0});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        if (badge > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$badge',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFD84343),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            Icons.health_and_safety_outlined,
            size: 18,
            color: AppLayout.subtitleColor(context),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'These insights are wellness guidance, not a medical diagnosis. '
              'Contact a clinician about persistent or severe symptoms.',
              style: AppLayout.subtitleStyle(context).copyWith(
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
