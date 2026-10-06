import 'package:flutter/material.dart';

import '../home/presentation/widgets/components/ai_voice_orb.dart';
import 'coach_mark.dart';

class BrandMark {
  static const asset = 'assets/branding/bot.jpg';
}

/// Live coach artwork — geometric signal mark.
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
    return CoachMark(
      size: size,
      pulse: pulse,
      state: state,
    );
  }
}
