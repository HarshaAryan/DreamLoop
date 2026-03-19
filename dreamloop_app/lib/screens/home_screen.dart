import 'package:dreamloop/config/theme.dart';
import 'package:dreamloop/models/session_model.dart';
import 'package:dreamloop/services/auth_service.dart';
import 'package:dreamloop/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isSigningOut = false;
  bool _isRestartingStory = false;

  Future<SessionModel?> _loadActiveSession(String userId) {
    return _firestoreService.getActiveSessionForUser(userId);
  }

  Future<void> _signOut() async {
    if (_isSigningOut) return;
    setState(() => _isSigningOut = true);
    try {
      await Provider.of<AuthService>(context, listen: false).signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } finally {
      if (mounted) {
        setState(() => _isSigningOut = false);
      }
    }
  }

  Future<void> _startNewStory(SessionModel session) async {
    if (_isRestartingStory) return;
    final shouldRestart = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Start a New Story?'),
          content: const Text(
            'This will reset the current storyline in this shared session for both players.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Start New Story'),
            ),
          ],
        );
      },
    );

    if (shouldRestart != true) return;

    setState(() => _isRestartingStory = true);
    try {
      await _firestoreService.restartStory(session.sessionId);
      if (mounted) {
        Navigator.pushNamed(context, '/story');
      }
    } finally {
      if (mounted) {
        setState(() => _isRestartingStory = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userId = authService.userId;
    final displayName = authService.displayName ?? 'DreamLoop Explorer';

    if (userId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('DreamLoop'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: _isSigningOut ? null : _signOut,
            icon: _isSigningOut
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: FutureBuilder<SessionModel?>(
        future: _loadActiveSession(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: DreamColors.primary),
            );
          }

          final session = snapshot.data;
          final hasActiveSession = session != null;

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Welcome back, $displayName',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  hasActiveSession
                      ? 'Your shared world is waiting.'
                      : 'Start a new adventure with your partner.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                _buildPrimaryCard(session),
                const SizedBox(height: 16),
                _buildSecondaryActions(hasActiveSession, session),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPrimaryCard(SessionModel? session) {
    final hasActiveSession = session != null;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: DreamColors.backgroundCard,
        border: Border.all(color: DreamColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasActiveSession ? 'Continue Story' : 'No Active Session',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            hasActiveSession
                ? (session.currentEvent.isNotEmpty
                      ? session.currentEvent
                      : 'Your next event is ready to begin.')
                : 'Create an invite code or join your partner to begin.',
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  hasActiveSession ? '/story' : '/invite',
                );
              },
              icon: Icon(
                hasActiveSession ? Icons.play_arrow_rounded : Icons.group_add,
              ),
              label: Text(
                hasActiveSession
                    ? 'Continue Adventure'
                    : 'Create / Join Session',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryActions(bool hasActiveSession, SessionModel? session) {
    return Column(
      children: [
        if (hasActiveSession && session != null) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isRestartingStory
                  ? null
                  : () => _startNewStory(session),
              icon: _isRestartingStory
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
              label: Text(
                _isRestartingStory ? 'Resetting Story...' : 'Start a New Story',
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/invite'),
            icon: Icon(hasActiveSession ? Icons.link : Icons.rocket_launch),
            label: Text(
              hasActiveSession ? 'Invite / Reconnect' : 'Invite Partner',
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/history'),
            icon: const Icon(Icons.history_rounded),
            label: const Text('Story History'),
          ),
        ),
      ],
    );
  }
}
