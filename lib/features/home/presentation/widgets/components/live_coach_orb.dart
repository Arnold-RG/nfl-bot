import 'package:flutter/material.dart';

import '../../../../../core/services/app_services.dart';
import '../../../../live/live_bot_character.dart';
import '../screens/live_voice_screen.dart';

/// Live Bot wired to the voice service — jumps, rotates, and talks everywhere.
class LiveCoachOrb extends StatelessWidget {
  final double size;

  /// Kept for API compatibility with existing call sites.
  final bool compact;

  /// Opens the full-screen conversation when tapped.
  final bool openOnTap;

  const LiveCoachOrb({
    super.key,
    this.size = 64,
    this.compact = false,
    this.openOnTap = true,
  });

  @override
  Widget build(BuildContext context) {
    final voice = AppServices.voice;

    return ListenableBuilder(
      listenable: voice,
      builder: (context, _) => LiveBotCharacter(
        size: size,
        pulse: voice.amplitude,
        state: voice.state,
        showGlow: !compact,
        onTap: openOnTap
            ? () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LiveVoiceScreen()),
              )
            : null,
      ),
    );
  }
}
