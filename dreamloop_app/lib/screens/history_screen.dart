import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dreamloop/config/theme.dart';
import 'package:dreamloop/services/auth_service.dart';
import 'package:dreamloop/services/firestore_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final session =
        await _firestoreService.getActiveSessionForUser(authService.userId!);

    if (session != null) {
      setState(() {
        _history = List<Map<String, dynamic>>.from(session.storyHistory);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Story History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: DreamColors.primary))
          : _history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.auto_stories,
                        size: 64,
                        color: DreamColors.textMuted.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No story yet',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: DreamColors.textMuted,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your adventure memories will appear here.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final entry = _history[index];
                    final reversedIndex = _history.length - index;
                    return _buildHistoryEntry(entry, reversedIndex);
                  },
                ),
    );
  }

  Widget _buildHistoryEntry(Map<String, dynamic> entry, int number) {
    final choices = entry['choices'] as Map<String, dynamic>? ?? {};

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot + line
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DreamColors.primary.withValues(alpha: 0.2),
                  border:
                      Border.all(color: DreamColors.primary, width: 2),
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      color: DreamColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (number > 1)
                Container(
                  width: 2,
                  height: 60,
                  color: DreamColors.divider,
                ),
            ],
          ),
          const SizedBox(width: 16),

          // Event content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: DreamColors.backgroundCard,
                border: Border.all(color: DreamColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry['event']?.toString() ?? 'Unknown event',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (choices.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(color: DreamColors.divider),
                    const SizedBox(height: 8),
                    ...choices.entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 12,
                                color: DreamColors.accent,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  e.value.toString(),
                                  style: TextStyle(
                                    color: DreamColors.accent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
