import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/models/coach_persona.dart';
import '../../../../../core/providers/app_state.dart';
import '../../../../../core/services/app_services.dart';
import '../../../../../core/services/voice_session_controller.dart';
import '../components/ai_voice_orb.dart';

/// Full-screen live conversation with the AI coach: speak to the orb, it
/// answers out loud, and in hands-free mode it reopens the microphone so the
/// exchange keeps going without any tapping.
class LiveVoiceScreen extends StatefulWidget {
  const LiveVoiceScreen({super.key});

  @override
  State<LiveVoiceScreen> createState() => _LiveVoiceScreenState();
}

class _LiveVoiceScreenState extends State<LiveVoiceScreen> {
  late final VoiceSessionController _session;

  @override
  void initState() {
    super.initState();
    _session = VoiceSessionController(
      voice: AppServices.voice,
      state: AppServices.appState,
      handsFree: AppServices.prefs.handsFree,
    );
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  Future<void> _speakPrompt(String text) async {
    await _session.stop();
    await AppServices.appState.sendChatMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05050F),
      body: AnimatedBuilder(
        animation: _session,
        builder: (context, _) {
          return Consumer<AppState>(
            builder: (context, state, _) => _buildBody(context, state),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppState state) {
    final voice = AppServices.voice;
    final size = MediaQuery.sizeOf(context);
    final orbSize = (size.shortestSide * 0.58).clamp(180.0, 300.0);
    final persona = state.coach;

    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.1,
          colors: [Color(0xFF0C0C22), Color(0xFF04040C)],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // Ribbons sit behind the orb and span the full width, as in the
            // reference artwork.
            Positioned(
              left: 0,
              right: 0,
              top: size.height * 0.18,
              child: VoiceWaveField(
                state: voice.state,
                amplitude: voice.amplitude,
                height: orbSize * 1.5,
              ),
            ),
            Column(
              children: [
                _Header(
                  persona: persona,
                  muted: !state.voiceEnabled,
                  onClose: () => Navigator.of(context).maybePop(),
                  onToggleMute: () => state.setVoiceEnabled(!state.voiceEnabled),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        SizedBox(height: size.height * 0.03),
                        AiVoiceOrb(
                          size: orbSize,
                          state: voice.state,
                          amplitude: voice.amplitude,
                          onTap: _session.toggle,
                        ),
                        const SizedBox(height: 18),
                        _StatusLine(
                          state: voice.state,
                          active: _session.isActive,
                          handsFree: _session.handsFree,
                        ),
                        const SizedBox(height: 14),
                        _TranscriptPanel(
                          liveTranscript: _session.liveTranscript,
                          lastHeard: _session.lastHeard,
                          reply: _lastReply(state),
                          notice:
                              _session.notice ?? _session.unavailableReason,
                          thinking: state.coachThinking,
                        ),
                        const SizedBox(height: 20),
                        if (!_session.isActive && !state.coachThinking)
                          _PromptChips(onTap: _speakPrompt),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                _Controls(
                  session: _session,
                  state: state,
                  onVoiceChanged: state.setCoachVoice,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? _lastReply(AppState state) {
    for (final m in state.messages.reversed) {
      if (!m.isUser) return m.text;
    }
    return null;
  }
}

class _Header extends StatelessWidget {
  final CoachPersona persona;
  final bool muted;
  final VoidCallback onClose;
  final VoidCallback onToggleMute;

  const _Header({
    required this.persona,
    required this.muted,
    required this.onClose,
    required this.onToggleMute,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
            tooltip: 'Close',
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  persona.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  persona.tagline,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onToggleMute,
            icon: Icon(
              muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              color: muted ? Colors.white38 : Colors.white70,
            ),
            tooltip: muted ? 'Unmute coach' : 'Mute coach',
          ),
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  final VoiceOrbState state;
  final bool active;
  final bool handsFree;

  const _StatusLine({
    required this.state,
    required this.active,
    required this.handsFree,
  });

  @override
  Widget build(BuildContext context) {
    final label = switch (state) {
      VoiceOrbState.listening => 'Listening — just talk',
      VoiceOrbState.thinking => 'Thinking',
      VoiceOrbState.speaking => 'Speaking — tap the orb to interrupt',
      VoiceOrbState.idle => active
          ? 'Ready for your next question'
          : 'Tap the orb and speak',
    };

    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (active && handsFree) ...[
          const SizedBox(height: 4),
          const Text(
            'Hands-free — the mic reopens after each answer',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ],
    );
  }
}

class _TranscriptPanel extends StatelessWidget {
  final String liveTranscript;
  final String lastHeard;
  final String? reply;
  final String? notice;
  final bool thinking;

  const _TranscriptPanel({
    required this.liveTranscript,
    required this.lastHeard,
    required this.reply,
    required this.notice,
    required this.thinking,
  });

  @override
  Widget build(BuildContext context) {
    // While the user is mid-sentence the partial transcript is the most
    // useful thing to show, so it takes priority over the last answer.
    final spoken = liveTranscript.isNotEmpty ? liveTranscript : lastHeard;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 560),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (notice != null) ...[
            Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 15,
                  color: Color(0xFFFFB74D),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    notice!,
                    style: const TextStyle(
                      color: Color(0xFFFFB74D),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (spoken.isNotEmpty) ...[
            const _PanelLabel('You said'),
            const SizedBox(height: 4),
            Text(
              spoken,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 14),
          ],
          const _PanelLabel('Coach'),
          const SizedBox(height: 4),
          if (thinking)
            const Text(
              'Working on it...',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            )
          else
            Text(
              reply ?? 'Ask me anything about your training, food, or sleep.',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }
}

class _PanelLabel extends StatelessWidget {
  final String text;

  const _PanelLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: Colors.white30,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
    );
  }
}

/// Openers the coach can answer out loud, which also give the user a way to
/// hear the voice on devices where the microphone is unavailable.
class _PromptChips extends StatelessWidget {
  final ValueChanged<String> onTap;

  const _PromptChips({required this.onTap});

  static const _prompts = [
    'Should I train today?',
    'What should I eat with the calories I have left?',
    'How was my sleep?',
    'Give me a 20 minute session',
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final p in _prompts)
          ActionChip(
            label: Text(p, style: const TextStyle(fontSize: 12)),
            onPressed: () => onTap(p),
            backgroundColor: Colors.white.withValues(alpha: 0.06),
            labelStyle: const TextStyle(color: Colors.white70),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
          ),
      ],
    );
  }
}

class _Controls extends StatelessWidget {
  final VoiceSessionController session;
  final AppState state;
  final ValueChanged<CoachVoice> onVoiceChanged;

  const _Controls({
    required this.session,
    required this.state,
    required this.onVoiceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Column(
        children: [
          SegmentedButton<CoachVoice>(
            segments: [
              for (final p in CoachPersona.all)
                ButtonSegment(
                  value: p.voice,
                  label: Text(p.name),
                  icon: const Icon(Icons.graphic_eq_rounded, size: 15),
                ),
            ],
            selected: {state.coachVoice},
            showSelectedIcon: false,
            onSelectionChanged: (s) => onVoiceChanged(s.first),
            style: ButtonStyle(
              textStyle: const WidgetStatePropertyAll(
                TextStyle(fontSize: 12, letterSpacing: 1.2),
              ),
              foregroundColor: const WidgetStatePropertyAll(Colors.white70),
              side: WidgetStatePropertyAll(
                BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ControlButton(
                icon: session.handsFree
                    ? Icons.all_inclusive_rounded
                    : Icons.touch_app_rounded,
                label: session.handsFree ? 'Hands-free' : 'Tap to talk',
                highlighted: session.handsFree,
                onTap: () => session.setHandsFree(!session.handsFree),
              ),
              const SizedBox(width: 12),
              _ControlButton(
                icon: session.isActive
                    ? Icons.stop_rounded
                    : Icons.mic_none_rounded,
                label: session.isActive ? 'Stop' : 'Talk',
                highlighted: session.isActive,
                onTap: session.toggle,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlighted;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.highlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 17),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: TextButton.styleFrom(
        foregroundColor: highlighted ? Colors.white : Colors.white54,
        backgroundColor: highlighted
            ? const Color(0xFF2F6BFF).withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.05),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
