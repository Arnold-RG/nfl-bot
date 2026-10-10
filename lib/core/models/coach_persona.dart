/// Selectable synthetic voices. The coach is presented as Elvora's AI.
enum CoachVoice { nova, atlas }

/// The coach's current disposition.
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

  /// Wake phrase users say to activate the coach.
  static const wakePhrase = 'hey elvora';

  static const nova = CoachPersona(
    voice: CoachVoice.nova,
    name: 'Elvora',
    tagline: 'Your AI coach — say “hey elvora” to start',
    greeting:
        'I am Elvora. Say hey elvora anytime. Ask about food, training, '
        'or recovery — I answer from your data when you have logged it.',
  );

  static const atlas = CoachPersona(
    voice: CoachVoice.atlas,
    name: 'Elvora',
    tagline: 'Your AI coach — say “hey elvora” to start',
    greeting:
        'Elvora here. Say hey elvora to wake me. Tell me what you need — I stay '
        'quiet until you call.',
  );

  static CoachPersona forVoice(CoachVoice voice) =>
      voice == CoachVoice.nova ? nova : atlas;

  static const all = [nova, atlas];

  /// True when [text] contains the wake phrase (case-insensitive).
  static bool heardWakePhrase(String text) {
    final t = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return t.contains('hey elvora');
  }

  /// Strip wake phrase from the start of a transcript.
  static String stripWakePhrase(String text) {
    return text
        .replaceFirst(
          RegExp(r'^\s*hey[\s,.-]*elvora[\s,.-]*', caseSensitive: false),
          '',
        )
        .trim();
  }
}
