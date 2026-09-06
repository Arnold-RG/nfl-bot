/// The two selectable synthetic voices. There is no human likeness — the
/// coach is presented as an AI, and the choice only changes how it sounds.
enum CoachVoice { nova, atlas }

/// The coach's current disposition. Drives the voice orb's colour and energy
/// and the tone of on-device replies.
enum CoachMood { neutral, focused, encouraging, celebrating, concerned, alert }

class CoachPersona {
  final CoachVoice voice;
  final String name;
  final String tagline;
  final String greeting;

  const CoachPersona({
    required this.voice,
    required this.name,
    required this.tagline,
    required this.greeting,
  });

  static const nova = CoachPersona(
    voice: CoachVoice.nova,
    name: 'NOVA',
    tagline: 'Recovery & endurance AI',
    greeting:
        'I am here. Talk the way you would talk to a coach on a call — food, '
        'training, sleep, whatever is in front of you.',
  );

  static const atlas = CoachPersona(
    voice: CoachVoice.atlas,
    name: 'ATLAS',
    tagline: 'Strength & conditioning AI',
    greeting:
        'Ready when you are. Tell me what you ate, how you slept, or whether '
        'you should train. I will answer out loud.',
  );

  static CoachPersona forVoice(CoachVoice voice) =>
      voice == CoachVoice.nova ? nova : atlas;

  static const all = [nova, atlas];
}
