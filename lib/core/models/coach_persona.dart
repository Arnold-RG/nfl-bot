/// The two selectable synthetic voices. There is no human likeness — the
/// coach is presented as an AI named Bot.
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

  /// Wake phrase users say to activate Bot.
  static const wakePhrase = 'hey bot';

  static const nova = CoachPersona(
    voice: CoachVoice.nova,
    name: 'Bot',
    tagline: 'Your AI coach — say “hey bot” to start',
    greeting:
        'I am Bot. Say hey bot anytime you want me. Ask about food, training, '
        'or recovery — I answer from your data when you have logged it.',
  );

  static const atlas = CoachPersona(
    voice: CoachVoice.atlas,
    name: 'Bot',
    tagline: 'Your AI coach — say “hey bot” to start',
    greeting:
        'Bot here. Say hey bot to wake me. Tell me what you need — I stay '
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
    return t.contains('hey bot');
  }

  /// Strip wake phrase from the start of a transcript.
  static String stripWakePhrase(String text) {
    return text
        .replaceFirst(
          RegExp(r'^\s*hey[\s,.-]*bot[\s,.-]*', caseSensitive: false),
          '',
        )
        .trim();
  }
}
