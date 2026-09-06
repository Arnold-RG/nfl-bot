import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/coach_context.dart';
import '../models/meal_recognition.dart';
import 'ai_coach_service.dart';

/// Estimates nutrition from a meal photo using the connected vision model.
///
/// There is deliberately no offline fallback that guesses at the contents of a
/// photo: without a model the app asks the user to enter the meal manually
/// rather than fabricating a result.
class FoodVisionService {
  static const _anthropicUrl = 'https://api.anthropic.com/v1/messages';
  static const _openAiUrl = 'https://api.openai.com/v1/chat/completions';
  static const _anthropicVersion = '2023-06-01';

  static const _anthropicVisionModel = 'claude-sonnet-4-20250514';
  static const _openAiVisionModel = 'gpt-4o';

  static const _prompt = '''
You are a nutrition analyst. Identify the food in this photo and estimate its nutrition.

Reply with raw JSON only, no prose and no code fences, in exactly this shape:
{
  "items": [
    {"name": "grilled chicken breast", "portion_g": 150, "calories": 248, "protein_g": 46.5, "carbs_g": 0, "fat_g": 5.4, "fiber_g": 0, "sugar_g": 0, "sodium_mg": 140}
  ],
  "insight": "one short sentence on how this fits a balanced day"
}

Rules:
- List each distinct food separately. Estimate portion sizes from visual cues such as plate and utensil size.
- Base the numbers on standard nutrition data for the portion you estimated.
- If the image contains no food, return {"items": [], "insight": "no food detected"}.
- Do not include any field other than those shown above.
''';

  final AiCoachService _coach;
  final Dio _dio;

  FoodVisionService({required AiCoachService coach, Dio? dio})
    : _coach = coach,
      _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 60),
              contentType: 'application/json',
            ),
          );

  /// True when a vision-capable model is connected.
  bool get isAvailable => _coach.credentials != null;

  Future<MealRecognition> analyze(Uint8List imageBytes) async {
    final creds = _coach.credentials;
    if (creds == null) {
      return const MealRecognition.failed(
        'Photo analysis needs an AI model. Connect one in Settings, or add this meal manually.',
      );
    }

    if (imageBytes.isEmpty) {
      return const MealRecognition.failed('That image could not be read.');
    }

    try {
      final raw = creds.provider == AiProvider.anthropic
          ? await _askAnthropic(imageBytes, creds.apiKey)
          : await _askOpenAi(imageBytes, creds.apiKey);
      return _parse(raw);
    } on DioException catch (e) {
      debugPrint('FoodVisionService request failed: ${e.message}');
      return MealRecognition.failed(_dioMessage(e));
    } catch (e) {
      debugPrint('FoodVisionService unexpected error: $e');
      return const MealRecognition.failed(
        'Could not analyze that photo. You can still add the meal manually.',
      );
    }
  }

  Future<String> _askAnthropic(Uint8List bytes, String apiKey) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _anthropicUrl,
      options: Options(
        headers: {'x-api-key': apiKey, 'anthropic-version': _anthropicVersion},
      ),
      data: {
        'model': _anthropicVisionModel,
        'max_tokens': 700,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'image',
                'source': {
                  'type': 'base64',
                  'media_type': _mediaType(bytes),
                  'data': base64Encode(bytes),
                },
              },
              {'type': 'text', 'text': _prompt},
            ],
          },
        ],
      },
    );

    final content = response.data?['content'];
    if (content is List) {
      return content
          .whereType<Map>()
          .where((block) => block['type'] == 'text')
          .map((block) => block['text']?.toString() ?? '')
          .join('\n');
    }
    return '';
  }

  Future<String> _askOpenAi(Uint8List bytes, String apiKey) async {
    final dataUrl = 'data:${_mediaType(bytes)};base64,${base64Encode(bytes)}';
    final response = await _dio.post<Map<String, dynamic>>(
      _openAiUrl,
      options: Options(headers: {'Authorization': 'Bearer $apiKey'}),
      data: {
        'model': _openAiVisionModel,
        'max_tokens': 700,
        'messages': [
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': _prompt},
              {
                'type': 'image_url',
                'image_url': {'url': dataUrl},
              },
            ],
          },
        ],
      },
    );

    final choices = response.data?['choices'];
    if (choices is List && choices.isNotEmpty) {
      return choices.first['message']?['content']?.toString() ?? '';
    }
    return '';
  }

  MealRecognition _parse(String raw) {
    final json = _extractJson(raw);
    if (json == null) {
      return const MealRecognition.failed(
        'The model returned an unexpected answer. Try another photo or add the meal manually.',
      );
    }

    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map((e) => RecognizedFood.fromJson(e.cast<String, dynamic>()))
              .where((f) => f.calories > 0)
              .toList()
        : <RecognizedFood>[];

    if (items.isEmpty) {
      return const MealRecognition.failed(
        'No food was recognized in that photo. Try a closer, well-lit shot.',
      );
    }

    return MealRecognition(
      items: items,
      insight: (json['insight'] as String?)?.trim(),
    );
  }

  /// Models sometimes wrap JSON in prose or code fences, so pull out the
  /// outermost object rather than trusting the whole response to parse.
  Map<String, dynamic>? _extractJson(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start == -1 || end <= start) return null;
    try {
      final decoded = jsonDecode(raw.substring(start, end + 1));
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  String _mediaType(Uint8List bytes) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  String _dioMessage(DioException e) {
    final status = e.response?.statusCode;
    if (status == 401 || status == 403) {
      return 'Your AI key was rejected. Check it in Settings.';
    }
    if (status == 429) {
      return 'The AI provider is rate limiting requests. Try again shortly.';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Analysis timed out. Check your connection and try again.';
    }
    return 'Could not reach the AI provider. You can add the meal manually.';
  }
}
