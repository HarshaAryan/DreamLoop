import 'package:cloud_firestore/cloud_firestore.dart';

class StoryEventModel {
  final String eventId;
  final String sessionId;
  final String title;
  final String description;
  final List<String> slides;
  final List<String> options;
  final String tone; // 'cute', 'adventure', 'bonding', 'mystery', 'horror'
  final String mood; // 'cozy', 'mysterious', 'adventurous', 'spooky', 'magical'
  final String storyState; // 'ongoing' | 'ending' | 'ended'
  final int episodeNumber;
  final DateTime createdAt;

  StoryEventModel({
    required this.eventId,
    required this.sessionId,
    required this.title,
    required this.description,
    required this.slides,
    required this.options,
    this.tone = 'adventure',
    this.mood = 'cozy',
    this.storyState = 'ongoing',
    this.episodeNumber = 1,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory StoryEventModel.fromMap(Map<String, dynamic> map) {
    return StoryEventModel(
      eventId: map['event_id'] ?? '',
      sessionId: map['session_id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      slides: List<String>.from(map['slides'] ?? []),
      options: List<String>.from(map['options'] ?? []),
      tone: map['tone'] ?? 'adventure',
      mood: map['mood'] ?? 'cozy',
      storyState: map['story_state'] ?? 'ongoing',
      episodeNumber: map['episode_number'] ?? 1,
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'event_id': eventId,
      'session_id': sessionId,
      'title': title,
      'description': description,
      'slides': slides,
      'options': options,
      'tone': tone,
      'mood': mood,
      'story_state': storyState,
      'episode_number': episodeNumber,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  /// Create from AI response JSON
  factory StoryEventModel.fromAIResponse({
    required String eventId,
    required String sessionId,
    required Map<String, dynamic> aiResponse,
    int episodeNumber = 1,
  }) {
    final rawSlides = aiResponse['slides'];
    final parsedSlides = rawSlides is List
        ? rawSlides
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList()
        : <String>[];
    final fallbackDescription =
        aiResponse['event'] ?? aiResponse['description'] ?? '';
    final finalSlides = parsedSlides.isNotEmpty
        ? parsedSlides
        : [fallbackDescription.toString()];

    return StoryEventModel(
      eventId: eventId,
      sessionId: sessionId,
      title: aiResponse['title'] ?? 'A new event',
      description: fallbackDescription.toString(),
      slides: finalSlides,
      options: List<String>.from(aiResponse['options'] ?? []),
      tone: aiResponse['tone'] ?? 'adventure',
      mood: aiResponse['mood'] ?? 'cozy',
      storyState: aiResponse['story_state'] ?? 'ongoing',
      episodeNumber: episodeNumber,
    );
  }
}
