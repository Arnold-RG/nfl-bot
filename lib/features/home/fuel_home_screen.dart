import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../core/models/coach_persona.dart';
import '../../core/providers/app_state.dart';
import '../account/account_screen.dart';
import '../activity/map_track_screen.dart';
import '../coach/daily_briefing.dart';
import '../live/live_bot_character.dart';
import '../plate/plate_screen.dart';
import '../shared/nf_design.dart';
import '../train/workout_anatomy_screen.dart';
import '../wellness/body_coach_screen.dart';
import '../wellness/water_screen.dart';
import 'presentation/widgets/components/ai_voice_orb.dart';

/// Today — one clear composition: greet → coach → vitals → next move.
class FuelHomeScreen extends StatefulWidget {
  final VoidCallback? onOpenDiary;
  final VoidCallback? onOpenBody;
  final VoidCallback? onOpenBot;

  const FuelHomeScreen({
    super.key,
    this.onOpenDiary,
    this.onOpenBody,
    this.onOpenBot,
  });

  @override
  State<FuelHomeScreen> createState() => _FuelHomeScreenState();
}

class _FuelHomeScreenState extends State<FuelHomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final name =
        state.userName.trim().isEmpty ? 'Athlete' : state.userName.trim();
    final pad = NfLayout.pagePad(context);
    final maxW = NfLayout.maxContent(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.labBg,
      body: NfAmbientBackdrop(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: ListView(
                padding: EdgeInsets.fromLTRB(pad, 8, pad, 120),
                children: [
                  NfReveal(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NFL BOT',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: AppTheme.bronze,
                                  letterSpacing: 1.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${_greeting()},',
                                style: theme.textTheme.bodyMedium,
                              ),
                              Text(
                                name,
                                style: theme.textTheme.displaySmall?.copyWith(
                                  color: AppTheme.labInk,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Account',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AccountScreen(),
                              ),
                            );
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.labCard,
                            side: const BorderSide(color: AppTheme.labBorder),
                          ),
                          icon: const Icon(
                            Icons.person_outline_rounded,
                            color: AppTheme.labMuted,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  NfReveal(
                    delayMs: 40,
                    child: _CoachHero(
                      pulse: _pulse,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        widget.onOpenBot?.call();
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  NfReveal(
                    delayMs: 80,
                    child: DailyBriefingCard(onTalk: widget.onOpenBot),
                  ),
                  const SizedBox(height: 14),
                  NfReveal(
                    delayMs: 110,
                    child: QuickVitalStrip(
                      onWater: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const WaterScreen()),
                      ),
                      onMap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MapTrackScreen(),
                        ),
                      ),
                      onSleep: () => showSleepLogSheet(context),
                    ),
                  ),
                  const SizedBox(height: 22),
                  NfReveal(
                    delayMs: 140,
                    child: const NfSectionLabel('Next move'),
                  ),
                  NfReveal(
                    delayMs: 160,
                    child: NfGlassCard(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.nextBestMoveTitle,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: AppTheme.labInk,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            state.nextBestMoveHint,
                            style: theme.textTheme.bodyMedium,
                          ),
                          if (state.bodyGoalSummary.trim().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              state.bodyGoalSummary,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.bronzeSoft,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const PlateScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text('Scan meal'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const BodyCoachScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text('Body Coach'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  NfReveal(
                    delayMs: 200,
                    child: Row(
                      children: [
                        Expanded(
                          child: _QuietLink(
                            title: 'Diary',
                            hint: state.mealsLogged == 0
                                ? 'No meals yet'
                                : '${state.mealsLogged} logged',
                            onTap: widget.onOpenDiary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuietLink(
                            title: 'Body',
                            hint: 'Check-ins',
                            onTap: widget.onOpenBody,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuietLink(
                            title: 'Form',
                            hint: 'Demos',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const WorkoutAnatomyScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _CoachHero extends StatelessWidget {
  final AnimationController pulse;
  final VoidCallback onTap;

  const _CoachHero({required this.pulse, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NfGlassCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: pulse,
            builder: (context, _) {
              return LiveBotCharacter(
                size: 72,
                state: VoiceOrbState.listening,
                pulse: pulse.value * 0.28,
                showGlow: false,
              );
            },
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Talk to Bot',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.labInk,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Say “${CoachPersona.wakePhrase}” or tap to open',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.graphic_eq_rounded,
            color: AppTheme.bronze,
            size: 22,
          ),
        ],
      ),
    );
  }
}

class _QuietLink extends StatelessWidget {
  final String title;
  final String hint;
  final VoidCallback? onTap;

  const _QuietLink({
    required this.title,
    required this.hint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NfGlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.labInk,
                ),
          ),
          const SizedBox(height: 4),
          Text(hint, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
