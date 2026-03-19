import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:dreamloop/models/choice_model.dart';
import 'package:dreamloop/models/session_model.dart';
import 'package:dreamloop/models/story_event_model.dart';
import 'package:dreamloop/models/user_model.dart';

/// FirestoreService — manages all database operations.
/// Uses Cloud Firestore for real-time multiplayer sync.
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final _uuid = const Uuid();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Random _random = Random.secure();

  // ─── Users ───

  Future<void> createUser(UserModel user) async {
    await _db.collection('users').doc(user.userId).set(user.toMap());
  }

  Future<UserModel?> getUser(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  Future<void> updateUser(UserModel user) async {
    await _db.collection('users').doc(user.userId).set(user.toMap());
  }

  // ─── Sessions ───

  Future<SessionModel> createSession(String userId) async {
    final sessionId = _uuid.v4();
    final inviteCode = await _generateUniqueInviteCode();

    final session = SessionModel(
      sessionId: sessionId,
      userIds: [userId],
      inviteCode: inviteCode,
      status: 'active',
      storySeed: _uuid.v4(),
    );

    await _db.collection('sessions').doc(sessionId).set(session.toMap());
    return session;
  }

  Future<SessionModel?> getSession(String sessionId) async {
    final doc = await _db.collection('sessions').doc(sessionId).get();
    if (doc.exists && doc.data() != null) {
      return SessionModel.fromMap(doc.data()!);
    }
    return null;
  }

  Future<SessionModel?> joinSessionByCode(
    String inviteCode,
    String userId,
  ) async {
    final query = await _db
        .collection('sessions')
        .where('invite_code', isEqualTo: inviteCode)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final docRef = query.docs.first.reference;
    return _db.runTransaction((tx) async {
      final snapshot = await tx.get(docRef);
      if (!snapshot.exists || snapshot.data() == null) return null;

      final session = SessionModel.fromMap(snapshot.data()!);
      if (session.status == 'ended') return null;
      if (session.userIds.contains(userId)) return session;
      if (session.userIds.length >= 2) return null;

      final updatedUserIds = [...session.userIds, userId];
      final updatedAt = DateTime.now();

      tx.update(snapshot.reference, {
        'user_ids': updatedUserIds,
        'updated_at': Timestamp.fromDate(updatedAt),
      });

      return session.copyWith(userIds: updatedUserIds, updatedAt: updatedAt);
    });
  }

  Future<SessionModel?> getActiveSessionForUser(String userId) async {
    try {
      final query = await _db
          .collection('sessions')
          .where('user_ids', arrayContains: userId)
          .get();

      if (query.docs.isEmpty) return null;

      final sessions = query.docs
          .map((doc) => SessionModel.fromMap(doc.data()))
          .where((session) => session.status != 'ended')
          .toList();
      if (sessions.isEmpty) return null;

      sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return sessions.first;
    } catch (_) {
      return null;
    }
  }

  Future<void> updateSession(SessionModel session) async {
    final updated = session.copyWith(updatedAt: DateTime.now());
    await _db
        .collection('sessions')
        .doc(session.sessionId)
        .update(updated.toMap());
  }

  Future<bool> submitChoiceForCurrentEvent({
    required String sessionId,
    required String userId,
    required String choice,
  }) async {
    return _db.runTransaction((tx) async {
      final sessionRef = _db.collection('sessions').doc(sessionId);
      final snapshot = await tx.get(sessionRef);
      if (!snapshot.exists || snapshot.data() == null) return false;

      final session = SessionModel.fromMap(snapshot.data()!);
      if (session.currentEventId.isEmpty || session.status == 'ended') {
        return false;
      }
      if (session.hasUserChosen(userId)) return true;

      final updatedChoices = Map<String, String>.from(session.userChoices);
      updatedChoices[userId] = choice;

      tx.update(sessionRef, {
        'user_choices': updatedChoices,
        'updated_at': Timestamp.fromDate(DateTime.now()),
      });

      final choiceDocId =
          '${session.sessionId}_${session.currentEventId}_$userId';
      tx.set(
        _db.collection('choices').doc(choiceDocId),
        ChoiceModel(
          choiceId: choiceDocId,
          eventId: session.currentEventId,
          userId: userId,
          selectedOption: choice,
        ).toMap(),
      );

      return true;
    });
  }

  Future<SessionModel?> applyNextEvent({
    required String sessionId,
    required StoryEventModel nextEvent,
  }) async {
    return _db.runTransaction((tx) async {
      final sessionRef = _db.collection('sessions').doc(sessionId);
      final snapshot = await tx.get(sessionRef);
      if (!snapshot.exists || snapshot.data() == null) return null;

      final session = SessionModel.fromMap(snapshot.data()!);
      if (session.status == 'ended') return null;

      final history = List<Map<String, dynamic>>.from(session.storyHistory);

      if (session.currentEvent.isNotEmpty && session.userChoices.isNotEmpty) {
        final eventTextForHistory = session.eventSlides.isNotEmpty
            ? session.eventSlides.join(' ')
            : session.currentEvent;
        history.add({
          'event': eventTextForHistory,
          'choices': Map<String, String>.from(session.userChoices),
          'timestamp': DateTime.now().toIso8601String(),
        });
      }

      final nextCount = session.eventCount + 1;
      final nextEpisodeNumber = session.episodeNumberForEventCount(nextCount);
      final nextPacingStage = nextCount < 5
          ? 'early'
          : (nextCount < 12 ? 'middle' : 'later');
      final updatedAt = DateTime.now();
      final elapsedDays = updatedAt.difference(session.storyStartedAt).inDays;
      final endingAllowed =
          nextEpisodeNumber >= session.minEpisodes &&
          elapsedDays >= session.minDurationDays;
      final nextStatus = endingAllowed && nextEvent.storyState == 'ended'
          ? 'ended'
          : 'active';

      final updatedSession = session.copyWith(
        currentEventId: nextEvent.eventId,
        currentEvent: nextEvent.slides.isNotEmpty
            ? nextEvent.slides.first
            : nextEvent.description,
        eventSlides: nextEvent.slides,
        eventOptions: nextEvent.options,
        userChoices: {},
        storyHistory: history,
        eventCount: nextCount,
        mood: nextEvent.mood,
        pacingStage: nextPacingStage,
        status: nextStatus,
        updatedAt: updatedAt,
      );

      tx.update(sessionRef, updatedSession.toMap());
      tx.set(
        _db.collection('events').doc(nextEvent.eventId),
        nextEvent.toMap(),
      );

      return updatedSession;
    });
  }

  Future<void> restartStory(String sessionId) async {
    final freshSeed = _uuid.v4();
    await _db.collection('sessions').doc(sessionId).update({
      'current_event_id': '',
      'current_event': '',
      'event_slides': <String>[],
      'event_options': <String>[],
      'user_choices': <String, String>{},
      'story_history': <Map<String, dynamic>>[],
      'session_summary': '',
      'event_count': 0,
      'mood': 'cozy',
      'pacing_stage': 'early',
      'status': 'active',
      'story_seed': freshSeed,
      'story_blueprint': <String, dynamic>{},
      'story_started_at': Timestamp.fromDate(DateTime.now()),
      'min_episodes': 20,
      'min_duration_days': 4,
      'updated_at': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> updateSessionSummary({
    required String sessionId,
    required String summary,
  }) async {
    await _db.collection('sessions').doc(sessionId).update({
      'session_summary': summary,
      'updated_at': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Stream session updates (for real-time sync)
  Stream<SessionModel?> streamSession(String sessionId) {
    return _db.collection('sessions').doc(sessionId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return SessionModel.fromMap(doc.data()!);
      }
      return null;
    });
  }

  // ─── Story Events ───

  Future<void> addStoryEvent(StoryEventModel event) async {
    await _db.collection('events').doc(event.eventId).set(event.toMap());
  }

  Future<List<StoryEventModel>> getStoryEvents(String sessionId) async {
    final query = await _db
        .collection('events')
        .where('session_id', isEqualTo: sessionId)
        .orderBy('created_at', descending: true)
        .get();

    return query.docs
        .map((doc) => StoryEventModel.fromMap(doc.data()))
        .toList();
  }

  // ─── Choices ───

  Future<void> submitChoice(ChoiceModel choice) async {
    await _db.collection('choices').doc(choice.choiceId).set(choice.toMap());
  }

  Future<List<ChoiceModel>> getChoicesForEvent(String eventId) async {
    final query = await _db
        .collection('choices')
        .where('event_id', isEqualTo: eventId)
        .get();

    return query.docs.map((doc) => ChoiceModel.fromMap(doc.data())).toList();
  }

  // ─── Helpers ───

  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(6, (_) => chars[_random.nextInt(chars.length)]).join();
  }

  Future<String> _generateUniqueInviteCode() async {
    for (var i = 0; i < 8; i++) {
      final code = _generateInviteCode();
      final query = await _db
          .collection('sessions')
          .where('invite_code', isEqualTo: code)
          .limit(1)
          .get();
      if (query.docs.isEmpty) return code;
    }

    return '${_generateInviteCode().substring(0, 5)}${_random.nextInt(10)}';
  }
}
