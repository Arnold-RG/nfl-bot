import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../models/coach_context.dart';
import '../models/coach_persona.dart';
import '../../features/home/presentation/widgets/components/ai_voice_orb.dart';
import 'app_services.dart';

/// Speech in and speech out for the AI coach.
///
/// Notifies listeners on every state and level change so the voice orb can
/// render what is actually happening rather than an animation loop.
class VoiceCoachService extends ChangeNotifier {
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _neural = AudioPlayer();
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 45),
    ),
  );

  bool _sttReady = false;
  bool _ttsReady = false;
  String _speechLocale = 'en_US';
  VoiceOrbState _state = VoiceOrbState.idle;
  double _amplitude = 0;
  String _partialTranscript = '';
  String? _unavailableReason;

  Completer<void>? _speechCompleter;
  Completer<String?>? _listenCompleter;

  /// True when the microphone is usable on this device and permission held.
  bool get canListen => _sttReady;
  bool get canSpeak => _ttsReady;
  bool get isListening => _state == VoiceOrbState.listening;
  bool get isSpeaking => _state == VoiceOrbState.speaking;

  VoiceOrbState get state => _state;

  /// Live input/output level, 0..1, for the orb's reactive burst.
  double get amplitude => _amplitude;

  /// Words recognised so far in the current utterance.
  String get partialTranscript => _partialTranscript;

  /// Why voice is unavailable, or null when it works.
  String? get unavailableReason => _unavailableReason;

  Future<bool> init() async {
    try {
      _sttReady = await _stt.initialize(
        onStatus: _onSttStatus,
        onError: (e) {
          debugPrint('VoiceCoach STT error: ${e.errorMsg}');
          _finishListening(null);
        },
      );
      if (!_sttReady) {
        _unavailableReason =
            'Microphone access was denied or speech recognition is not '
            'available on this device.';
      }
    } catch (e) {
      debugPrint('VoiceCoach STT init failed: $e');
      _sttReady = false;
      _unavailableReason = 'Speech recognition could not start on this device.';
    }

    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.47);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      // Lets `speak` be awaited to completion on platforms that support it.
      await _tts.awaitSpeakCompletion(true);
      _tts.setCompletionHandler(_onSpeechComplete);
      _tts.setCancelHandler(_onSpeechComplete);
      _tts.setErrorHandler((msg) {
        debugPrint('VoiceCoach TTS error: $msg');
        _onSpeechComplete();
      });
      // Progress drives the orb while speaking, since TTS exposes no level.
      _tts.setProgressHandler((text, start, end, word) {
        if (_state != VoiceOrbState.speaking) return;
        final span = text.isEmpty ? 1 : text.length;
        // A gentle oscillation around the word boundary reads as speech.
        _setAmplitude(0.35 + 0.35 * ((end % 7) / 7) + 0.1 * (start / span));
      });
      _ttsReady = true;
    } catch (e) {
      debugPrint('VoiceCoach TTS init failed: $e');
      _ttsReady = false;
    }

    _neural.onPlayerComplete.listen((_) => _onSpeechComplete());
    notifyListeners();
    return _sttReady || _ttsReady;
  }

  /// Matches microphone and spoken voice to the member's language.
  Future<void> applyLanguage(String speechLocale) async {
    _speechLocale = speechLocale.replaceAll('-', '_');
    try {
      await _tts.setLanguage(speechLocale);
    } catch (_) {
      try {
        await _tts.setLanguage(_speechLocale);
      } catch (_) {}
    }
    await _preferHumanVoice();
  }

  Future<void> _preferHumanVoice() async {
    try {
      final raw = await _tts.getVoices;
      if (raw is! List) return;
      final wanted = _speechLocale.toLowerCase().replaceAll('-', '_');
      final lang = wanted.split('_').first;
      final voices = raw.whereType<Map>().toList();
      Map? pick;
      for (final voice in voices) {
        final name = '${voice['name']}'.toLowerCase();
        final locale = '${voice['locale']}'.toLowerCase().replaceAll('-', '_');
        final human = name.contains('neural') ||
            name.contains('premium') ||
            name.contains('enhanced') ||
            name.contains('natural') ||
            name.contains('samantha') ||
            name.contains('ava') ||
            name.contains('daniel');
        if (locale.startsWith(wanted) && human) {
          pick = voice;
          break;
        }
        if (locale.startsWith(lang) && human) pick ??= voice;
        if (locale.startsWith(wanted)) pick ??= voice;
      }
      if (pick != null) {
        await _tts.setVoice({
          'name': '${pick['name']}',
          'locale': '${pick['locale']}',
        });
      }
    } catch (e) {
      debugPrint('VoiceCoach voice pick failed: $e');
    }
  }

  void _onSttStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      // A final result may still be delivered; only close if none arrived.
      if (_listenCompleter != null && !_listenCompleter!.isCompleted) {
        _finishListening(
          _partialTranscript.trim().isEmpty ? null : _partialTranscript.trim(),
        );
      }
    }
  }

  void _setState(VoiceOrbState next) {
    if (_state == next) return;
    _state = next;
    notifyListeners();
  }

  void _setAmplitude(double value) {
    final clamped = value.clamp(0.0, 1.0);
    if ((clamped - _amplitude).abs() < 0.02) return;
    _amplitude = clamped;
    notifyListeners();
  }

  /// Marks the coach as composing a reply, between hearing and speaking.
  void markThinking() => _setState(VoiceOrbState.thinking);

  void markIdle() {
    _setAmplitude(0);
    _setState(VoiceOrbState.idle);
  }

  /// Speaks [text] and completes when the utterance finishes.
  Future<void> speak(String text, {CoachVoice? voice}) async {
    final clean = _stripForSpeech(text);
    if (clean.isEmpty) return;

    await stopSpeaking();
    if (voice != null) {
      await _tts.setPitch(_pitchFor(voice));
      await _tts.setSpeechRate(_rateFor(voice));
    }

    _setState(VoiceOrbState.speaking);
    _setAmplitude(0.55);

    final completer = Completer<void>();
    _speechCompleter = completer;

    final neural = await _speakNeural(clean, voice ?? CoachVoice.nova);
    if (!neural && _ttsReady) {
      try {
        await _tts.speak(clean);
      } catch (e) {
        debugPrint('VoiceCoach speak failed: $e');
        _onSpeechComplete();
      }
    } else if (!neural) {
      _onSpeechComplete();
    }

    await completer.future.timeout(
      const Duration(minutes: 2),
      onTimeout: _onSpeechComplete,
    );
  }

  Future<bool> _speakNeural(String text, CoachVoice voice) async {
    try {
      final creds = AppServices.coach.credentials;
      if (creds == null || creds.provider != AiProvider.openai) return false;

      final response = await _dio.post<List<int>>(
        'https://api.openai.com/v1/audio/speech',
        options: Options(
          headers: {'Authorization': 'Bearer ${creds.apiKey}'},
          responseType: ResponseType.bytes,
        ),
        data: {
          'model': 'tts-1-hd',
          'voice': voice == CoachVoice.atlas ? 'onyx' : 'nova',
          'input': text,
          'speed': 0.97,
        },
      );
      final bytes = Uint8List.fromList(response.data ?? const []);
      if (bytes.isEmpty) return false;
      await _neural.stop();
      await _neural.play(BytesSource(bytes, mimeType: 'audio/mpeg'));
      return true;
    } catch (e) {
      debugPrint('VoiceCoach neural TTS fallback: $e');
      return false;
    }
  }

  void _onSpeechComplete() {
    final completer = _speechCompleter;
    _speechCompleter = null;
    if (completer != null && !completer.isCompleted) completer.complete();
    if (_state == VoiceOrbState.speaking) markIdle();
  }

  Future<void> stopSpeaking() async {
    if (_speechCompleter == null && _state != VoiceOrbState.speaking) return;
    try {
      await _tts.stop();
    } catch (_) {}
    try {
      await _neural.stop();
    } catch (_) {}
    _onSpeechComplete();
  }

  /// Listens for a single utterance and returns the transcript, or null if
  /// nothing intelligible was heard.
  Future<String?> listen({
    Duration maxDuration = const Duration(seconds: 30),
    Duration pauseFor = const Duration(seconds: 3),
  }) async {
    if (!_sttReady || _state == VoiceOrbState.listening) return null;

    // Never listen to our own voice.
    await stopSpeaking();

    _partialTranscript = '';
    _setState(VoiceOrbState.listening);

    final completer = Completer<String?>();
    _listenCompleter = completer;

    try {
      await _stt.listen(
        onResult: (result) {
          _partialTranscript = result.recognizedWords;
          notifyListeners();
          if (result.finalResult) {
            _finishListening(
              result.recognizedWords.trim().isEmpty
                  ? null
                  : result.recognizedWords.trim(),
            );
          }
        },
        onSoundLevelChange: (level) {
          // Platforms report wildly different ranges, so normalise loosely
          // against a typical speaking band rather than a fixed scale.
          _setAmplitude(((level + 2) / 12).clamp(0.0, 1.0));
        },
        listenOptions: SpeechListenOptions(
          localeId: _speechLocale,
          listenFor: maxDuration,
          pauseFor: pauseFor,
          partialResults: true,
          cancelOnError: true,
        ),
      );
    } catch (e) {
      debugPrint('VoiceCoach listen failed: $e');
      _finishListening(null);
    }

    return completer.future;
  }

  void _finishListening(String? transcript) {
    final completer = _listenCompleter;
    _listenCompleter = null;
    _setAmplitude(0);
    if (_state == VoiceOrbState.listening) _setState(VoiceOrbState.idle);
    if (completer != null && !completer.isCompleted) {
      completer.complete(transcript);
    }
  }

  Future<void> stopListening() async {
    if (_state != VoiceOrbState.listening) return;
    try {
      await _stt.stop();
    } catch (_) {
      // Already stopped.
    }
    _finishListening(
      _partialTranscript.trim().isEmpty ? null : _partialTranscript.trim(),
    );
  }

  /// Aborts whatever the voice layer is doing right now.
  Future<void> cancel() async {
    await stopSpeaking();
    if (_state == VoiceOrbState.listening) {
      try {
        await _stt.cancel();
      } catch (_) {
        // Already stopped.
      }
      _finishListening(null);
    }
    markIdle();
  }

  /// Markdown and emoji read badly aloud, so they are stripped first.
  static String _stripForSpeech(String text) {
    return text
        .replaceAll(RegExp(r'\*\*|__|[*_`#>]'), '')
        .replaceAll(RegExp(r'^\s*[-•]\s*', multiLine: true), '')
        .replaceAll(
          RegExp(
            r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}]',
            unicode: true,
          ),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static double _pitchFor(CoachVoice voice) =>
      voice == CoachVoice.nova ? 1.18 : 0.92;

  static double _rateFor(CoachVoice voice) =>
      voice == CoachVoice.nova ? 0.50 : 0.46;

  @override
  void dispose() {
    _stt.cancel();
    _tts.stop();
    _neural.dispose();
    super.dispose();
  }
}
