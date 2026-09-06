import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../intelligence/coach_knowledge.dart';
import '../models/coach_context.dart';

/// Conversational coach backed by a large language model, with a local
/// knowledge fallback so the app still answers usefully offline.
class AiCoachService {
  static const _keyApiKey = 'ai_api_key';
  static const _keyProvider = 'ai_provider';

  static const _anthropicUrl = 'https://api.anthropic.com/v1/messages';
  static const _openAiUrl = 'https://api.openai.com/v1/chat/completions';
  static const _anthropicVersion = '2023-06-01';

  static const anthropicModel = 'claude-sonnet-4-20250514';
  static const openAiModel = 'gpt-4o-mini';

  final Dio _dio;
  final FlutterSecureStorage _storage;

  AiProvider _provider = AiProvider.offline;
  String? _apiKey;
  bool _initialized = false;

  AiCoachService({Dio? dio, FlutterSecureStorage? storage})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 40),
              contentType: 'application/json',
            )),
        _storage = storage ?? const FlutterSecureStorage();

  AiProvider get provider => _provider;
  bool get isModelBacked => _provider != AiProvider.offline && _apiKey != null;
  bool get initialized => _initialized;

  /// Credentials for other model-backed features, so the user only has to
  /// configure a key once. Null when no model is connected.
  ({AiProvider provider, String apiKey})? get credentials =>
      isModelBacked ? (provider: _provider, apiKey: _apiKey!) : null;

  Future<void> init() async {
    try {
      _apiKey = await _storage.read(key: _keyApiKey);
      final stored = await _storage.read(key: _keyProvider);
      _provider = AiProvider.values.firstWhere(
        (p) => p.name == stored,
        orElse: () => _apiKey == null ? AiProvider.offline : AiProvider.anthropic,
      );
    } catch (e) {
      // Secure storage is unavailable on some desktop/web setups.
      debugPrint('AiCoachService: secure storage unavailable ($e)');
      _provider = AiProvider.offline;
    }
    _initialized = true;
  }

  Future<void> configure({
    required AiProvider provider,
    required String apiKey,
  }) async {
    _provider = provider;
    _apiKey = apiKey.trim().isEmpty ? null : apiKey.trim();
    try {
      if (_apiKey == null) {
        await _storage.delete(key: _keyApiKey);
      } else {
        await _storage.write(key: _keyApiKey, value: _apiKey);
      }
      await _storage.write(key: _keyProvider, value: provider.name);
    } catch (e) {
      debugPrint('AiCoachService: could not persist credentials ($e)');
    }
  }

  Future<void> clearCredentials() async {
    _apiKey = null;
    _provider = AiProvider.offline;
    try {
      await _storage.delete(key: _keyApiKey);
      await _storage.write(key: _keyProvider, value: AiProvider.offline.name);
    } catch (_) {
      // Nothing persisted; in-memory reset is enough.
    }
  }

  /// Asks the coach a question. Falls back to local knowledge on any failure
  /// so the user always gets an answer.
  Future<CoachReply> ask({
    required String userMessage,
    required CoachContext context,
    List<({String role, String text})> history = const [],
  }) async {
    if (!isModelBacked) {
      return _offlineReply(userMessage, context);
    }

    try {
      final text = _provider == AiProvider.anthropic
          ? await _askAnthropic(userMessage, context, history)
          : await _askOpenAi(userMessage, context, history);

      if (text.trim().isEmpty) {
        return _offlineReply(userMessage, context);
      }

      return CoachReply(
        text: text.trim(),
        mood: CoachKnowledge.moodFor(userMessage, text),
        fromModel: true,
      );
    } on DioException catch (e) {
      final detail = e.response?.data is Map
          ? (e.response!.data as Map)['error']?.toString() ?? e.message
          : e.message;
      debugPrint('AiCoachService request failed: $detail');
      final fallback = _offlineReply(userMessage, context);
      return CoachReply(
        text: fallback.text,
        mood: fallback.mood,
        fromModel: false,
        error: 'Live coach unavailable — answered from on-device knowledge.',
      );
    } catch (e) {
      debugPrint('AiCoachService unexpected error: $e');
      final fallback = _offlineReply(userMessage, context);
      return CoachReply(
        text: fallback.text,
        mood: fallback.mood,
        fromModel: false,
        error: 'Live coach unavailable — answered from on-device knowledge.',
      );
    }
  }

  Future<String> _askAnthropic(
    String userMessage,
    CoachContext context,
    List<({String role, String text})> history,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _anthropicUrl,
      options: Options(headers: {
        'x-api-key': _apiKey,
        'anthropic-version': _anthropicVersion,
      }),
      data: {
        'model': anthropicModel,
        'max_tokens': 700,
        'system': _systemPrompt(context),
        'messages': [
          for (final turn in history)
            {'role': turn.role == 'user' ? 'user' : 'assistant', 'content': turn.text},
          {'role': 'user', 'content': userMessage},
        ],
      },
    );

    final content = response.data?['content'];
    if (content is List && content.isNotEmpty) {
      return content
          .whereType<Map>()
          .where((block) => block['type'] == 'text')
          .map((block) => block['text']?.toString() ?? '')
          .join('\n');
    }
    return '';
  }

  Future<String> _askOpenAi(
    String userMessage,
    CoachContext context,
    List<({String role, String text})> history,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _openAiUrl,
      options: Options(headers: {'Authorization': 'Bearer $_apiKey'}),
      data: {
        'model': openAiModel,
        'max_tokens': 700,
        'messages': [
          {'role': 'system', 'content': _systemPrompt(context)},
          for (final turn in history)
            {'role': turn.role == 'user' ? 'user' : 'assistant', 'content': turn.text},
          {'role': 'user', 'content': userMessage},
        ],
      },
    );

    final choices = response.data?['choices'];
    if (choices is List && choices.isNotEmpty) {
      return choices.first['message']?['content']?.toString() ?? '';
    }
    return '';
  }

  String _systemPrompt(CoachContext context) {
    return '''
You are ${context.coach.name}, the live voice trainer inside NFL Live. You sound like a calm, sharp human coach on a phone call — never robotic, never theatrical. You are openly an AI.

CRITICAL: Answer entirely in ${context.languageName}. Match the member's language even if they mix languages.

Your reply is spoken out loud:
- Two short spoken paragraphs at most. Warm, specific, conversational.
- No markdown, no lists, no emoji, no stage directions.
- Say numbers the way a person would say them.
- Use the live data below. Give one next action.
- You are not a doctor. For chest pain, fainting, or alarming vitals, tell them to contact a clinician.

Live data for ${context.userName} right now:
${context.toPromptBlock()}
''';
  }

  CoachReply _offlineReply(String userMessage, CoachContext context) {
    final text = CoachKnowledge.answer(userMessage, context);
    return CoachReply(
      text: text,
      mood: CoachKnowledge.moodFor(userMessage, text),
      fromModel: false,
    );
  }
}
