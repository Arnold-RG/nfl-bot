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
import '../wellness/water_screen.dart';
import 'presentation/widgets/components/ai_voice_orb.dart';

/// Today — distinctive dark-bronze coach home.
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
      duration: const Duration(seconds: 5),
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
        state.userName.trim().isEmpty ? 'there' : state.userName.trim();
    final pad = NfLayout.pagePad(context);
    final maxW = NfLayout.maxContent(context);

    return Scaffold(
      backgroundColor: AppTheme.labBg,
      body: NfAmbientBackdrop(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: ListView(
                padding: EdgeInsets.fromLTRB(pad, 12, pad, 120),
                children: [
                  NfReveal(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _greeting(),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                name,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: AppTheme.labInk,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AccountScreen(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.person_outline,
                            color: AppTheme.labMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  NfReveal(
                    delayMs: 60,
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, _) {
                        return Center(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              widget.onOpenBot?.call();
                            },
                            child: LiveBotCharacter(
                              size: NfLayout.isCompact(context) ? 188 : 230,
                              state: VoiceOrbState.listening,
                              pulse: _pulse.value * 0.35,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'Say “${CoachPersona.wakePhrase}”',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppTheme.bronzeSoft,
                          ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  NfReveal(
                    delayMs: 120,
                    child: DailyBriefingCard(onTalk: widget.onOpenBot),
                  ),
                  const SizedBox(height: 12),
                  NfReveal(
                    delayMs: 160,
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
                  const SizedBox(height: 14),
                  NfReveal(
                    delayMs: 200,
                    child: NfGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NEXT BEST MOVE',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: AppTheme.bronze,
                                  letterSpacing: 1.2,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.nextBestMoveTitle,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(color: AppTheme.labInk),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            state.nextBestMoveHint,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const PlateScreen(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.photo_camera_outlined),
                                  label: const Text('Scan meal'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const WorkoutAnatomyScreen(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.accessibility_new_rounded,
                                  ),
                                  label: const Text('Form demo'),
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
                    delayMs: 240,
                    child: Row(
                      children: [
                        Expanded(
                          child: _LinkTile(
                            title: 'Diary',
                            hint: state.mealsLogged == 0
                                ? 'No meals yet'
                                : '${state.mealsLogged} today',
                            onTap: widget.onOpenDiary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _LinkTile(
                            title: 'Body',
                            hint: 'Check-ins',
                            onTap: widget.onOpenBody,
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

class _LinkTile extends StatelessWidget {
  final String title;
  final String hint;
  final VoidCallback? onTap;

  const _LinkTile({
    required this.title,
    required this.hint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NfGlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(hint, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
