import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dreamloop/config/theme.dart';
import 'package:dreamloop/models/session_model.dart';
import 'package:dreamloop/services/ai_service.dart';
import 'package:dreamloop/services/auth_service.dart';
import 'package:dreamloop/services/firestore_service.dart';
import 'package:dreamloop/services/notification_service.dart';
import 'package:dreamloop/services/widget_sync_service.dart';
import 'package:dreamloop/widgets/choice_card.dart';
import 'package:dreamloop/widgets/pixel_world_widget_preview.dart';
import 'package:dreamloop/widgets/story_event_card.dart';

class StoryScreen extends StatefulWidget {
  const StoryScreen({super.key});

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen>
    with TickerProviderStateMixin {
  final _firestoreService = FirestoreService();
  final _aiService = AIService();
  final _widgetSyncService = WidgetSyncService();

  SessionModel? _session;
  bool _isLoading = true;
  bool _isGenerating = false;
  String? _selectedChoice;
  int _activeSlideIndex = 0;
  String _lastRenderedEventId = '';
  StreamSubscription<SessionModel?>? _sessionSubscription;
  bool _progressInFlight = false;
  String? _lastFailedProgressToken;
  DateTime? _retryNotBefore;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _loadSession();
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadSession() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.userId;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final session = await _firestoreService.getActiveSessionForUser(userId);

    if (session != null) {
      _listenToSession(session.sessionId);
      if (!mounted) return;
      await _widgetSyncService.updateWidget(
        eventText: session.currentEvent,
        mood: session.mood,
        characterCustomization: authService.characterCustomization,
      );
      setState(() {
        _session = session;
        _selectedChoice = session.userChoices[userId];
        _activeSlideIndex = 0;
        _lastRenderedEventId = session.currentEventId;
        _isLoading = false;
      });

      // If no current event, generate the first one.
      if (session.currentEvent.isEmpty) {
        final isSolo = session.userIds.length <= 1;
        final isHost =
            session.userIds.isNotEmpty && session.userIds.first == userId;
        if (isSolo || isHost) {
          await _generateAndApplyNextEvent();
        }
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _listenToSession(String sessionId) {
    _sessionSubscription?.cancel();
    _sessionSubscription = _firestoreService.streamSession(sessionId).listen((
      session,
    ) {
      if (!mounted || session == null) return;
      if (session.status == 'ended') {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        return;
      }
      final authService = Provider.of<AuthService>(context, listen: false);
      final hasNewEvent = _lastRenderedEventId != session.currentEventId;
      setState(() {
        _session = session;
        _selectedChoice = session.userChoices[authService.userId];
        if (hasNewEvent) {
          _activeSlideIndex = 0;
          _lastRenderedEventId = session.currentEventId;
        }
      });
      _progressStoryIfReady();
    });
  }

  Future<bool> _generateAndApplyNextEvent() async {
    final currentSession = _session;
    if (currentSession == null) return false;

    final authService = Provider.of<AuthService>(context, listen: false);
    final characterCustomization = authService.characterCustomization;

    setState(() => _isGenerating = true);

    try {
      SessionModel freshSession =
          await _firestoreService.getSession(currentSession.sessionId) ??
          currentSession;
      if (freshSession.storyBlueprint.isEmpty) {
        final blueprint = await _aiService.generateStoryBlueprint(freshSession);
        final openingMood = blueprint['opening_mood']?.toString();
        final worldTheme = blueprint['world_theme']?.toString();
        final beatsPerEpisode =
            int.tryParse('${blueprint['beats_per_episode'] ?? ''}') ?? 3;
        final minEpisodes =
            int.tryParse('${blueprint['minimum_episodes'] ?? ''}') ?? 20;
        final minDurationDays =
            int.tryParse('${blueprint['minimum_duration_days'] ?? ''}') ?? 4;

        final normalizedBlueprint = Map<String, dynamic>.from(blueprint)
          ..['beats_per_episode'] = beatsPerEpisode
          ..['minimum_episodes'] = minEpisodes < 20 ? 20 : minEpisodes
          ..['minimum_duration_days'] = minDurationDays < 4
              ? 4
              : minDurationDays;

        final updatedWithBlueprint = freshSession.copyWith(
          storyBlueprint: normalizedBlueprint,
          mood: (openingMood != null && openingMood.isNotEmpty)
              ? openingMood
              : freshSession.mood,
          worldTheme: (worldTheme != null && worldTheme.isNotEmpty)
              ? worldTheme
              : freshSession.worldTheme,
          minEpisodes: minEpisodes < 20 ? 20 : minEpisodes,
          minDurationDays: minDurationDays < 4 ? 4 : minDurationDays,
        );
        await _firestoreService.updateSession(updatedWithBlueprint);
        freshSession = updatedWithBlueprint;
      }
      final event = await _aiService.generateStoryEvent(freshSession);
      final updatedSession = await _firestoreService.applyNextEvent(
        sessionId: freshSession.sessionId,
        nextEvent: event,
      );

      if (updatedSession == null) {
        throw Exception('Unable to apply next event to session');
      }

      await _widgetSyncService.updateWidget(
        eventText: updatedSession.currentEvent,
        mood: updatedSession.mood,
        characterCustomization: characterCustomization,
      );
      NotificationService().showLocalNotification(
        title: 'New Dream Event',
        body: event.title,
      );
      setState(() {
        _session = updatedSession;
        _selectedChoice = null;
        _activeSlideIndex = 0;
        _lastRenderedEventId = updatedSession.currentEventId;
        _isGenerating = false;
      });
      _lastFailedProgressToken = null;
      _retryNotBefore = null;
      return true;
    } catch (e) {
      setState(() => _isGenerating = false);
      final retryAfter = e is AIQuotaException
          ? (e.retryAfter ?? const Duration(seconds: 60))
          : const Duration(seconds: 20);
      _lastFailedProgressToken = _buildProgressToken(currentSession);
      _retryNotBefore = DateTime.now().add(retryAfter);
      if (mounted) {
        final seconds = retryAfter.inSeconds;
        final message = e is AIQuotaException
            ? 'Gemini quota exceeded. Enable billing/increase quota, then retry.'
            : 'Story generation failed. Try again in ~$seconds s.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
      debugPrint('Error generating event: $e');
      return false;
    }
  }

  Future<void> _submitChoice(String choice) async {
    final session = _session;
    if (session == null) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.userId;
    if (userId == null || session.hasUserChosen(userId)) return;

    setState(() => _selectedChoice = choice);

    try {
      final accepted = await _firestoreService.submitChoiceForCurrentEvent(
        sessionId: session.sessionId,
        userId: userId,
        choice: choice,
      );

      if (!accepted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not submit choice. Please retry.'),
          ),
        );
        setState(() => _selectedChoice = null);
        return;
      }

      NotificationService().showLocalNotification(
        title: 'Choice Locked In',
        body: 'Waiting for your partner...',
      );
      await _progressStoryIfReady();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit choice.')),
        );
        setState(() => _selectedChoice = null);
      }
      debugPrint('Choice submission error: $e');
    }
  }

  Future<void> _progressStoryIfReady() async {
    if (_session == null || _isGenerating || _progressInFlight) return;
    if (_session!.status == 'ended') return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.userId;
    if (userId == null) return;

    final session = _session!;
    final isSoloMode = session.userIds.length <= 1;
    final isHost =
        session.userIds.isNotEmpty && session.userIds.first == userId;
    final soloReady = isSoloMode && session.userChoices.isNotEmpty;
    final canProgress = soloReady || (session.bothUsersChosen && isHost);
    if (!canProgress) return;
    final token = _buildProgressToken(session);
    if (_lastFailedProgressToken == token &&
        _retryNotBefore != null &&
        DateTime.now().isBefore(_retryNotBefore!)) {
      return;
    }

    _progressInFlight = true;
    try {
      if (session.eventCount > 0 && session.eventCount % 5 == 0) {
        final summary = await _aiService.generateSessionSummary(session);
        await _firestoreService.updateSessionSummary(
          sessionId: session.sessionId,
          summary: summary,
        );
      }

      await Future.delayed(const Duration(milliseconds: 900));
      await _generateAndApplyNextEvent();
    } finally {
      _progressInFlight = false;
    }
  }

  String _buildProgressToken(SessionModel session) {
    final sortedUserIds = [...session.userChoices.keys]..sort();
    final choiceDigest = sortedUserIds
        .map((id) => '$id:${session.userChoices[id] ?? ''}')
        .join('|');
    return '${session.sessionId}:${session.currentEventId}:${session.eventCount}:$choiceDigest';
  }

  Future<void> _handleTopMenuAction(String value) async {
    switch (value) {
      case 'home':
        if (mounted) Navigator.pushNamed(context, '/home');
        break;
      case 'history':
        if (mounted) Navigator.pushNamed(context, '/history');
        break;
      case 'signout':
        await Provider.of<AuthService>(context, listen: false).signOut();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        }
        break;
      default:
        break;
    }
  }

  List<String> _currentSlides() {
    final session = _session;
    if (session == null) return const [];
    if (session.eventSlides.isNotEmpty) return session.eventSlides;
    if (session.currentEvent.isNotEmpty) return [session.currentEvent];
    return const [];
  }

  bool get _isOnLastSlide {
    final slides = _currentSlides();
    if (slides.isEmpty) return true;
    return _activeSlideIndex >= slides.length - 1;
  }

  void _goToPrevSlide() {
    if (_activeSlideIndex <= 0) return;
    setState(() => _activeSlideIndex -= 1);
  }

  void _goToNextSlide() {
    final slides = _currentSlides();
    if (_activeSlideIndex >= slides.length - 1) return;
    setState(() => _activeSlideIndex += 1);
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: DreamColors.primary),
        ),
      );
    }

    if (_session == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: DreamColors.textMuted,
              ),
              const SizedBox(height: 16),
              const Text('No active session found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/invite'),
                child: const Text('Create Session'),
              ),
            ],
          ),
        ),
      );
    }

    final slides = _currentSlides();
    final safeSlideIndex = slides.isEmpty
        ? 0
        : _activeSlideIndex.clamp(0, slides.length - 1);
    final currentSlideText = slides.isEmpty
        ? _session!.currentEvent
        : slides[safeSlideIndex];

    return Scaffold(
      body: Stack(
        children: [
          // Mood-based background gradient
          _buildMoodBackground(),

          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      // Episode counter
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: DreamColors.backgroundCard.withValues(
                            alpha: 0.8,
                          ),
                        ),
                        child: Text(
                          'Episode ${_session!.currentEpisodeNumber}',
                          style: const TextStyle(
                            color: DreamColors.accent,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Mood indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: _getMoodColor().withValues(alpha: 0.2),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getMoodIcon(),
                              size: 14,
                              color: _getMoodColor(),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _session!.mood.toUpperCase(),
                              style: TextStyle(
                                color: _getMoodColor(),
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: _handleTopMenuAction,
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'home', child: Text('Home')),
                          PopupMenuItem(
                            value: 'history',
                            child: Text('History'),
                          ),
                          PopupMenuItem(
                            value: 'signout',
                            child: Text('Sign Out'),
                          ),
                        ],
                        icon: const Icon(Icons.more_vert_rounded),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        // Story event
                        if (_isGenerating) ...[
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Opacity(
                                opacity: 0.4 + (_pulseController.value * 0.6),
                                child: child,
                              );
                            },
                            child: Column(
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 48,
                                  color: DreamColors.primary.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'The story unfolds...',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        color: DreamColors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          // Event card
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                PixelWorldWidgetPreview(
                                  eventText: currentSlideText,
                                  mood: _session!.mood,
                                  characterCustomization:
                                      authService.characterCustomization,
                                ),
                                const SizedBox(height: 14),
                                StoryEventCard(
                                  eventText: currentSlideText,
                                  mood: _session!.mood,
                                ),
                                if (slides.length > 1) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: _activeSlideIndex > 0
                                            ? _goToPrevSlide
                                            : null,
                                        icon: const Icon(
                                          Icons.chevron_left_rounded,
                                        ),
                                        label: const Text('Back'),
                                      ),
                                      const Spacer(),
                                      Text(
                                        'Slide ${safeSlideIndex + 1}/${slides.length}',
                                        style: const TextStyle(
                                          color: DreamColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const Spacer(),
                                      OutlinedButton.icon(
                                        onPressed: _isOnLastSlide
                                            ? null
                                            : _goToNextSlide,
                                        icon: const Icon(
                                          Icons.chevron_right_rounded,
                                        ),
                                        label: const Text('Next'),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Choices
                          if (_isOnLastSlide)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Column(
                                children: _session!.eventOptions.map((option) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: ChoiceCard(
                                      text: option,
                                      isSelected: _selectedChoice == option,
                                      isDisabled: _selectedChoice != null,
                                      onTap: () => _submitChoice(option),
                                    ),
                                  );
                                }).toList(),
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: DreamColors.backgroundCard.withValues(
                                    alpha: 0.7,
                                  ),
                                  border: Border.all(
                                    color: DreamColors.divider,
                                  ),
                                ),
                                child: const Text(
                                  'Read the full scene and make your choice on the final slide.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: DreamColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),

                          // Waiting for partner indicator
                          if (_selectedChoice != null &&
                              !(_session!.bothUsersChosen)) ...[
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: DreamColors.textMuted.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Waiting for partner...',
                                  style: TextStyle(
                                    color: DreamColors.textMuted.withValues(
                                      alpha: 0.7,
                                    ),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodBackground() {
    final colors = _getMoodGradient();
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
    );
  }

  List<Color> _getMoodGradient() {
    switch (_session?.mood) {
      case 'mysterious':
        return [
          const Color(0xFF0D0D2B),
          const Color(0xFF1A1A3E),
          const Color(0xFF0D0D2B),
        ];
      case 'spooky':
        return [
          const Color(0xFF1A0A0A),
          const Color(0xFF2D1B1B),
          const Color(0xFF1A0A0A),
        ];
      case 'magical':
        return [
          const Color(0xFF0A1628),
          const Color(0xFF162040),
          const Color(0xFF0A1628),
        ];
      case 'adventurous':
        return [
          const Color(0xFF0A1A14),
          const Color(0xFF142D22),
          const Color(0xFF0A1A14),
        ];
      default: // cozy
        return [
          DreamColors.backgroundDark,
          DreamColors.backgroundSurface,
          DreamColors.backgroundDark,
        ];
    }
  }

  Color _getMoodColor() {
    switch (_session?.mood) {
      case 'mysterious':
        return DreamColors.mystery;
      case 'spooky':
        return DreamColors.horror;
      case 'magical':
        return DreamColors.accent;
      case 'adventurous':
        return DreamColors.adventure;
      default:
        return DreamColors.cute;
    }
  }

  IconData _getMoodIcon() {
    switch (_session?.mood) {
      case 'mysterious':
        return Icons.visibility;
      case 'spooky':
        return Icons.warning_amber;
      case 'magical':
        return Icons.auto_awesome;
      case 'adventurous':
        return Icons.explore;
      default:
        return Icons.favorite;
    }
  }
}
