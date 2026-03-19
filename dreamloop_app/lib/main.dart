import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:dreamloop/services/auth_service.dart';
import 'package:dreamloop/services/notification_service.dart';
import 'package:dreamloop/services/widget_sync_service.dart';
import 'package:dreamloop/app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('No .env found, continuing with defaults: $e');
  }

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await NotificationService().initialize();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthService())],
      child: const DreamLoopApp(),
    ),
  );

  // Start widget bridge after app is mounted so navigator is available.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    WidgetSyncService().initialize();
  });
}
