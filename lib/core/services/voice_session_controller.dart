import 'package:flutter/foundation.dart';

import '../models/coach_persona.dart';
import '../providers/app_state.dart';
import 'app_services.dart';
import 'voice_coach_service.dart';

/// Spoken back-and-forth with Bot. Activate with “hey bot”.
class VoiceSessionController extends ChangeNotifier {
  final VoiceCoachService voice;
  final AppState state;

  bool _active = false;
  bool _handsFree;
  bool _disposed = false;
  bool _awaitingWake = true;
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

  bool get isActive => _active;
  bool get handsFree => _handsFree;
  bool get awaitingWake => _awaitingWake;
  String? get notice => _notice;
  String get lastHeard => _lastHeard;
  int get turnCount => _turns;
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

  Future<void> toggle() async {
    if (_active || voice.isSpeaking) {
      await stop();
    } else {
      await start(requireWakePhrase: true);
    }
  }

  Future<void> start({bool requireWakePhrase = true}) async {
    if (_active) return;
    if (!voice.canListen) {
      _notice = voice.unavailableReason ??
          'Voice input is not available on this device.';
      notifyListeners();
      return;
    }

    _active = true;
    _awaitingWake = requireWakePhrase;
    _notice =
        requireWakePhrase ? 'Say “hey bot” to activate Bot.' : null;
    notifyListeners();
    await _runTurns();
  }

  Future<void> stop() async {
    _active = false;
    _awaitingWake = true;
    await voice.cancel();
    if (!_disposed) notifyListeners();
  }

  Future<void> _runTurns() async {
    while (_active && !_disposed) {
      final heard = await voice.listen();
      if (!_active || _disposed) break;

      if (heard == null || heard.trim().isEmpty) {
        if (_awaitingWake) {
          _notice = 'Still waiting — say “hey bot”.';
          notifyListeners();
          continue;
        }
        _notice = 'I did not catch that. Say “hey bot” or tap to try again.';
        _active = false;
        break;
      }

      if (_awaitingWake) {
        if (!CoachPersona.heardWakePhrase(heard)) {
          _notice = 'Say “hey bot” to wake me.';
          notifyListeners();
          continue;
        }
        _awaitingWake = false;
        final remainder = CoachPersona.stripWakePhrase(heard);
        _notice = null;
        notifyListeners();
        if (remainder.isEmpty) {
          final greeting = state.isInQuietHours
              ? 'Quiet hours are on. I am here if you need me.'
              : 'I am Bot. What do you need?';
          await voice.speak(greeting, voice: state.coachVoice);
          if (!_handsFree) {
            _active = false;
            break;
          }
          continue;
        }
        await _handleUtterance(remainder);
      } else {
        if (_isEndPhrase(heard)) {
          _active = false;
          _awaitingWake = true;
          _notice = null;
          notifyListeners();
          await voice.speak('Talk later.', voice: state.coachVoice);
          break;
        }
        await _handleUtterance(heard);
      }

      if (!_handsFree) {
        _active = false;
        break;
      }
    }

    if (!_disposed) {
      _active = false;
      _awaitingWake = true;
      voice.markIdle();
      notifyListeners();
    }
  }

  Future<void> _handleUtterance(String heard) async {
    if (!await AppServices.billing.consumeVoiceTurn()) {
      _notice = AppServices.billing.talkGateReason;
      _active = false;
      notifyListeners();
      await voice.speak(
        AppServices.billing.talkGateReason ?? '',
        voice: state.coachVoice,
      );
      return;
    }
    _lastHeard = heard;
    _notice = null;
    _turns++;
    notifyListeners();
    await state.sendChatMessage(heard);
  }

  static bool _isEndPhrase(String text) {
    final t = text.toLowerCase().trim();
    return {
      'stop',
      'stop listening',
      'goodbye',
      'good bye',
      'bye',
      'exit',
      'end session',
    }.contains(t);
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
