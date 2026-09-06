import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../../config/app_theme.dart';
import '../../../../../config/routes.dart';
import '../../../../../core/models/health_intelligence.dart';
import '../../../../../core/providers/app_state.dart';
import '../../../../../core/services/app_services.dart';
import '../../../../../core/theme/app_layout.dart';
import '../components/live_coach_orb.dart';
import '../components/macro_card.dart';
import '../components/quick_action_card.dart';
import '../components/coach_card.dart';
import '../components/meal_card.dart';
import 'profile_screen.dart';
import 'progress_screen.dart';
import 'settings_screen.dart';

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  String _formatSteps(int steps) {
    if (steps >= 1000) return '${(steps / 1000).toStringAsFixed(1)}k';
    return steps.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final caloriesLeft =
            (state.calorieGoal - state.caloriesConsumed).clamp(0, 99999);
        final progress = state.caloriesConsumed / state.calorieGoal;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final trackColor = isDark
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0xFFD8E6E0);

        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [AppTheme.darkBg, const Color(0xFF101A16)]
                  : [const Color(0xFFE6F4EE), AppTheme.backgroundColor],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _greeting(),
                              style: AppLayout.subtitleStyle(context),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              state.userName,
                              style: GoogleFonts.syne(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).colorScheme.onSurface,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            // Both screens are tab bodies without their own
                            // Scaffold, so pushed copies need one for an
                            // opaque background and a back button.
                            builder: (_) => Scaffold(
                              appBar: AppBar(title: const Text('Settings')),
                              body: const SettingsScreen(),
                            ),
                          ),
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.white.withValues(alpha: 0.7),
                        ),
                        icon: const Icon(Icons.settings_rounded),
                      ),
                      const SizedBox(width: 8),
                      const LiveCoachOrb(size: 56),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (!state.hasProfile) ...[
                    const _ProfilePrompt(),
                    const SizedBox(height: 14),
                  ],
                  const _ReadinessStrip(),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: AppLayout.cardDecoration(context, radius: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Daily calories',
                              style: AppLayout.subtitleStyle(context)
                                  .copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$caloriesLeft left',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              NumberFormat('#,###').format(state.caloriesConsumed),
                              style: GoogleFonts.syne(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                '/ ${NumberFormat('#,###').format(state.calorieGoal)} kcal',
                                style: AppLayout.subtitleStyle(context)
                                    .copyWith(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            minHeight: 11,
                            backgroundColor: trackColor,
                            valueColor: const AlwaysStoppedAnimation(
                              AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: MacroCard(
                          label: 'Protein',
                          value: '${state.proteinG.toStringAsFixed(0)}g',
                          color: const Color(0xFFFFA85C),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: MacroCard(
                          label: 'Carbs',
                          value: '${state.carbsG.toStringAsFixed(0)}g',
                          color: const Color(0xFF4CC9A8),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: MacroCard(
                          label: 'Fat',
                          value: '${state.fatG.toStringAsFixed(0)}g',
                          color: const Color(0xFFE07A8A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => state.addHydration(0.25),
                          child: QuickActionCard(
                            label: 'Hydration',
                            value: '${state.hydrationLiters.toStringAsFixed(1)}L',
                            icon: Icons.water_drop_rounded,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: QuickActionCard(
                          label: 'Steps',
                          value: _formatSteps(state.steps),
                          icon: Icons.directions_walk_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: QuickActionCard(
                          label: 'Sleep',
                          value: state.hasSleepLog
                              ? '${state.sleepHours}h'
                              : '—',
                          icon: Icons.bedtime_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => Scaffold(
                          appBar: AppBar(title: const Text('Progress')),
                          body: const ProgressScreen(),
                        ),
                      ),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1B5E45), Color(0xFF4CC9A8)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.28),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.insights_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'View Progress',
                                  style: GoogleFonts.syne(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${state.workoutsCompleted} workouts · ${state.mealsLogged} meals logged',
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white.withValues(alpha: 0.78),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StepsChart(
                    steps: state.steps,
                    goal: state.stepGoal,
                    trackColor: trackColor,
                  ),
                  const SizedBox(height: 18),
                  const CoachCard(),
                  const SizedBox(height: 22),
                  Text(
                    "Today's meals",
                    style: GoogleFonts.syne(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (state.todayMeals.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: AppLayout.cardDecoration(context, radius: 18),
                      child: Row(
                        children: [
                          Icon(
                            Icons.restaurant_menu_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Nothing logged yet. Add a meal from the Nutrition tab.',
                              style: AppLayout.subtitleStyle(context),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...state.todayMeals.reversed.map(
                      (m) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MealCard(
                          meal: _mealSlot(m.loggedAt),
                          time: DateFormat.jm().format(m.loggedAt),
                          title: m.foodName,
                          calories: '${m.calories} kcal',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  /// Labels a meal by when it was logged rather than asking the user to pick.
  static String _mealSlot(DateTime at) {
    if (at.hour < 11) return 'Breakfast';
    if (at.hour < 15) return 'Lunch';
    if (at.hour < 18) return 'Snack';
    return 'Dinner';
  }
}

/// Prompts for body metrics while targets are still generic defaults.
class _ProfilePrompt extends StatelessWidget {
  const _ProfilePrompt();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppLayout.cardDecoration(context, radius: 22).copyWith(
          border: Border.all(
            color: const Color(0xFFFFB347).withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.straighten_rounded,
              color: Color(0xFFFFB347),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personalize your targets',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Add height, weight, age and activity level to replace the '
                    'generic defaults below.',
                    style: AppLayout.subtitleStyle(context)
                        .copyWith(fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

/// Readiness, watch status, and unread alerts in one glanceable row.
class _ReadinessStrip extends StatelessWidget {
  const _ReadinessStrip();

  Color _bandColor(ReadinessBand band) {
    switch (band) {
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
    return ListenableBuilder(
      listenable: AppServices.intelligence,
      builder: (context, _) {
        final readiness = AppServices.intelligence.readiness;
        final state = context.watch<AppState>();
        if (readiness == null) {
          return _ReadinessUnavailable(
            reason: AppServices.intelligence.readinessUnavailableReason ??
                'Not enough data yet for a readiness score.',
          );
        }

        final color = _bandColor(readiness.band);
        final alerts = AppServices.intelligence.actionableAlertCount;

        return InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => Navigator.pushNamed(context, AppRoutes.intelligence),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: AppLayout.cardDecoration(context, radius: 22).copyWith(
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: readiness.score / 100,
                          strokeWidth: 6,
                          backgroundColor: color.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                      Text(
                        '${readiness.score}',
                        style: GoogleFonts.syne(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Readiness · ${readiness.bandLabel}',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        readiness.recommendationLabel,
                        style: AppLayout.subtitleStyle(context)
                            .copyWith(fontSize: 12.5),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _MiniChip(
                            icon: state.watchConnected
                                ? Icons.watch_rounded
                                : Icons.watch_off_rounded,
                            label: state.watchConnected
                                ? '${state.watchHeartRate} bpm'
                                : 'No watch',
                            color: state.watchConnected
                                ? const Color(0xFFFF6B6B)
                                : const Color(0xFF8A9490),
                          ),
                          if (alerts > 0)
                            _MiniChip(
                              icon: Icons.notifications_active_rounded,
                              label: '$alerts alert${alerts == 1 ? '' : 's'}',
                              color: const Color(0xFFFFA726),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Stands in for the readiness score before there is data to compute one.
class _ReadinessUnavailable extends StatelessWidget {
  final String reason;
  const _ReadinessUnavailable({required this.reason});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => Navigator.pushNamed(context, AppRoutes.watch),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppLayout.cardDecoration(context, radius: 22),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF8A9490).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.monitor_heart_outlined,
                color: Color(0xFF8A9490),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Readiness not available yet',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reason,
                    style: AppLayout.subtitleStyle(context)
                        .copyWith(fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepsChart extends StatelessWidget {
  final int steps;
  final int goal;
  final Color trackColor;

  const _StepsChart({
    required this.steps,
    required this.goal,
    required this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (steps / goal).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppLayout.cardDecoration(context, radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step progress',
            style: GoogleFonts.syne(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$steps / $goal steps today',
            style: AppLayout.subtitleStyle(context).copyWith(fontSize: 13),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 36,
                sections: [
                  PieChartSectionData(
                    value: progress * 100,
                    color: AppTheme.primaryColor,
                    title: '${(progress * 100).toInt()}%',
                    radius: 40,
                    titleStyle: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: (1 - progress) * 100,
                    color: trackColor,
                    title: '',
                    radius: 36,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
