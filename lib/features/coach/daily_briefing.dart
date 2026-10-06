import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../core/providers/app_state.dart';
import '../shared/nf_design.dart';

/// Daily Bot briefing — text-led, no redundant mascot.
class DailyBriefingCard extends StatelessWidget {
  final VoidCallback? onTalk;

  const DailyBriefingCard({super.key, this.onTalk});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final streak = state.dayStreak;
    final brief = state.dailyBriefing;
    final theme = Theme.of(context);

    return NfGlassCard(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTalk?.call();
      },
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'TODAY’S BRIEFING',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.bronze,
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              NfMetricPill(
                icon: Icons.local_fire_department_rounded,
                label: 'STREAK',
                value: '$streak d',
                color: AppTheme.copper,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            brief,
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppTheme.labInk,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick log strip: water, steps, sleep.
class QuickVitalStrip extends StatelessWidget {
  final VoidCallback? onWater;
  final VoidCallback? onMap;
  final VoidCallback? onSleep;

  const QuickVitalStrip({
    super.key,
    this.onWater,
    this.onMap,
    this.onSleep,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Row(
      children: [
        Expanded(
          child: _VitalTile(
            icon: Icons.water_drop_outlined,
            label: 'Water',
            value: '${state.hydrationLiters.toStringAsFixed(1)}L',
            color: AppTheme.labWater,
            onTap: onWater,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _VitalTile(
            icon: Icons.directions_walk_rounded,
            label: 'Steps',
            value: '${state.steps}',
            color: AppTheme.bronze,
            onTap: onMap,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _VitalTile(
            icon: Icons.bedtime_outlined,
            label: 'Sleep',
            value: state.hasSleepLog ? '${state.sleepHours}h' : 'Log',
            color: AppTheme.copper,
            onTap: onSleep,
          ),
        ),
      ],
    );
  }
}

class _VitalTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _VitalTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            color: AppTheme.labCard,
            border: Border.all(color: AppTheme.labBorder),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.labInk,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple sleep logger sheet.
Future<void> showSleepLogSheet(BuildContext context) async {
  var hours = 7;
  var quality = 75;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppTheme.labCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModal) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.labBorder,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Log sleep', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                Text('Hours: $hours',
                    style: Theme.of(ctx).textTheme.bodyMedium),
                Slider(
                  value: hours.toDouble(),
                  min: 3,
                  max: 12,
                  divisions: 9,
                  activeColor: AppTheme.bronze,
                  onChanged: (v) => setModal(() => hours = v.round()),
                ),
                Text('Quality: $quality%',
                    style: Theme.of(ctx).textTheme.bodyMedium),
                Slider(
                  value: quality.toDouble(),
                  min: 20,
                  max: 100,
                  divisions: 16,
                  activeColor: AppTheme.copper,
                  onChanged: (v) => setModal(() => quality = v.round()),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () {
                    ctx.read<AppState>().logSleep(hours, quality);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save sleep'),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
