import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dreamloop/config/theme.dart';
import 'package:dreamloop/services/auth_service.dart';
import 'package:dreamloop/screens/login_screen.dart';
import 'package:dreamloop/screens/onboarding_screen.dart';
import 'package:dreamloop/screens/character_creation_screen.dart';
import 'package:dreamloop/screens/invite_screen.dart';
import 'package:dreamloop/screens/story_screen.dart';
import 'package:dreamloop/screens/history_screen.dart';
import 'package:dreamloop/screens/home_screen.dart';
import 'package:dreamloop/navigation/app_navigator.dart';
import 'package:dreamloop/services/firestore_service.dart';
import 'package:dreamloop/models/user_model.dart';

class DreamLoopApp extends StatelessWidget {
  const DreamLoopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DreamLoop',
      debugShowCheckedModeBanner: false,
      theme: DreamTheme.darkTheme,
      navigatorKey: AppNavigator.navigatorKey,
      initialRoute: '/',
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    Widget page;

    switch (settings.name) {
      case '/':
        page = const _AuthGate();
        break;
      case '/login':
        page = const LoginScreen();
        break;
      case '/onboarding':
        page = const OnboardingScreen();
        break;
      case '/character':
        page = const CharacterCreationScreen();
        break;
      case '/invite':
        page = const InviteScreen();
        break;
      case '/home':
        page = const HomeScreen();
        break;
      case '/story':
        page = const StoryScreen();
        break;
      case '/history':
        page = const HistoryScreen();
        break;
      default:
        page = const LoginScreen();
    }

    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

/// Auth gate — redirects to login or story based on auth state
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    if (authService.isAuthenticated) {
      final userId = authService.userId;
      if (userId == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      return FutureBuilder<UserModel?>(
        future: FirestoreService().getUser(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final user = snapshot.data;
          final needsOnboarding =
              user == null ||
              user.relationshipType.isEmpty ||
              user.characterCustomization.isEmpty;
          if (needsOnboarding) {
            return const OnboardingScreen();
          }
          return const HomeScreen();
        },
      );
    }

    return const LoginScreen();
  }
}
