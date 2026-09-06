import 'package:flutter/material.dart';

import '../features/account/account_screen.dart';
import '../features/onboarding/welcome_flow.dart';
import '../features/shell/nflbot_shell.dart';
import '../features/watch/watch_connect_screen.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String watch = '/watch';
  static const String settings = '/settings';
  static const String intelligence = '/progress';
}

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.onboarding:
        return MaterialPageRoute(
          builder: (_) => WelcomeFlow(onComplete: () {}),
        );
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const NflBotShell());
      case AppRoutes.watch:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Watch')),
            body: const WatchConnectScreen(),
          ),
        );
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const AccountScreen());
      default:
        return MaterialPageRoute(builder: (_) => const NflBotShell());
    }
  }
}
