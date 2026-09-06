import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../core/engines/activity_engine.dart';
import '../../core/engines/body_engine.dart';
import '../../core/providers/app_state.dart';
import '../../core/services/app_services.dart';
import '../account/account_screen.dart';
import '../plate/plate_screen.dart';
import '../shared/app_ui.dart';
import '../train/train_screen.dart';

/// Pacer-style Home: big step ring, calorie / active / distance, sparkline.
class HomeHubScreen extends StatefulWidget {
  final ValueChanged<int>? onOpenTab;
  final VoidCallback? onOpenAdd;

  const HomeHubScreen({super.key, this.onOpenTab, this.onOpenAdd});

  @override
  State<HomeHubScreen> createState() => _HomeHubScreenState();
}

class _HomeHubScreenState extends State<HomeHubScreen> {
  int _subTab = 1; // 0 Nutrition · 1 Home · 2 GPS

  Future<void> _askNow(BuildContext context, AppState state) async {
    final decision = AppServices.health.whatShouldIDoNow();
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('What should I do now?',
                  style: Theme.of(ctx).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(decision.title, style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(decision.reason),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (decision.kind.name == 'hydrate') {
                    state.addHydration(0.25);
                    return;
                  }
                  if (decision.openTab != null) {
                    widget.onOpenTab?.call(decision.openTab!);
                  }
                },
                child: Text(decision.cta),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openAddSheet(BuildContext context, AppState state) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.restaurant_outlined),
              title: const Text('Log food'),
              onTap: () {
                Navigator.pop(ctx);
                widget.onOpenTab?.call(2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.directions_walk_rounded),
              title: const Text('Log walk (20 min)'),
              onTap: () {
                Navigator.pop(ctx);
                state.logActivity(
                  type: ActivityType.walk,
                  minutes: 20,
                  steps: 2200,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.monitor_weight_outlined),
              title: const Text('Log weight'),
              onTap: () {
                Navigator.pop(ctx);
                widget.onOpenTab?.call(3);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Scan meal'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PlateScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.fitness_center_rounded),
              title: const Text('Start workout'),
              onTap: () {
                Navigator.pop(ctx);
                widget.onOpenTab?.call(1);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showGpsSheet(
    BuildContext context,
    AppState state,
    num km,
    String activeLabel,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('GPS activity', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 12),
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.pacerBlue.withValues(alpha: 0.15),
                      AppTheme.pacerBlueSoft.withValues(alpha: 0.35),
                    ],
                  ),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.map_outlined,
                          size: 42, color: AppTheme.pacerBlue),
                      SizedBox(height: 8),
                      Text('Route map — native GPS in device builds'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Today’s movement',
                        style: Theme.of(ctx).textTheme.titleMedium),
                    Text(
                      DateFormat('MMM d · HH:mm').format(DateTime.now()),
                      style: Theme.of(ctx).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCol(
                            value: km.toStringAsFixed(2),
                            label: 'Km',
                            color: AppTheme.pacerBlue,
                          ),
                        ),
                        Expanded(
                          child: _MetricCol(
                            value: activeLabel,
                            label: 'Duration',
                            color: AppTheme.pacerGreen,
                          ),
                        ),
                        Expanded(
                          child: _MetricCol(
                            value: km > 0 ? "8'40\"" : '--',
                            label: 'Pace',
                            color: AppTheme.navy,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          state.logActivity(
                            type: ActivityType.walk,
                            minutes: 20,
                            steps: 2200,
                          );
                        },
                        child: const Text('Start walk'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final day = BodyEngine.snapshot(state);
    final theme = Theme.of(context);
    final steps = day.steps;
    final goal = day.stepGoal;
    final pct = goal == 0 ? 0.0 : (steps / goal).clamp(0.0, 1.0);
    final km = (steps * 0.00078).clamp(0, 99);
    final activeMin = (steps / 100).round().clamp(0, 24 * 60);
    final activeLabel = activeMin >= 60
        ? '${activeMin ~/ 60}h ${activeMin % 60}m'
        : '${activeMin}m';
    final spark = _sparkFromSteps(steps);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => widget.onOpenTab?.call(4),
                icon: const Icon(Icons.search_rounded),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _TopTab(
                      label: 'Nutrition',
                      selected: _subTab == 0,
                      onTap: () {
                        setState(() => _subTab = 0);
                        widget.onOpenTab?.call(2);
                      },
                    ),
                    _TopTab(
                      label: 'Home',
                      selected: _subTab == 1,
                      onTap: () => setState(() => _subTab = 1),
                    ),
                    _TopTab(
                      label: 'GPS',
                      selected: _subTab == 2,
                      onTap: () {
                        setState(() => _subTab = 2);
                        _showGpsSheet(context, state, km, activeLabel);
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded,
                        color: AppTheme.pacerOrange, size: 20),
                    const SizedBox(width: 2),
                    Text(
                      '${day.streakDays}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AccountScreen()),
                ),
                icon: const Icon(Icons.person_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _MetricCol(
                        value: '${day.caloriesBurned}',
                        label: 'Calories',
                        color: AppTheme.pacerOrange,
                      ),
                    ),
                    Expanded(
                      child: _MetricCol(
                        value: activeLabel,
                        label: 'Active',
                        color: AppTheme.pacerGreen,
                      ),
                    ),
                    Expanded(
                      child: _MetricCol(
                        value: km.toStringAsFixed(1),
                        label: 'Km',
                        color: AppTheme.pacerBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 220,
                  width: 220,
                  child: CustomPaint(
                    painter: _StepRingPainter(
                      progress: pct,
                      track: AppTheme.pacerBlueSoft.withValues(alpha: 0.35),
                      progressColor: AppTheme.pacerBlue,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat('EEE, MMM d').format(DateTime.now()),
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            NumberFormat.decimalPattern().format(steps),
                            style: theme.textTheme.displayMedium?.copyWith(
                              color: AppTheme.pacerBlue,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Step Goal: ${NumberFormat.decimalPattern().format(goal)}',
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            '${(pct * 100).round()}% Completed',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppTheme.pacerBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _SparklinePainter(
                      points: spark,
                      color: AppTheme.pacerBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _QuickIcon(
                  icon: Icons.show_chart_rounded,
                  onTap: () => widget.onOpenTab?.call(3),
                ),
                _QuickIcon(
                  icon: Icons.location_on_outlined,
                  onTap: () =>
                      _showGpsSheet(context, state, km, activeLabel),
                ),
                _QuickIcon(
                  icon: Icons.add_rounded,
                  filled: true,
                  onTap: widget.onOpenAdd ??
                      () => _openAddSheet(context, state),
                ),
                _QuickIcon(
                  icon: Icons.search_rounded,
                  onTap: () => widget.onOpenTab?.call(4),
                ),
                _QuickIcon(
                  icon: Icons.photo_camera_outlined,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PlateScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => _askNow(context, state),
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('What should I do now?'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: AppTheme.navy,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            onTap: () => widget.onOpenTab?.call(1),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.gravlVolt.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.fitness_center_rounded,
                      color: AppTheme.navy),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(day.workoutTitle,
                          style: theme.textTheme.titleMedium),
                      Text(
                        'Train · ${day.workoutFocus} · ${day.workoutMinutes} min',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    state.generateWorkout(
                      focus: day.workoutFocus.split('+').first.trim(),
                      minutes: day.workoutMinutes,
                    );
                    widget.onOpenTab?.call(1);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TrainSessionLauncher(),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.gravlVolt,
                    foregroundColor: AppTheme.navy,
                  ),
                  child: const Text('Start'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            onTap: () => widget.onOpenTab?.call(2),
            child: Column(
              children: [
                MacroBar(
                  label: 'Calories',
                  current: day.caloriesConsumed,
                  goal: day.calorieGoal,
                  color: AppTheme.pacerOrange,
                ),
                MacroBar(
                  label: 'Protein',
                  current: day.proteinG,
                  goal: day.proteinGoal,
                  color: AppTheme.pacerBlue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<double> _sparkFromSteps(int steps) {
    final seed = steps.clamp(1, 20000);
    final rnd = math.Random(seed);
    final list = <double>[];
    var v = 0.25;
    for (var i = 0; i < 24; i++) {
      v = (v + (rnd.nextDouble() - 0.42) * 0.22).clamp(0.08, 1.0);
      if (i > 18) v = (v + steps / 20000).clamp(0.1, 1.0);
      list.add(v);
    }
    return list;
  }
}

class _TopTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TopTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppTheme.pacerBlue : AppTheme.textLight,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 3,
              width: selected ? 28 : 0,
              decoration: BoxDecoration(
                color: AppTheme.pacerBlue,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCol extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _MetricCol({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _QuickIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _QuickIcon({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return Material(
        color: AppTheme.pacerBlue,
        shape: const CircleBorder(),
        elevation: 2,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const SizedBox(
            width: 56,
            height: 56,
            child: Icon(Icons.add_rounded, color: Colors.white, size: 30),
          ),
        ),
      );
    }
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: AppTheme.textLight),
    );
  }
}

class _StepRingPainter extends CustomPainter {
  final double progress;
  final Color track;
  final Color progressColor;

  _StepRingPainter({
    required this.progress,
    required this.track,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 10;
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    final progPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _StepRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _SparklinePainter extends CustomPainter {
  final List<double> points;
  final Color color;

  _SparklinePainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = size.width * (i / (points.length - 1));
      final y = size.height * (1 - points[i]);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) => true;
}
