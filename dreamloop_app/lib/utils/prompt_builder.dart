import 'package:dreamloop/models/session_model.dart';

/// Builds context-aware prompts for the AI Story Engine.
/// Includes story memory, pacing stage, tone rules, and past choices.

class PromptBuilder {
  /// Build the system prompt that defines AI behavior
  static String buildSystemPrompt() {
    return '''You are the DreamLoop Story Engine — an AI narrator for a shared adventure between two players.

RULES:
1. Generate ONE story event at a time. Never write a full story or predetermined ending.
2. Keep a SINGLE continuous canon storyline. Do not branch into alternate timelines or restart arcs unless explicitly asked.
3. Each event must include 3-5 slides. Each slide is 1-2 vivid sentences.
4. Slides in the same event are part of the same episode beat.
5. Always return EXACTLY 3 choices that represent meaningfully different strategies.
6. Choices must be hard and emotionally meaningful. No obvious "correct" option.
7. Reference past events, selected options, and story blueprint to preserve continuity.
8. Include emotional bonding moments naturally.
9. Occasionally include surprise twists while remaining coherent with prior events.
10. Story may continue indefinitely OR reach a natural ending depending on cumulative choices.
11. Do NOT end the story unless ending is explicitly allowed by context.

TONE DISTRIBUTION:
- Cute/cozy: 35%
- Adventure: 35%
- Emotional bonding: 15%
- Mystery: 10%
- Horror (rare): 5%

RESPONSE FORMAT (strict JSON):
{
  "title": "Short event title",
  "event": "single-paragraph summary of this event",
  "slides": ["Slide 1", "Slide 2", "Slide 3"],
  "options": ["Choice 1", "Choice 2", "Choice 3"],
  "tone": "cute|adventure|bonding|mystery|horror",
  "mood": "cozy|mysterious|adventurous|spooky|magical",
  "story_state": "ongoing|ending|ended"
}

Only respond with valid JSON. No markdown, no explanations.''';
  }

  /// Build the user prompt with session context and memory
  static String buildEventPrompt(SessionModel session) {
    final buffer = StringBuffer();
    final episode = session.currentEpisodeNumber;
    final beatInEpisode = ((session.eventCount % session.beatsPerEpisode) + 1);
    final daysElapsed = DateTime.now()
        .difference(session.storyStartedAt)
        .inDays;
    final nextEventCount = session.eventCount + 1;
    final nextEpisodeNumber = session.episodeNumberForEventCount(
      nextEventCount,
    );
    final endingAllowed =
        nextEpisodeNumber >= session.minEpisodes &&
        daysElapsed >= session.minDurationDays;

    // Pacing stage
    buffer.writeln('CURRENT PACING STAGE: ${session.computedPacingStage}');
    buffer.writeln('CURRENT EPISODE: $episode');
    buffer.writeln(
      'CURRENT BEAT IN EPISODE: $beatInEpisode/${session.beatsPerEpisode}',
    );
    buffer.writeln('NEXT EPISODE IF PROGRESSED: $nextEpisodeNumber');
    buffer.writeln('MIN EPISODES REQUIRED: ${session.minEpisodes}');
    buffer.writeln('MIN DAYS REQUIRED: ${session.minDurationDays}');
    buffer.writeln('DAYS ELAPSED: $daysElapsed');
    buffer.writeln('ENDING_ALLOWED: $endingAllowed');
    buffer.writeln('');

    // Pacing instructions
    switch (session.computedPacingStage) {
      case 'early':
        buffer.writeln(
          'PACING GUIDANCE: Focus on exploration, discovery, and curiosity. Introduce the world gently.',
        );
        break;
      case 'middle':
        buffer.writeln(
          'PACING GUIDANCE: Deepen mysteries, build relationships between characters, introduce challenges and moral dilemmas.',
        );
        break;
      case 'later':
        buffer.writeln(
          'PACING GUIDANCE: Escalate to major conflicts, emotional decisions, and meaningful outcomes. Stakes should be high.',
        );
        break;
    }
    buffer.writeln('');

    // World context
    buffer.writeln('WORLD THEME: ${session.worldTheme}');
    buffer.writeln('CURRENT MOOD: ${session.mood}');
    buffer.writeln('STORY SEED: ${session.storySeed}');
    buffer.writeln('');

    if (session.storyBlueprint.isNotEmpty) {
      buffer.writeln('=== STORY BLUEPRINT ===');
      buffer.writeln(session.storyBlueprint);
      buffer.writeln('=== END BLUEPRINT ===');
      buffer.writeln('');
    }

    if (session.sessionSummary.isNotEmpty) {
      buffer.writeln('SESSION SUMMARY: ${session.sessionSummary}');
      buffer.writeln('');
    }

    // Memory context — past events and choices
    if (session.storyHistory.isNotEmpty) {
      buffer.writeln('=== STORY MEMORY (past events and player choices) ===');
      for (final entry in session.storyHistory) {
        buffer.writeln('Event: ${entry['event'] ?? 'unknown'}');
        if (entry['choices'] != null) {
          final choices = entry['choices'] as Map<String, dynamic>;
          choices.forEach((userId, choice) {
            buffer.writeln('  Player chose: $choice');
          });
        }
        buffer.writeln('');
      }
      buffer.writeln('=== END MEMORY ===');
      buffer.writeln('');
    }

    buffer.writeln(
      'Generate the next story event as a continuation of the same storyline. Return 3-5 slides and 3 choices. Use story_state=ongoing unless ENDING_ALLOWED=true and the choices logically conclude the arc.',
    );

    return buffer.toString();
  }

  static String buildBlueprintSystemPrompt() {
    return '''You are a narrative architect for a two-player interactive story game.

Create a reusable story blueprint that guides many future events.
The blueprint must support both:
- potentially infinite continuation
- possible natural endings depending on player choices

Return strict JSON only.''';
  }

  static String buildBlueprintPrompt(SessionModel session) {
    final buffer = StringBuffer();
    buffer.writeln('Create a fresh story blueprint for this new run.');
    buffer.writeln('Story seed: ${session.storySeed}');
    buffer.writeln('Mood baseline: ${session.mood}');
    buffer.writeln('World hint: ${session.worldTheme}');
    buffer.writeln('');
    buffer.writeln('Return JSON in this exact shape:');
    buffer.writeln('''{
  "story_title": "string",
  "world_theme": "string",
  "opening_mood": "cozy|mysterious|adventurous|spooky|magical",
  "core_conflict": "string",
  "emotional_arc": ["string", "string", "string", "string"],
  "beats_per_episode": 3,
  "minimum_episodes": 20,
  "minimum_duration_days": 4,
  "episode_outline": [
    {"episode": 1, "focus": "string", "stakes": "string"},
    {"episode": 2, "focus": "string", "stakes": "string"},
    {"episode": 3, "focus": "string", "stakes": "string"},
    {"episode": 4, "focus": "string", "stakes": "string"}
  ],
  "continuation_rules": [
    "If players choose X, steer toward Y",
    "If trust grows, unlock intimate/cozy moments",
    "Allow ending branches when stakes resolve"
  ]
}''');
    return buffer.toString();
  }

  /// Generate a session summary for long-running sessions
  static String buildSummaryPrompt(SessionModel session) {
    final buffer = StringBuffer();
    buffer.writeln(
      'Summarize the following story events into 2-3 sentences for context preservation:',
    );
    buffer.writeln('');

    for (final entry in session.storyHistory) {
      buffer.writeln('Event: ${entry['event']}');
      if (entry['choices'] != null) {
        buffer.writeln('Choices made: ${entry['choices']}');
      }
    }

    buffer.writeln('');
    buffer.writeln(
      'Return only a plain text summary, no JSON. Keep it concise but include key decisions and outcomes.',
    );

    return buffer.toString();
  }
}
