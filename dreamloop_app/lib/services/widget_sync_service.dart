import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:dreamloop/navigation/app_navigator.dart';

/// Syncs story state with the home-screen widget and handles widget taps.
class WidgetSyncService {
  static final WidgetSyncService _instance = WidgetSyncService._internal();
  factory WidgetSyncService() => _instance;
  WidgetSyncService._internal();

  static const String _appGroupId = 'group.com.dreamloop.shared';
  static const String _iOSWidgetName = 'DreamLoopWidget';
  static const String _androidWidgetProvider = 'DreamLoopWidgetProvider';

  StreamSubscription<Uri?>? _widgetClickSub;

  Future<void> initialize() async {
    try {
      await HomeWidget.setAppGroupId(_appGroupId);
      _widgetClickSub?.cancel();
      _widgetClickSub = HomeWidget.widgetClicked.listen(_handleWidgetUri);

      final launchUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      _handleWidgetUri(launchUri);
    } catch (e) {
      debugPrint('WidgetSyncService.initialize error: $e');
    }
  }

  Future<void> updateWidget({
    required String eventText,
    required String mood,
    required Map<String, dynamic> characterCustomization,
  }) async {
    try {
      final sceneTag = _deriveSceneTag(eventText);
      final weatherTag = _deriveWeatherTag(eventText);
      final timeTag = _deriveTimeTag(eventText, mood);

      await HomeWidget.saveWidgetData<String>('event_text', eventText);
      await HomeWidget.saveWidgetData<String>('mood', mood);
      await HomeWidget.saveWidgetData<String>('scene_tag', sceneTag);
      await HomeWidget.saveWidgetData<String>('weather_tag', weatherTag);
      await HomeWidget.saveWidgetData<String>('time_tag', timeTag);
      await HomeWidget.saveWidgetData<String>(
        'character_color_hex',
        characterCustomization['color_hex']?.toString() ?? 'ff6c5ce7',
      );

      await HomeWidget.saveWidgetData<String>(
        'widget_url',
        'dreamloop://story',
      );

      await HomeWidget.updateWidget(
        iOSName: _iOSWidgetName,
        androidName: _androidWidgetProvider,
      );
    } catch (e) {
      debugPrint('WidgetSyncService.updateWidget error: $e');
    }
  }

  String _deriveSceneTag(String eventText) {
    final text = eventText.toLowerCase();
    if (text.contains('cave')) return 'cave';
    if (text.contains('temple') || text.contains('ruin')) return 'ruins';
    if (text.contains('village') || text.contains('town')) return 'village';
    if (text.contains('mirror')) return 'mirror';
    if (text.contains('bridge')) return 'bridge';
    if (text.contains('campfire') || text.contains('camp')) return 'camp';
    if (text.contains('forest') || text.contains('tree')) return 'forest';
    if (text.contains('sea') ||
        text.contains('shore') ||
        text.contains('ocean')) {
      return 'shore';
    }
    return 'fields';
  }

  String _deriveWeatherTag(String eventText) {
    final text = eventText.toLowerCase();
    if (text.contains('storm') || text.contains('thunder')) return 'storm';
    if (text.contains('rain') || text.contains('drizzle')) return 'rain';
    if (text.contains('snow') || text.contains('blizzard')) return 'snow';
    if (text.contains('fog') || text.contains('mist')) return 'mist';
    if (text.contains('wind') || text.contains('gust')) return 'wind';
    return 'clear';
  }

  String _deriveTimeTag(String eventText, String mood) {
    final text = eventText.toLowerCase();
    if (text.contains('night') ||
        text.contains('moon') ||
        text.contains('stars') ||
        mood == 'spooky' ||
        mood == 'mysterious') {
      return 'night';
    }
    if (text.contains('sunset') || text.contains('dusk')) return 'sunset';
    if (text.contains('sunrise') || text.contains('dawn')) return 'dawn';
    return 'day';
  }

  void _handleWidgetUri(Uri? uri) {
    if (uri == null) return;
    final pathOrHost = uri.path.isNotEmpty ? uri.path : '/${uri.host}';

    switch (pathOrHost) {
      case '/story':
        AppNavigator.pushNamed('/story');
        break;
      case '/history':
        AppNavigator.pushNamed('/history');
        break;
      default:
        AppNavigator.pushNamed('/story');
        break;
    }
  }
}
