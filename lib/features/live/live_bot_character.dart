import '../home/presentation/widgets/components/ai_voice_orb.dart';
import 'coach_mark.dart';

export 'coach_mark.dart' show CoachMark;

/// Back-compat wrapper — the AI coach is now the geometric [CoachMark] signal.
class LiveBotCharacter extends CoachMark {
  /// Legacy raster path (marketing still may reference it). Prefer [CoachMark].
  static const asset = 'assets/branding/bot.jpg';

  const LiveBotCharacter({
    super.key,
    required super.size,
    super.pulse = 0,
    super.state = VoiceOrbState.idle,
    super.showGlow = true,
    super.onTap,
  });
}
