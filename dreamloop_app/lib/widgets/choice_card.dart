import 'package:flutter/material.dart';
import 'package:dreamloop/config/theme.dart';

/// Glassmorphism choice card with selection animation.
class ChoiceCard extends StatelessWidget {
  final String text;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const ChoiceCard({
    super.key,
    required this.text,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected
              ? DreamColors.primary.withValues(alpha: 0.2)
              : DreamColors.backgroundCard.withValues(alpha: 0.8),
          border: Border.all(
            color: isSelected
                ? DreamColors.primary
                : isDisabled
                    ? DreamColors.divider.withValues(alpha: 0.5)
                    : DreamColors.divider,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: DreamColors.primary.withValues(alpha: 0.2),
                    blurRadius: 16,
                    spreadRadius: 0,
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? DreamColors.textPrimary
                      : isDisabled
                          ? DreamColors.textMuted
                          : DreamColors.textSecondary,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: DreamColors.primary,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
