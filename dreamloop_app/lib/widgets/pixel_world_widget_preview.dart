import 'dart:math';

import 'package:dreamloop/config/theme.dart';
import 'package:flutter/material.dart';

/// In-app preview for the home-screen widget.
/// Renders a retro pixel scene from event tags (procedural + sprite templates).
class PixelWorldWidgetPreview extends StatelessWidget {
  final String eventText;
  final String mood;
  final Map<String, dynamic> characterCustomization;

  const PixelWorldWidgetPreview({
    super.key,
    required this.eventText,
    required this.mood,
    required this.characterCustomization,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DreamColors.divider),
        color: DreamColors.backgroundCard.withValues(alpha: 0.9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Widget Preview',
            style: TextStyle(
              color: DreamColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          AspectRatio(
            aspectRatio: 2.1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomPaint(
                painter: _RetroWorldPainter(
                  seed: eventText,
                  mood: mood,
                  characterCustomization: characterCustomization,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            eventText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: DreamColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _RetroWorldPainter extends CustomPainter {
  final String seed;
  final String mood;
  final Map<String, dynamic> characterCustomization;

  _RetroWorldPainter({
    required this.seed,
    required this.mood,
    required this.characterCustomization,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final event = seed.toLowerCase();
    final random = Random(seed.hashCode);
    final scene = _sceneTag(event);
    final weather = _weatherTag(event);
    final time = _timeTag(event, mood);

    const p = 6.0;

    _drawSky(canvas, size, mood, time);
    _drawSunOrMoon(canvas, size, p, time);
    _drawClouds(canvas, size, p, random, time);
    _drawHills(canvas, size, p);
    _drawGroundTiles(canvas, size, p);
    _drawPlatforms(canvas, size, p, random);
    _drawSceneSprite(canvas, size, p, scene);
    _drawWeather(canvas, size, p, weather, random);
    _drawCharacter(canvas, size, p, characterCustomization, dx: 0);
    if (_hasPartner(event)) {
      _drawCharacter(canvas, size, p, characterCustomization, dx: 5 * p);
    }
  }

  void _drawSky(Canvas canvas, Size size, String m, String time) {
    final (top, bottom) = _skyColors(m, time);
    final rect = Rect.fromLTWH(0, 0, size.width, size.height * 0.7);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ).createShader(rect),
    );
  }

  (Color, Color) _skyColors(String m, String time) {
    if (time == 'night') {
      return (const Color(0xFF132040), const Color(0xFF2E3A63));
    }
    if (time == 'sunset') {
      return (const Color(0xFF5B2C6F), const Color(0xFFEB984E));
    }
    if (time == 'dawn') {
      return (const Color(0xFF4A69BD), const Color(0xFFF8C291));
    }
    switch (m) {
      case 'spooky':
        return (const Color(0xFF2A1E1A), const Color(0xFF5C4033));
      case 'mysterious':
        return (const Color(0xFF2C2C54), const Color(0xFF706FD3));
      case 'magical':
        return (const Color(0xFF1B3C73), const Color(0xFF4A69BD));
      default:
        return (const Color(0xFF3B6AB3), const Color(0xFF79A7E3));
    }
  }

  void _drawSunOrMoon(Canvas canvas, Size size, double p, String time) {
    final x = size.width * 0.12;
    final y = size.height * 0.12;
    final color = time == 'night'
        ? const Color(0xFFD6DDFF)
        : const Color(0xFFF7D04A);
    final paint = Paint()..color = color;
    for (int ix = 0; ix < 5; ix++) {
      for (int iy = 0; iy < 5; iy++) {
        if ((ix == 0 || ix == 4) && (iy == 0 || iy == 4)) continue;
        canvas.drawRect(Rect.fromLTWH(x + ix * p, y + iy * p, p, p), paint);
      }
    }
  }

  void _drawClouds(Canvas canvas, Size size, double p, Random r, String time) {
    final cloudPaint = Paint()
      ..color =
          (time == 'night' ? const Color(0xFFC8D6E5) : const Color(0xFFF5F6FA))
              .withValues(alpha: 0.7);
    for (int i = 0; i < 5; i++) {
      final x = r.nextDouble() * (size.width - 12 * p);
      final y = r.nextDouble() * (size.height * 0.25);
      for (int ix = 0; ix < 8; ix++) {
        for (int iy = 0; iy < 3; iy++) {
          if ((ix < 1 || ix > 6) && iy == 2) continue;
          canvas.drawRect(
            Rect.fromLTWH(x + ix * p, y + iy * p, p, p),
            cloudPaint,
          );
        }
      }
    }
  }

  void _drawHills(Canvas canvas, Size size, double p) {
    final hill = Paint()..color = const Color(0xFF72C86F);
    final hillDark = Paint()..color = const Color(0xFF4FAE55);
    for (double x = -10; x < size.width + 20; x += 30) {
      for (int ix = 0; ix < 6; ix++) {
        for (int iy = 0; iy < 4 - (ix ~/ 2); iy++) {
          canvas.drawRect(
            Rect.fromLTWH(x + ix * p, size.height * 0.61 - iy * p, p, p),
            hill,
          );
        }
      }
      canvas.drawRect(
        Rect.fromLTWH(x + 3 * p, size.height * 0.61, p, 2 * p),
        hillDark,
      );
    }
  }

  void _drawGroundTiles(Canvas canvas, Size size, double p) {
    final grass = Paint()..color = const Color(0xFF4CAF50);
    final dirt = Paint()..color = const Color(0xFF8D5A2B);
    final brick = Paint()..color = const Color(0xFFA36A3A);
    final yBase = size.height * 0.7;

    for (double x = 0; x < size.width; x += p) {
      canvas.drawRect(Rect.fromLTWH(x, yBase, p, p), grass);
    }
    for (double y = yBase + p; y < size.height; y += p) {
      for (double x = 0; x < size.width; x += p) {
        canvas.drawRect(Rect.fromLTWH(x, y, p, p), dirt);
      }
    }
    for (double y = yBase + p; y < size.height; y += 2 * p) {
      for (double x = 0; x < size.width; x += 2 * p) {
        canvas.drawRect(Rect.fromLTWH(x, y, p, p), brick);
      }
    }
  }

  void _drawPlatforms(Canvas canvas, Size size, double p, Random r) {
    final block = Paint()..color = const Color(0xFFE9D8A6);
    final shade = Paint()..color = const Color(0xFFC9B98A);
    for (int i = 0; i < 5; i++) {
      final x = size.width * 0.28 + r.nextDouble() * size.width * 0.55;
      final y = size.height * 0.32 + r.nextDouble() * size.height * 0.15;
      for (int ix = 0; ix < 4; ix++) {
        canvas.drawRect(Rect.fromLTWH(x + ix * p, y, p, p), block);
      }
      canvas.drawRect(Rect.fromLTWH(x + 3 * p, y, p, p), shade);
    }
    _drawQuestionBlock(canvas, size.width * 0.42, size.height * 0.42, p);
    _drawPipe(canvas, size.width * 0.78, size.height * 0.56, p);
  }

  void _drawQuestionBlock(Canvas canvas, double x, double y, double p) {
    final gold = Paint()..color = const Color(0xFFF1C40F);
    final dark = Paint()..color = const Color(0xFFD4AC0D);
    for (int ix = 0; ix < 3; ix++) {
      for (int iy = 0; iy < 3; iy++) {
        canvas.drawRect(Rect.fromLTWH(x + ix * p, y + iy * p, p, p), gold);
      }
    }
    canvas.drawRect(Rect.fromLTWH(x + p, y + p, p, p), dark);
  }

  void _drawPipe(Canvas canvas, double x, double y, double p) {
    final green = Paint()..color = const Color(0xFF2ECC71);
    final dark = Paint()..color = const Color(0xFF27AE60);
    canvas.drawRect(Rect.fromLTWH(x, y, 5 * p, p), green);
    canvas.drawRect(Rect.fromLTWH(x + p, y + p, 3 * p, 4 * p), green);
    canvas.drawRect(Rect.fromLTWH(x + 3 * p, y + p, p, 4 * p), dark);
  }

  void _drawSceneSprite(Canvas canvas, Size size, double p, String scene) {
    switch (scene) {
      case 'forest':
        _drawTree(canvas, size.width * 0.12, size.height * 0.52, p);
        _drawTree(canvas, size.width * 0.22, size.height * 0.54, p);
        break;
      case 'cave':
        final cave = Paint()..color = const Color(0xFF3B3B52);
        canvas.drawRect(
          Rect.fromLTWH(size.width * 0.66, size.height * 0.5, 10 * p, 6 * p),
          cave,
        );
        break;
      case 'village':
        _drawHouse(canvas, size.width * 0.64, size.height * 0.52, p);
        break;
      case 'camp':
        _drawTent(canvas, size.width * 0.66, size.height * 0.56, p);
        _drawFire(canvas, size.width * 0.78, size.height * 0.62, p);
        break;
      case 'bridge':
        final bridge = Paint()..color = const Color(0xFFA47551);
        canvas.drawRect(
          Rect.fromLTWH(size.width * 0.6, size.height * 0.62, 14 * p, p),
          bridge,
        );
        break;
      case 'ruins':
        _drawColumn(canvas, size.width * 0.68, size.height * 0.5, p);
        _drawColumn(canvas, size.width * 0.76, size.height * 0.52, p);
        break;
      default:
        break;
    }
  }

  void _drawTree(Canvas canvas, double x, double y, double p) {
    final trunk = Paint()..color = const Color(0xFF8D6E63);
    final leaves = Paint()..color = const Color(0xFF43A047);
    canvas.drawRect(Rect.fromLTWH(x + 2 * p, y + 2 * p, p, 4 * p), trunk);
    canvas.drawRect(Rect.fromLTWH(x, y, 5 * p, 3 * p), leaves);
  }

  void _drawHouse(Canvas canvas, double x, double y, double p) {
    final wall = Paint()..color = const Color(0xFFD7C8A3);
    final roof = Paint()..color = const Color(0xFF8D5A2B);
    canvas.drawRect(Rect.fromLTWH(x, y + p, 8 * p, 5 * p), wall);
    canvas.drawRect(Rect.fromLTWH(x - p, y, 10 * p, p), roof);
  }

  void _drawTent(Canvas canvas, double x, double y, double p) {
    final tent = Paint()..color = const Color(0xFF6C5CE7);
    canvas.drawRect(Rect.fromLTWH(x, y + p, 6 * p, 3 * p), tent);
    canvas.drawRect(Rect.fromLTWH(x + 2 * p, y, 2 * p, p), tent);
  }

  void _drawFire(Canvas canvas, double x, double y, double p) {
    final fire = Paint()..color = const Color(0xFFFFA000);
    final wood = Paint()..color = const Color(0xFF7B4F2A);
    canvas.drawRect(Rect.fromLTWH(x, y, 2 * p, 2 * p), fire);
    canvas.drawRect(Rect.fromLTWH(x - p, y + 2 * p, 4 * p, p), wood);
  }

  void _drawColumn(Canvas canvas, double x, double y, double p) {
    final stone = Paint()..color = const Color(0xFFB0BEC5);
    canvas.drawRect(Rect.fromLTWH(x, y, 2 * p, 6 * p), stone);
    canvas.drawRect(Rect.fromLTWH(x - p, y, 4 * p, p), stone);
  }

  void _drawWeather(
    Canvas canvas,
    Size size,
    double p,
    String weather,
    Random random,
  ) {
    switch (weather) {
      case 'rain':
        final rain = Paint()..color = const Color(0xFFB3E5FC);
        for (int i = 0; i < 20; i++) {
          final x = random.nextDouble() * size.width;
          final y = random.nextDouble() * (size.height * 0.65);
          canvas.drawRect(Rect.fromLTWH(x, y, p * 0.5, p * 1.8), rain);
        }
        break;
      case 'snow':
        final snow = Paint()..color = const Color(0xFFFFFFFF);
        for (int i = 0; i < 20; i++) {
          final x = random.nextDouble() * size.width;
          final y = random.nextDouble() * (size.height * 0.65);
          canvas.drawRect(Rect.fromLTWH(x, y, p * 0.8, p * 0.8), snow);
        }
        break;
      case 'mist':
        final mist = Paint()
          ..color = const Color(0xFFCFD8DC).withValues(alpha: 0.35);
        canvas.drawRect(
          Rect.fromLTWH(0, size.height * 0.54, size.width, size.height * 0.12),
          mist,
        );
        break;
      case 'storm':
        final bolt = Paint()..color = const Color(0xFFFFD54F);
        canvas.drawRect(
          Rect.fromLTWH(size.width * 0.18, size.height * 0.18, p, 5 * p),
          bolt,
        );
        canvas.drawRect(
          Rect.fromLTWH(size.width * 0.18 + p, size.height * 0.22, p, 4 * p),
          bolt,
        );
        break;
      default:
        break;
    }
  }

  void _drawCharacter(
    Canvas canvas,
    Size size,
    double p,
    Map<String, dynamic> customization, {
    required double dx,
  }) {
    final accentHex = customization['color_hex']?.toString();
    final clothColor = _parseHexColor(accentHex) ?? DreamColors.primary;

    final skin = Paint()..color = const Color(0xFFFAD7B5);
    final hair = Paint()..color = const Color(0xFF4E342E);
    final cloth = Paint()..color = clothColor;
    final eye = Paint()..color = Colors.black;
    final leg = Paint()..color = const Color(0xFF424242);

    final x = size.width * 0.5 + dx;
    final y = size.height * 0.66;

    canvas.drawRect(Rect.fromLTWH(x, y - 6 * p, 3 * p, p), hair);
    canvas.drawRect(Rect.fromLTWH(x, y - 5 * p, 3 * p, 2 * p), skin);
    canvas.drawRect(Rect.fromLTWH(x + p, y - 4 * p, p, p), eye);
    canvas.drawRect(Rect.fromLTWH(x, y - 3 * p, 3 * p, 3 * p), cloth);
    canvas.drawRect(Rect.fromLTWH(x, y, p, 2 * p), leg);
    canvas.drawRect(Rect.fromLTWH(x + 2 * p, y, p, 2 * p), leg);
  }

  bool _hasPartner(String event) {
    return event.contains('you and') ||
        event.contains('together') ||
        event.contains('companion') ||
        event.contains('both');
  }

  String _sceneTag(String event) {
    if (event.contains('forest') || event.contains('tree')) return 'forest';
    if (event.contains('cave')) return 'cave';
    if (event.contains('village') || event.contains('town')) return 'village';
    if (event.contains('camp') || event.contains('campfire')) return 'camp';
    if (event.contains('bridge')) return 'bridge';
    if (event.contains('temple') || event.contains('ruin')) return 'ruins';
    return 'fields';
  }

  String _weatherTag(String event) {
    if (event.contains('storm') || event.contains('thunder')) return 'storm';
    if (event.contains('rain') || event.contains('drizzle')) return 'rain';
    if (event.contains('snow') || event.contains('blizzard')) return 'snow';
    if (event.contains('mist') || event.contains('fog')) return 'mist';
    return 'clear';
  }

  String _timeTag(String event, String mood) {
    if (event.contains('night') ||
        event.contains('moon') ||
        event.contains('star') ||
        mood == 'spooky' ||
        mood == 'mysterious') {
      return 'night';
    }
    if (event.contains('sunset') || event.contains('dusk')) return 'sunset';
    if (event.contains('sunrise') || event.contains('dawn')) return 'dawn';
    return 'day';
  }

  Color? _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final normalized = hex.length == 8 ? hex : 'ff$hex';
    try {
      return Color(int.parse(normalized, radix: 16));
    } catch (_) {
      return null;
    }
  }

  @override
  bool shouldRepaint(covariant _RetroWorldPainter oldDelegate) {
    return oldDelegate.seed != seed ||
        oldDelegate.mood != mood ||
        oldDelegate.characterCustomization != characterCustomization;
  }
}
