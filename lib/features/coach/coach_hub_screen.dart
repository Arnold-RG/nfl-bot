import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../core/models/coach_persona.dart';
import '../../core/providers/app_state.dart';
import '../../core/services/app_services.dart';
import '../home/presentation/widgets/components/ai_voice_orb.dart';
import '../live/coach_mark.dart';
import '../live/live_stage_screen.dart';
import '../shared/nf_design.dart';

/// Bot tab — signal mark stage + talk CTA.
class CoachHubScreen extends StatelessWidget {
  const CoachHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final voice = AppServices.voice;
    final short = MediaQuery.sizeOf(context).shortestSide;
    final markSize = (short * 0.42).clamp(160.0, 240.0);
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
                  'Coach',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: AppTheme.labInk,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Say “${CoachPersona.wakePhrase}” · signal reacts while Bot listens and talks',
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
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CoachMark(
                              size: markSize,
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
                            const SizedBox(height: 20),
                            Text(
                              _statusLabel(st).toUpperCase(),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: AppTheme.bronze,
                                letterSpacing: 1.4,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                NfGlassCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Text(
                        state.messages.length <= 1
                            ? 'Tap the mark or say hey bot — coaching stays tied to your data.'
                            : 'Continue your session · ${_statusLabel(voice.state)}',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.labInk,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const LiveStageScreen(),
                              ),
                            );
                          },
                          child: const Text('Talk with coach'),
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
