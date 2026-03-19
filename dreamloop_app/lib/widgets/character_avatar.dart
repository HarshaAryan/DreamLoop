import 'package:flutter/material.dart';
import 'package:dreamloop/config/theme.dart';

/// Renders a pixel-style character avatar based on customization.
class CharacterAvatar extends StatelessWidget {
  final Map<String, dynamic> customization;
  final double size;

  const CharacterAvatar({
    super.key,
    this.customization = const {},
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    final colorIndex = customization['color'] as int? ?? 0;
    final colors = [
      DreamColors.primary,
      DreamColors.accent,
      DreamColors.cute,
      DreamColors.warning,
      DreamColors.mystery,
      const Color(0xFF00B894),
    ];
    final color = colors[colorIndex % colors.length];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.6)],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(
        Icons.face,
        size: size * 0.55,
        color: Colors.white,
      ),
    );
  }
}
