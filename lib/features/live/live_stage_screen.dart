import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../core/providers/app_state.dart';
import '../../core/services/app_services.dart';
import '../../core/services/voice_session_controller.dart';
import '../../features/home/presentation/widgets/components/ai_voice_orb.dart';
import '../shared/app_ui.dart';
import 'brand_mark.dart';

/// Live voice coach — looks like a normal mobile call / chat screen.
class LiveStageScreen extends StatefulWidget {
  const LiveStageScreen({super.key});

  @override
  State<LiveStageScreen> createState() => _LiveStageScreenState();
}

class _LiveStageScreenState extends State<LiveStageScreen> {
  late final VoiceSessionController _session;
  final _typed = TextEditingController();
  final _scroll = ScrollController();

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
    _typed.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _sendTyped() async {
    final text = _typed.text.trim();
    if (text.isEmpty) return;
    _typed.clear();
    if (!await AppServices.billing.consumeVoiceTurn()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppServices.billing.talkGateReason ?? '')),
      );
      return;
    }
    await AppServices.appState.sendChatMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final copy = AppServices.locale.copy;
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([_session, AppServices.voice, AppServices.billing]),
      builder: (context, _) {
        return Consumer<AppState>(
          builder: (context, state, _) {
            final voice = AppServices.voice;
            final status = switch (voice.state) {
              VoiceOrbState.listening => copy.t('listening'),
              VoiceOrbState.thinking => copy.t('thinking'),
              VoiceOrbState.speaking => copy.t('speaking'),
              VoiceOrbState.idle =>
                _session.isActive ? copy.t('handsFree') : 'Tap the mic to talk',
            };
            final spoken = _session.liveTranscript.isNotEmpty
                ? _session.liveTranscript
                : _session.lastHeard;
            final reply = _lastReply(state);
            final notice = _session.notice ??
                (!AppServices.billing.canTalk
                    ? AppServices.billing.talkGateReason
                    : null) ??
                _session.unavailableReason;

            return Scaffold(
              body: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'NFL BOT',
                                  style: theme.textTheme.titleLarge,
                                ),
                                Text(
                                  '${state.coach.name} · ${AppServices.locale.language.nativeName}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          FilterChip(
                            selected: _session.handsFree,
                            label: Text(
                              _session.handsFree ? 'Hands-free' : 'Tap to talk',
                              style: const TextStyle(fontSize: 12),
                            ),
                            onSelected: (v) => _session.setHandsFree(v),
                            showCheckmark: false,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                        children: [
                          const SizedBox(height: 8),
                          Center(
                            child: GestureDetector(
                              onTap: _session.toggle,
                              child: VoiceArtwork(
                                size: 148,
                                pulse: voice.amplitude,
                                state: voice.state,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            status,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 18),
                          if (notice != null)
                            AppCard(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    size: 18,
                                    color: AppTheme.warningColor,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      notice,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: AppTheme.warningColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (notice != null) const SizedBox(height: 12),
                          if (spoken.isNotEmpty) ...[
                            _Bubble(
                              label: copy.t('youSaid'),
                              text: spoken,
                              alignEnd: true,
                            ),
                            const SizedBox(height: 10),
                          ],
                          _Bubble(
                            label: copy.t('coach'),
                            text: state.coachThinking
                                ? '…'
                                : (reply ??
                                    'Ask about food, training, sleep, or how you feel today.'),
                            alignEnd: false,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        border: Border(
                          top: BorderSide(color: theme.dividerColor),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _typed,
                              minLines: 1,
                              maxLines: 3,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendTyped(),
                              decoration: InputDecoration(
                                hintText: 'Message your coach…',
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: _sendTyped,
                            style: IconButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.arrow_upward_rounded),
                          ),
                          const SizedBox(width: 6),
                          IconButton.filled(
                            onPressed: _session.toggle,
                            style: IconButton.styleFrom(
                              backgroundColor: _session.isActive
                                  ? AppTheme.errorColor
                                  : AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              fixedSize: const Size(52, 52),
                            ),
                            icon: Icon(
                              _session.isActive
                                  ? Icons.stop_rounded
                                  : Icons.mic_rounded,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String? _lastReply(AppState state) {
    for (final m in state.messages.reversed) {
      if (!m.isUser) return m.text;
    }
    return null;
  }
}

class _Bubble extends StatelessWidget {
  final String label;
  final String text;
  final bool alignEnd;

  const _Bubble({
    required this.label,
    required this.text,
    required this.alignEnd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = alignEnd
        ? AppTheme.primaryColor.withValues(alpha: isDark ? 0.22 : 0.10)
        : (isDark ? AppTheme.darkCard : Colors.white);
    final border = alignEnd
        ? Colors.transparent
        : (isDark ? Colors.white10 : AppTheme.dividerColor);

    return Align(
      alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.86,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(alignEnd ? 16 : 4),
              bottomRight: Radius.circular(alignEnd ? 4 : 16),
            ),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(text, style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }
}
