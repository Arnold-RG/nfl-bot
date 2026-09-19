import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../core/models/coach_persona.dart';
import '../../core/providers/app_state.dart';
import '../../core/services/app_services.dart';
import '../home/presentation/widgets/components/ai_voice_orb.dart';
import '../live/live_bot_character.dart';
import '../live/live_stage_screen.dart';
import '../shared/nf_design.dart';

/// Bot tab — huge reactive coach stage.
class CoachHubScreen extends StatelessWidget {
  const CoachHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final voice = AppServices.voice;
    final short = MediaQuery.sizeOf(context).shortestSide;
    final botSize = (short * 0.68).clamp(240.0, 380.0);
    final pad = NfLayout.pagePad(context);

    return Scaffold(
      backgroundColor: AppTheme.labBg,
      body: NfAmbientBackdrop(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(pad, 8, pad, 16),
            child: Column(
              children: [
                Text(
                  'Bot',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: AppTheme.labInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mouth moves while Bot talks · say “${CoachPersona.wakePhrase}”',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                Expanded(
                  child: ListenableBuilder(
                    listenable: voice,
                    builder: (context, _) {
                      final st = voice.state == VoiceOrbState.idle
                          ? VoiceOrbState.listening
                          : voice.state;
                      return Center(
                        child: LiveBotCharacter(
                          size: botSize,
                          pulse: voice.amplitude,
                          state: st,
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const LiveStageScreen(),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                NfGlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        state.messages.length <= 1
                            ? 'Tap Bot or say hey bot — I only coach from your data.'
                            : 'Continue · ${_statusLabel(voice.state)}',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.labInk,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton.icon(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const LiveStageScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.graphic_eq_rounded),
                          label: const Text('Talk with Bot'),
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
    );
  }

  String _statusLabel(VoiceOrbState s) => switch (s) {
        VoiceOrbState.listening => 'listening',
        VoiceOrbState.thinking => 'thinking',
        VoiceOrbState.speaking => 'speaking',
        VoiceOrbState.idle => 'ready',
      };
}
