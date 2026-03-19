import 'package:flutter/material.dart';
import 'package:dreamloop/config/theme.dart';

/// Displays a story event with mood-based styling.
class StoryEventCard extends StatelessWidget {
  final String eventText;
  final String mood;

  const StoryEventCard({
    super.key,
    required this.eventText,
    required this.mood,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: DreamColors.backgroundCard.withValues(alpha: 0.85),
        border: Border.all(
          color: _getMoodColor().withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _getMoodColor().withValues(alpha: 0.1),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          // Mood icon
          Icon(
            _getMoodIcon(),
            size: 32,
            color: _getMoodColor().withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),

          // Event text
          Text(
            eventText,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.8,
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                ),
          ),
        ],
      ),
    );
  }

  Color _getMoodColor() {
    switch (mood) {
      case 'mystery':
      case 'mysterious':
        return DreamColors.mystery;
      case 'horror':
      case 'spooky':
        return DreamColors.horror;
      case 'bonding':
      case 'magical':
        return DreamColors.bonding;
      case 'adventure':
      case 'adventurous':
        return DreamColors.adventure;
      default:
        return DreamColors.cute;
    }
  }

  IconData _getMoodIcon() {
    switch (mood) {
      case 'mystery':
      case 'mysterious':
        return Icons.visibility;
      case 'horror':
      case 'spooky':
        return Icons.nights_stay;
      case 'bonding':
      case 'magical':
        return Icons.favorite;
      case 'adventure':
      case 'adventurous':
        return Icons.explore;
      default:
        return Icons.auto_awesome;
    }
  }
}
