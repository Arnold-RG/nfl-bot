import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';

/// Soft white card used across the CalorieLab-style surfaces.
class LabCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const LabCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final childBox = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.labCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.labBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return childBox;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: childBox,
      ),
    );
  }
}

class LabSectionTitle extends StatelessWidget {
  final String text;
  const LabSectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppTheme.labInk,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Horizontal week date strip (CalorieLab home).
class LabDateStrip extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  const LabDateStrip({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final start = today.subtract(Duration(days: today.weekday % 7));
    final days = List.generate(7, (i) => start.add(Duration(days: i)));

    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final d = days[i];
          final isSelected = DateUtils.isSameDay(d, selected);
          final isToday = DateUtils.isSameDay(d, today);
          return GestureDetector(
            onTap: () => onSelect(d),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 52,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.labInk : AppTheme.labCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? AppTheme.labInk : AppTheme.labBorder,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(d).toUpperCase().substring(0, 3),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white70 : AppTheme.labMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${d.day}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? Colors.white
                          : (isToday ? AppTheme.labOrange : AppTheme.labInk),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Big calorie ring — consumed / target / remaining.
class LabCalorieRing extends StatelessWidget {
  final int consumed;
  final int target;
  final double size;

  const LabCalorieRing({
    super.key,
    required this.consumed,
    required this.target,
    this.size = 168,
  });

  @override
  Widget build(BuildContext context) {
    final goal = target <= 0 ? 1 : target;
    final progress = (consumed / goal).clamp(0.0, 1.0);
    final remaining = (target - consumed).clamp(0, 99999);
    final pct = (progress * 100).round();

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress,
          track: AppTheme.labBorder,
          fill: AppTheme.labOrange,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                NumberFormat.decimalPattern().format(consumed),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.labInk,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'kcal',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.labMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$pct%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.labOrange,
                ),
              ),
              Text(
                '${NumberFormat.decimalPattern().format(remaining)} left',
                style: const TextStyle(fontSize: 11, color: AppTheme.labMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color track;
  final Color fill;

  _RingPainter({
    required this.progress,
    required this.track,
    required this.fill,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    final fillPaint = Paint()
      ..color = fill
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class LabMacroMini extends StatelessWidget {
  final String label;
  final num current;
  final num goal;
  final Color color;
  final IconData icon;

  const LabMacroMini({
    super.key,
    required this.label,
    required this.current,
    required this.goal,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final g = goal <= 0 ? 1.0 : goal.toDouble();
    final p = (current / g).clamp(0.0, 1.0);
    return Expanded(
      child: LabCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            SizedBox(
              width: 46,
              height: 46,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: p,
                    strokeWidth: 5,
                    backgroundColor: AppTheme.labBorder,
                    color: color,
                    strokeCap: StrokeCap.round,
                  ),
                  Icon(icon, size: 16, color: color),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${current is double ? (current as double).toStringAsFixed(0) : current}g',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppTheme.labInk,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.labMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LabAddMealButton extends StatelessWidget {
  final VoidCallback onPressed;
  const LabAddMealButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'Add Meal',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
    );
  }
}

String greetingForNow() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good Morning';
  if (h < 17) return 'Good Afternoon';
  return 'Good Evening';
}
