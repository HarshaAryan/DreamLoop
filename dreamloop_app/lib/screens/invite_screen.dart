import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:dreamloop/config/theme.dart';
import 'package:dreamloop/services/auth_service.dart';
import 'package:dreamloop/services/firestore_service.dart';
import 'package:dreamloop/models/session_model.dart';

class InviteScreen extends StatefulWidget {
  const InviteScreen({super.key});

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  final _codeController = TextEditingController();
  final _firestoreService = FirestoreService();
  SessionModel? _createdSession;
  StreamSubscription<SessionModel?>? _sessionSubscription;
  bool _isLoading = false;
  String? _errorMessage;
  bool _showJoinField = false;

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _createSession() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.userId;
    if (userId == null) {
      setState(() => _errorMessage = 'Please sign in again.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final session = await _firestoreService.createSession(userId);
      setState(() {
        _createdSession = session;
        _isLoading = false;
      });
      _listenForPartnerJoin(session.sessionId);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create session';
        _isLoading = false;
      });
    }
  }

  void _listenForPartnerJoin(String sessionId) {
    _sessionSubscription?.cancel();
    _sessionSubscription = _firestoreService.streamSession(sessionId).listen((
      session,
    ) {
      if (!mounted || session == null) return;
      setState(() => _createdSession = session);
      if (session.userIds.length == 2) {
        Navigator.pushReplacementNamed(context, '/story');
      }
    });
  }

  Future<void> _joinSession() async {
    if (_codeController.text.trim().length != 6) {
      setState(() => _errorMessage = 'Enter a 6-character invite code');
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.userId;
    if (userId == null) {
      setState(() => _errorMessage = 'Please sign in again.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final session = await _firestoreService.joinSessionByCode(
        _codeController.text.trim().toUpperCase(),
        userId,
      );

      if (session != null && mounted) {
        Navigator.pushReplacementNamed(context, '/story');
      } else {
        setState(() {
          _errorMessage = 'Invalid code or session is full';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to join session';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invite Partner')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DreamColors.accent.withValues(alpha: 0.15),
                ),
                child: const Icon(
                  Icons.link_rounded,
                  size: 40,
                  color: DreamColors.accent,
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Connect with\nyour partner',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Create an invite code to share, or enter one you received.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 40),

              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: DreamColors.error.withValues(alpha: 0.15),
                  ),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: DreamColors.error),
                  ),
                ),

              // Created session — show invite code
              if (_createdSession != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: DreamColors.backgroundCard,
                    border: Border.all(color: DreamColors.divider),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Your invite code',
                        style: TextStyle(color: DreamColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _createdSession!.inviteCode,
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(
                              letterSpacing: 8,
                              color: DreamColors.accent,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(
                                  text: _createdSession!.inviteCode,
                                ),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Code copied!')),
                              );
                            },
                            icon: const Icon(Icons.copy, size: 18),
                            label: const Text('Copy'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              final code = _createdSession!.inviteCode;
                              Share.share(
                                'Join my DreamLoop adventure.\nInvite code: $code\nOpen DreamLoop and enter this code.',
                                subject: 'DreamLoop Invite',
                              );
                            },
                            icon: const Icon(Icons.share, size: 18),
                            label: const Text('Share'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Waiting for your partner to join...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DreamColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: DreamColors.primary,
                  ),
                ),
                const SizedBox(height: 32),

                // Dev/Solo mode override
                TextButton.icon(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/story'),
                  icon: const Icon(Icons.rocket_launch, size: 16),
                  label: const Text('Start Solo Adventure (Dev Mode)'),
                  style: TextButton.styleFrom(
                    foregroundColor: DreamColors.textSecondary,
                  ),
                ),
              ] else ...[
                // Create or Join buttons
                if (_isLoading)
                  const CircularProgressIndicator(color: DreamColors.primary)
                else ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _createSession,
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Create Invite Code'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: DreamColors.divider)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or',
                          style: TextStyle(color: DreamColors.textMuted),
                        ),
                      ),
                      Expanded(child: Divider(color: DreamColors.divider)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_showJoinField) ...[
                    TextField(
                      controller: _codeController,
                      textAlign: TextAlign.center,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 6,
                      style: const TextStyle(
                        fontSize: 24,
                        letterSpacing: 6,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'INVITE CODE',
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _joinSession,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DreamColors.accent,
                        ),
                        child: const Text('Join Adventure'),
                      ),
                    ),
                  ] else
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => _showJoinField = true),
                        icon: const Icon(Icons.input_rounded),
                        label: const Text('I have an invite code'),
                      ),
                    ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
