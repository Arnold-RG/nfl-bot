import 'package:flutter/material.dart';

import '../home/presentation/widgets/components/ai_voice_orb.dart';
import 'live_bot_character.dart';

class BrandMark {
  static const asset = LiveBotCharacter.asset;
}

/// Live Bot coach artwork — jump / rotate / talk (API kept for call sites).
class VoiceArtwork extends StatelessWidget {
  final double size;
  final double pulse;
  final VoiceOrbState state;

  const VoiceArtwork({
    super.key,
    required this.size,
    this.pulse = 0,
    this.state = VoiceOrbState.idle,
  });

  @override
  Widget build(BuildContext context) {
    return LiveBotCharacter(
      size: size,
      pulse: pulse,
      state: state,
    );
  }
}
