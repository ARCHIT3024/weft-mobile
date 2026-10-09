import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/widgets/weft_logo.dart';

/// Splash (task 2.2). Purely presentational: while `AuthController` restores
/// the session the router holds the user here, then redirects (language →
/// onboarding → login, or straight to the map). No timers, no navigation code.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WeftColors.navy,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const WeftLogo(),
            const SizedBox(height: 8),
            Text(
              'Report. Track. Resolve.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 48),
            Semantics(
              label: 'Loading',
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: WeftColors.teal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
