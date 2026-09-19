import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../core/providers/app_state.dart';
import '../live/live_bot_character.dart';
import '../home/presentation/widgets/components/ai_voice_orb.dart';
import '../shared/nf_design.dart';

/// Daily Bot briefing + streak — unique coach surface.
class DailyBriefingCard extends StatelessWidget {
  final VoidCallback? onTalk;

  const DailyBriefingCard({super.key, this.onTalk});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final streak = state.dayStreak;
    final brief = state.dailyBriefing;

    return NfGlassCard(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTalk?.call();
      },
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme.bronzeDeep.withValues(alpha: 0.35),
          AppTheme.labCard,
          AppTheme.labLift,
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LiveBotCharacter(
            size: 64,
            state: VoiceOrbState.idle,
            showGlow: false,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'BOT BRIEFING',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppTheme.bronzeSoft,
                            letterSpacing: 1.3,
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
                const SizedBox(height: 8),
                Text(
                  brief,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.labInk,
                        height: 1.35,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Tap to talk · say “hey bot”',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.bronze,
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

/// Quick log strip: water, steps glance, sleep.
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
            icon: Icons.water_drop_rounded,
            label: 'Water',
            value:
                '${state.hydrationLiters.toStringAsFixed(1)}L',
            color: AppTheme.labWater,
            onTap: onWater,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _VitalTile(
            icon: Icons.directions_walk_rounded,
            label: 'Steps',
            value: '${state.steps}',
            color: AppTheme.bronze,
            onTap: onMap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _VitalTile(
            icon: Icons.bedtime_rounded,
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
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: AppTheme.labCard,
            border: Border.all(color: AppTheme.labBorder),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 6),
              Text(
                value,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.labInk,
                      fontWeight: FontWeight.w700,
                    ),
              ),
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
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                Text('Log sleep',
                    style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 12),
                Text('Hours: $hours'),
                Slider(
                  value: hours.toDouble(),
                  min: 3,
                  max: 12,
                  divisions: 9,
                  activeColor: AppTheme.bronze,
                  onChanged: (v) => setModal(() => hours = v.round()),
                ),
                Text('Quality: $quality%'),
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
