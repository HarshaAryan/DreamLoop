import 'package:flutter/material.dart';
import 'package:dreamloop/config/theme.dart';
import 'package:provider/provider.dart';
import 'package:dreamloop/services/auth_service.dart';
import 'package:dreamloop/services/firestore_service.dart';
import 'package:dreamloop/models/user_model.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentPage = 0;
  String? _selectedRelationship;
  final _firestoreService = FirestoreService();
  bool _isSaving = false;
  String? _errorMessage;

  final List<Map<String, dynamic>> _pages = [
    {
      'icon': Icons.auto_awesome,
      'title': 'Welcome to DreamLoop',
      'subtitle': 'A shared dream adventure awaits you and someone special.',
      'color': DreamColors.primary,
    },
    {
      'icon': Icons.people_alt_rounded,
      'title': 'Two Hearts, One Story',
      'subtitle':
          'Make choices together. Your decisions shape an ever-evolving narrative.',
      'color': DreamColors.accent,
    },
    {
      'icon': Icons.nightlight_round,
      'title': 'No Two Dreams Alike',
      'subtitle':
          'Every adventure is unique. Hard choices reveal who you truly are.',
      'color': DreamColors.cute,
    },
  ];

  final List<Map<String, dynamic>> _relationships = [
    {
      'type': 'couple',
      'icon': Icons.favorite,
      'label': 'Couple',
      'color': DreamColors.cute,
    },
    {
      'type': 'bestfriend',
      'icon': Icons.group,
      'label': 'Best Friend',
      'color': DreamColors.accent,
    },
    {
      'type': 'family',
      'icon': Icons.home_filled,
      'label': 'Family',
      'color': DreamColors.warning,
    },
    {
      'type': 'adventure',
      'icon': Icons.explore,
      'label': 'Adventure Partner',
      'color': DreamColors.mystery,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // Progress dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length + 1,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _currentPage == index
                              ? DreamColors.primary
                              : DreamColors.divider,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Page content (scrollable to prevent overflow on small devices)
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 220,
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            child: isLastPage
                                ? _buildRelationshipPicker()
                                : _buildOnboardingPage(_pages[_currentPage]),
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: DreamColors.error),
                      ),
                    ),

                  // Navigation
                  Row(
                    children: [
                      if (_currentPage > 0)
                        TextButton(
                          onPressed: () => setState(() => _currentPage--),
                          child: const Text(
                            'Back',
                            style: TextStyle(color: DreamColors.textSecondary),
                          ),
                        ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: _isSaving
                            ? null
                            : isLastPage
                            ? (_selectedRelationship != null
                                  ? _continueToCharacter
                                  : null)
                            : () => setState(() => _currentPage++),
                        child: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(isLastPage ? 'Continue' : 'Next'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _continueToCharacter() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final relationship = _selectedRelationship;
    if (relationship == null || authService.userId == null) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    authService.setRelationshipType(relationship);
    final user = UserModel(
      userId: authService.userId!,
      displayName: authService.displayName ?? 'DreamLoop Explorer',
      authProvider: authService.authProvider ?? 'unknown',
      relationshipType: relationship,
      characterCustomization: authService.characterCustomization,
    );
    try {
      await _firestoreService.createUser(user);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/character');
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage = 'Could not save your profile. Try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildOnboardingPage(Map<String, dynamic> page) {
    return Column(
      key: ValueKey(page['title']),
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (page['color'] as Color).withValues(alpha: 0.15),
          ),
          child: Icon(
            page['icon'] as IconData,
            size: 56,
            color: page['color'] as Color,
          ),
        ),
        const SizedBox(height: 40),
        Text(
          page['title'] as String,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 16),
        Text(
          page['subtitle'] as String,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: DreamColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildRelationshipPicker() {
    return Column(
      key: const ValueKey('relationship'),
      children: [
        Text(
          'Who are you\nadventuring with?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 12),
        Text(
          'This shapes the tone of your shared story.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        ...List.generate(_relationships.length, (index) {
          final rel = _relationships[index];
          final isSelected = _selectedRelationship == rel['type'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () =>
                  setState(() => _selectedRelationship = rel['type'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isSelected
                      ? (rel['color'] as Color).withValues(alpha: 0.15)
                      : DreamColors.backgroundCard,
                  border: Border.all(
                    color: isSelected
                        ? rel['color'] as Color
                        : DreamColors.divider,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      rel['icon'] as IconData,
                      color: rel['color'] as Color,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      rel['label'] as String,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    if (isSelected)
                      Icon(Icons.check_circle, color: rel['color'] as Color),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
