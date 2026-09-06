import 'package:flutter/material.dart';

import '../../../../../core/services/app_services.dart';
import '../screens/live_voice_screen.dart';
import 'ai_voice_orb.dart';

/// The voice orb wired to the live voice service, so wherever it appears in
/// the app it shows what the coach is actually doing right now.
class LiveCoachOrb extends StatelessWidget {
  final double size;

  /// Drops the radiating spikes, for small inline placements.
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
      builder: (context, _) => AiVoiceOrb(
        size: size,
        state: voice.state,
        amplitude: voice.amplitude,
        compact: compact,
        onTap: openOnTap
            ? () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LiveVoiceScreen()),
              )
            : null,
      ),
    );
  }
}
