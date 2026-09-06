import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../../config/routes.dart';
import '../../../../../core/providers/app_state.dart';
import '../../../../../core/services/app_services.dart';
import '../../../../../core/services/voice_coach_service.dart';
import '../components/ai_voice_orb.dart';
import '../components/live_coach_orb.dart';
import 'live_voice_screen.dart';

class ChatScreen extends StatefulWidget {
  final VoiceCoachService voiceService;
  const ChatScreen({super.key, required this.voiceService});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    Future.delayed(const Duration(milliseconds: 400), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    _scrollToEnd();

    // Speaking is handled inside sendChatMessage, so typed and spoken
    // questions are answered out loud in exactly the same way.
    await context.read<AppState>().sendChatMessage(text);
    if (!mounted) return;
    _scrollToEnd();
  }

  /// Captures one spoken question here in the transcript view. The continuous
  /// back-and-forth lives on the full-screen voice experience.
  Future<void> _dictate() async {
    final voice = widget.voiceService;
    if (!voice.canListen) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            voice.unavailableReason ??
                'Voice input is not available on this device.',
          ),
        ),
      );
      return;
    }

    if (voice.isListening) {
      await voice.stopListening();
      return;
    }

    final heard = await voice.listen();
    if (!mounted || heard == null || heard.trim().isEmpty) return;
    _controller.text = heard;
    await _send();
  }

  Future<void> _attachImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    await context.read<AppState>().analyzeImageInChat(bytes);
    _scrollToEnd();
  }

  void _openLiveVoice() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LiveVoiceScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    const LiveCoachOrb(size: 60),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.coach.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            state.coach.tagline,
                            style: const TextStyle(
                              color: Color(0xFF5F6F72),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const _CoachModeChip(),
                        ],
                      ),
                    ),
                    IconButton.filled(
                      onPressed: _openLiveVoice,
                      icon: const Icon(Icons.graphic_eq_rounded),
                      tooltip: 'Live voice conversation',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  itemCount:
                      state.messages.length + (state.coachThinking ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i >= state.messages.length) {
                      return _ThinkingBubble(name: state.coach.name);
                    }
                    return _ChatBubble(
                      message: state.messages[i],
                      onReplay: () => widget.voiceService.speak(
                        state.messages[i].text,
                        voice: state.coachVoice,
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _attachImage,
                      icon: const Icon(Icons.attach_file_rounded),
                      tooltip: 'Attach food image',
                    ),
                    ListenableBuilder(
                      listenable: widget.voiceService,
                      builder: (context, _) {
                        final listening = widget.voiceService.isListening;
                        return IconButton(
                          onPressed: _dictate,
                          icon: Icon(
                            listening
                                ? Icons.mic_rounded
                                : Icons.mic_none_rounded,
                            color: listening
                                ? Colors.red
                                : const Color(0xFF00C853),
                          ),
                          tooltip: listening ? 'Stop' : 'Speak your question',
                        );
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onSubmitted: (_) => _send(),
                        decoration: InputDecoration(
                          hintText: 'Type or tap the mic...',
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: state.coachThinking
                          ? const Color(0xFF9AA5A1)
                          : const Color(0xFF00C853),
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: state.coachThinking ? null : _send,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: state.coachThinking
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback onReplay;

  const _ChatBubble({required this.message, required this.onReplay});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: message.isUser
              ? const Color(0xFF4CC9A8)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: message.isUser ? Colors.white : null,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (!message.isUser)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: onReplay,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.volume_up_rounded,
                          size: 13,
                          color: Color(0xFF8A9490),
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Play again',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8A9490),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (message.notice != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 13,
                      color: Color(0xFF8A9490),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        message.notice!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF8A9490),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Shows whether replies come from the live model or on-device knowledge, so
/// the answer's provenance is never ambiguous.
class _CoachModeChip extends StatelessWidget {
  const _CoachModeChip();

  @override
  Widget build(BuildContext context) {
    final live = AppServices.coach.isModelBacked;
    final color = live ? const Color(0xFF00C853) : const Color(0xFF8A9490);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              live ? Icons.auto_awesome_rounded : Icons.offline_bolt_rounded,
              size: 12,
              color: color,
            ),
            const SizedBox(width: 5),
            Text(
              live ? 'Live AI coach' : 'On-device coach · tap to connect',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  final String name;

  const _ThinkingBubble({required this.name});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AiVoiceOrb(
              size: 30,
              state: VoiceOrbState.thinking,
              compact: true,
            ),
            const SizedBox(width: 10),
            Text(
              '$name is thinking…',
              style: const TextStyle(fontSize: 13, color: Color(0xFF8A9490)),
            ),
          ],
        ),
      ),
    );
  }
}
