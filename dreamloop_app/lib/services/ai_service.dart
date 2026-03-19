import 'dart:convert';

import 'package:dreamloop/models/session_model.dart';
import 'package:dreamloop/models/story_event_model.dart';
import 'package:dreamloop/utils/prompt_builder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class AIQuotaException implements Exception {
  final String message;
  final Duration? retryAfter;

  AIQuotaException(this.message, {this.retryAfter});

  @override
  String toString() => message;
}

/// AIService — Gemini-backed story and blueprint generation.
class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  final _uuid = const Uuid();

  String get _apiKey => dotenv.env['AI_API_KEY'] ?? '';
  String get _baseUrl =>
      dotenv.env['AI_BASE_URL'] ??
      'https://generativelanguage.googleapis.com/v1beta';
  String get _model => dotenv.env['AI_MODEL'] ?? 'gemini-2.0-flash';

  Future<Map<String, dynamic>> generateStoryBlueprint(
    SessionModel session,
  ) async {
    _assertApiKey();
    final systemPrompt = PromptBuilder.buildBlueprintSystemPrompt();
    final userPrompt = PromptBuilder.buildBlueprintPrompt(session);
    final response = await _callGeminiAPI(
      systemPrompt,
      userPrompt,
      asJson: true,
    );
    return _parseJsonResponse(response);
  }

  Future<StoryEventModel> generateStoryEvent(SessionModel session) async {
    _assertApiKey();
    final systemPrompt = PromptBuilder.buildSystemPrompt();
    final userPrompt = PromptBuilder.buildEventPrompt(session);
    final response = await _callGeminiAPI(
      systemPrompt,
      userPrompt,
      asJson: true,
    );
    final jsonResponse = _parseJsonResponse(response);

    return StoryEventModel.fromAIResponse(
      eventId: _uuid.v4(),
      sessionId: session.sessionId,
      aiResponse: jsonResponse,
      episodeNumber: session.currentEpisodeNumber,
    );
  }

  Future<String> generateSessionSummary(SessionModel session) async {
    if (_apiKey.isEmpty || _apiKey == 'your_api_key_here') {
      return _buildLocalSummary(session);
    }

    try {
      final prompt = PromptBuilder.buildSummaryPrompt(session);
      final response = await _callGeminiAPI(
        'You summarize story continuity context for an AI game. Keep output to 2-3 sentences.',
        prompt,
        asJson: false,
      );
      return response.trim();
    } catch (e) {
      debugPrint('AI summary error: $e');
      return _buildLocalSummary(session);
    }
  }

  Future<String> _callGeminiAPI(
    String systemPrompt,
    String userPrompt, {
    required bool asJson,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/models/$_model:generateContent?key=$_apiKey',
    );

    final body = {
      'system_instruction': {
        'parts': [
          {'text': systemPrompt},
        ],
      },
      'contents': [
        {
          'parts': [
            {'text': userPrompt},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.9,
        'topP': 0.95,
        'maxOutputTokens': 700,
        if (asJson) 'responseMimeType': 'application/json',
      },
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 429) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final details = data['error']?['details'];
          final retryAfter = _parseRetryAfter(details);
          throw AIQuotaException(
            'Gemini quota exceeded. Check API key billing/quota.',
            retryAfter: retryAfter,
          );
        } catch (_) {
          throw AIQuotaException('Gemini quota exceeded.');
        }
      }
      throw Exception('API error: ${response.statusCode} — ${response.body}');
    }

    final data = jsonDecode(response.body);
    final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
    return text;
  }

  Map<String, dynamic> _parseJsonResponse(String response) {
    var cleaned = response.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    }
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    cleaned = cleaned.trim();
    return jsonDecode(cleaned) as Map<String, dynamic>;
  }

  Duration? _parseRetryAfter(dynamic details) {
    if (details is! List) return null;
    for (final item in details) {
      if (item is! Map<String, dynamic>) continue;
      final retryDelay = item['retryDelay'];
      if (retryDelay is String && retryDelay.endsWith('s')) {
        final seconds = int.tryParse(retryDelay.replaceAll('s', ''));
        if (seconds != null && seconds > 0) {
          return Duration(seconds: seconds);
        }
      }
    }
    return null;
  }

  void _assertApiKey() {
    if (_apiKey.isEmpty || _apiKey == 'your_api_key_here') {
      throw Exception('AI_API_KEY missing. Configure .env to run live Gemini.');
    }
  }

  String _buildLocalSummary(SessionModel session) {
    if (session.storyHistory.isEmpty) {
      return 'Session has just started and no major choices are recorded yet.';
    }
    final recent = session.storyHistory
        .take(3)
        .map((e) => e['event'])
        .join(' ');
    return 'Recent continuity: $recent';
  }
}
