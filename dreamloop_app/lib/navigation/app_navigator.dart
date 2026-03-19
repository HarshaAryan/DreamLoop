import 'package:flutter/material.dart';

class AppNavigator {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static void pushNamed(String routeName) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    navigator.pushNamed(routeName);
  }

  static void pushReplacementNamed(String routeName) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    navigator.pushReplacementNamed(routeName);
  }
}
