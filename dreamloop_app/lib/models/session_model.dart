import 'package:cloud_firestore/cloud_firestore.dart';

class SessionModel {
  final String sessionId;
  final List<String> userIds;
  final String currentEventId;
  final String currentEvent;
  final List<String> eventSlides;
  final List<String> eventOptions;
  final Map<String, String> userChoices; // {userId: selectedOption}
  final List<Map<String, dynamic>> storyHistory;
  final String sessionSummary;
  final String worldTheme;
  final String mood;
  final String pacingStage; // 'early', 'middle', 'later'
  final String inviteCode;
  final int eventCount;
  final String status; // 'active' | 'ended'
  final String storySeed;
  final Map<String, dynamic> storyBlueprint;
  final DateTime storyStartedAt;
  final int minEpisodes;
  final int minDurationDays;
  final DateTime createdAt;
  final DateTime updatedAt;

  SessionModel({
    required this.sessionId,
    required this.userIds,
    this.currentEventId = '',
    this.currentEvent = '',
    this.eventSlides = const [],
    this.eventOptions = const [],
    this.userChoices = const {},
    this.storyHistory = const [],
    this.sessionSummary = '',
    this.worldTheme = 'enchanted_forest',
    this.mood = 'cozy',
    this.pacingStage = 'early',
    this.inviteCode = '',
    this.eventCount = 0,
    this.status = 'active',
    this.storySeed = '',
    this.storyBlueprint = const {},
    DateTime? storyStartedAt,
    this.minEpisodes = 20,
    this.minDurationDays = 4,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       storyStartedAt = storyStartedAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Determine pacing stage based on event count
  String get computedPacingStage {
    if (eventCount < 5) return 'early';
    if (eventCount < 12) return 'middle';
    return 'later';
  }

  int get beatsPerEpisode {
    final raw = storyBlueprint['beats_per_episode'];
    if (raw is int && raw > 0) return raw;
    if (raw is String) {
      final parsed = int.tryParse(raw);
      if (parsed != null && parsed > 0) return parsed;
    }
    return 3;
  }

  int get currentEpisodeNumber {
    if (eventCount <= 0) return 1;
    return ((eventCount - 1) ~/ beatsPerEpisode) + 1;
  }

  int episodeNumberForEventCount(int count) {
    if (count <= 0) return 1;
    return ((count - 1) ~/ beatsPerEpisode) + 1;
  }

  /// Check if both users have submitted choices
  bool get bothUsersChosen =>
      userIds.length == 2 &&
      userChoices.length == 2 &&
      userIds.every((id) => userChoices.containsKey(id));

  /// Check if a specific user has chosen
  bool hasUserChosen(String userId) => userChoices.containsKey(userId);

  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      sessionId: map['session_id'] ?? '',
      userIds: List<String>.from(map['user_ids'] ?? []),
      currentEventId: map['current_event_id'] ?? '',
      currentEvent: map['current_event'] ?? '',
      eventSlides: List<String>.from(map['event_slides'] ?? []),
      eventOptions: List<String>.from(map['event_options'] ?? []),
      userChoices: Map<String, String>.from(map['user_choices'] ?? {}),
      storyHistory: List<Map<String, dynamic>>.from(
        (map['story_history'] ?? []).map((e) => Map<String, dynamic>.from(e)),
      ),
      sessionSummary: map['session_summary'] ?? '',
      worldTheme: map['world_theme'] ?? 'enchanted_forest',
      mood: map['mood'] ?? 'cozy',
      pacingStage: map['pacing_stage'] ?? 'early',
      inviteCode: map['invite_code'] ?? '',
      eventCount: map['event_count'] ?? 0,
      status: map['status'] ?? 'active',
      storySeed: map['story_seed'] ?? '',
      storyBlueprint: Map<String, dynamic>.from(map['story_blueprint'] ?? {}),
      storyStartedAt: (map['story_started_at'] as Timestamp?)?.toDate(),
      minEpisodes: map['min_episodes'] ?? 20,
      minDurationDays: map['min_duration_days'] ?? 4,
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'session_id': sessionId,
      'user_ids': userIds,
      'current_event_id': currentEventId,
      'current_event': currentEvent,
      'event_slides': eventSlides,
      'event_options': eventOptions,
      'user_choices': userChoices,
      'story_history': storyHistory,
      'session_summary': sessionSummary,
      'world_theme': worldTheme,
      'mood': mood,
      'pacing_stage': pacingStage,
      'invite_code': inviteCode,
      'event_count': eventCount,
      'status': status,
      'story_seed': storySeed,
      'story_blueprint': storyBlueprint,
      'story_started_at': Timestamp.fromDate(storyStartedAt),
      'min_episodes': minEpisodes,
      'min_duration_days': minDurationDays,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  SessionModel copyWith({
    String? currentEventId,
    String? currentEvent,
    List<String>? eventSlides,
    List<String>? eventOptions,
    Map<String, String>? userChoices,
    List<Map<String, dynamic>>? storyHistory,
    String? sessionSummary,
    String? worldTheme,
    String? mood,
    String? pacingStage,
    int? eventCount,
    List<String>? userIds,
    String? status,
    String? storySeed,
    Map<String, dynamic>? storyBlueprint,
    DateTime? storyStartedAt,
    int? minEpisodes,
    int? minDurationDays,
    DateTime? updatedAt,
  }) {
    return SessionModel(
      sessionId: sessionId,
      userIds: userIds ?? this.userIds,
      currentEventId: currentEventId ?? this.currentEventId,
      currentEvent: currentEvent ?? this.currentEvent,
      eventSlides: eventSlides ?? this.eventSlides,
      eventOptions: eventOptions ?? this.eventOptions,
      userChoices: userChoices ?? this.userChoices,
      storyHistory: storyHistory ?? this.storyHistory,
      sessionSummary: sessionSummary ?? this.sessionSummary,
      worldTheme: worldTheme ?? this.worldTheme,
      mood: mood ?? this.mood,
      pacingStage: pacingStage ?? this.pacingStage,
      inviteCode: inviteCode,
      eventCount: eventCount ?? this.eventCount,
      status: status ?? this.status,
      storySeed: storySeed ?? this.storySeed,
      storyBlueprint: storyBlueprint ?? this.storyBlueprint,
      storyStartedAt: storyStartedAt ?? this.storyStartedAt,
      minEpisodes: minEpisodes ?? this.minEpisodes,
      minDurationDays: minDurationDays ?? this.minDurationDays,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
