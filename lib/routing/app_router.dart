/// GoRouter configuration for Weft mobile app.
///
/// Routes:
///   /splash       — App launch screen
///   /onboarding   — First-time user onboarding (3 slides)
///   /login        — Email/password + Google + Apple + anonymous
///   /register     — New citizen account
///   /home         — Tab shell: map, my reports, notifications, profile
///   /report       — Issue submission flow (camera → category → location)
///   /issue/:id    — Issue detail screen
library;

import 'package:go_router/go_router.dart';

import '../screens/splash_screen.dart';
import '../screens/home_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    // Phase 2 routes will be added here:
    // /onboarding, /login, /register, /report, /issue/:id
  ],
);
