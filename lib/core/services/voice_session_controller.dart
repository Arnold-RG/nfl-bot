import 'package:flutter/foundation.dart';

import '../providers/app_state.dart';
import 'app_services.dart';
import 'voice_coach_service.dart';

/// Drives a spoken back-and-forth with the coach.
///
/// One turn is: open the microphone, transcribe what was said, ask the coach,
/// speak the answer. In hands-free mode the microphone reopens automatically
/// when the coach stops talking, so the user never has to tap between turns.
class VoiceSessionController extends ChangeNotifier {
  final VoiceCoachService voice;
  final AppState state;

  bool _active = false;
  bool _handsFree;
  bool _disposed = false;
  String? _notice;
  String _lastHeard = '';
  int _turns = 0;

  VoiceSessionController({
    required this.voice,
    required this.state,
    bool handsFree = true,
  }) : _handsFree = handsFree {
    voice.addListener(_onVoiceChanged);
  }

  /// True while a conversation is running, including the pauses between turns.
  bool get isActive => _active;
  bool get handsFree => _handsFree;

  /// Guidance for the user, e.g. when nothing was heard.
  String? get notice => _notice;

  /// The last thing the user said, for on-screen confirmation.
  String get lastHeard => _lastHeard;

  /// Completed exchanges in this session.
  int get turnCount => _turns;

  /// What the user is saying right now, while still speaking.
  String get liveTranscript => voice.partialTranscript;

  bool get canUseVoice => voice.canListen;
  String? get unavailableReason => voice.unavailableReason;

  void _onVoiceChanged() {
    if (!_disposed) notifyListeners();
  }

  Future<void> setHandsFree(bool value) async {
    _handsFree = value;
    await AppServices.prefs.setHandsFree(value);
    notifyListeners();
  }

  /// Tap-to-talk and tap-to-interrupt in one action, so the orb always does
  /// the obvious thing for whatever the coach is currently doing.
  Future<void> toggle() async {
    if (_active || voice.isSpeaking) {
      await stop();
    } else {
      await start();
    }
  }

  Future<void> start() async {
    if (_active) return;
    if (!voice.canListen) {
      _notice =
          voice.unavailableReason ??
          'Voice input is not available on this device.';
      notifyListeners();
      return;
    }

    _active = true;
    _notice = null;
    notifyListeners();

    await _runTurns();
  }

  Future<void> stop() async {
    _active = false;
    await voice.cancel();
    if (!_disposed) notifyListeners();
  }

  Future<void> _runTurns() async {
    while (_active && !_disposed) {
      final heard = await voice.listen();

      // The user may have stopped the session while the mic was open.
      if (!_active || _disposed) break;

      if (heard == null || heard.trim().isEmpty) {
        _notice = 'I did not catch that. Tap the orb and try again.';
        _active = false;
        break;
      }

      if (_isEndPhrase(heard)) {
        _active = false;
        _notice = null;
        notifyListeners();
        await voice.speak(
          'Talk to you later, ${state.userName}.',
          voice: state.coachVoice,
        );
        break;
      }

      if (!await AppServices.billing.consumeVoiceTurn()) {
        _notice = AppServices.billing.talkGateReason;
        _active = false;
        notifyListeners();
        await voice.speak(
          AppServices.billing.talkGateReason ?? '',
          voice: state.coachVoice,
        );
        break;
      }

      _lastHeard = heard;
      _notice = null;
      _turns++;
      notifyListeners();

      await state.sendChatMessage(heard);

      if (!_handsFree) {
        _active = false;
        break;
      }
    }

    if (!_disposed) {
      _active = false;
      voice.markIdle();
      notifyListeners();
    }
  }

  static bool _isEndPhrase(String text) {
    final t = text.toLowerCase().trim();
    const enders = {
      'stop',
      'stop listening',
      'goodbye',
      'good bye',
      'bye',
      'thanks bye',
      'that is all',
      "that's all",
      'end session',
      'we are done',
      'exit',
      'au revoir',
      'arrête',
      'arrete',
      'adios',
      'adiós',
      'hasta luego',
      'tschüss',
      'auf wiedersehen',
      'до свидания',
      'пока',
      'стоп',
      'do widzenia',
      'koniec',
      'مع السلامة',
      '再见',
      '结束',
    };
    return enders.contains(t);
  }

  @override
  void dispose() {
    _disposed = true;
    _active = false;
    voice.removeListener(_onVoiceChanged);
    voice.cancel();
    super.dispose();
  }
}
