/// Guarded Firebase start-up.
///
/// There is no `google-services.json` / `GoogleService-Info.plist` in the repo
/// yet (see FIREBASE_SETUP.md), and `Firebase.initializeApp()` throws without
/// them. The app must still start: push notifications are an enhancement, not
/// a prerequisite for reporting an issue. FCM wiring is tasks 2.29–2.31; that
/// work should check [FirebaseBootstrap.isAvailable] before touching
/// `FirebaseMessaging`.
library;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool _available = false;

  /// True only if `Firebase.initializeApp()` succeeded this launch.
  static bool get isAvailable => _available;

  /// Never throws. Returns whether Firebase is usable.
  static Future<bool> initialize() async {
    try {
      await Firebase.initializeApp().timeout(const Duration(seconds: 5));
      _available = true;
    } catch (e) {
      _available = false;
      debugPrint(
        'Firebase not initialised ($e). Push notifications are disabled — '
        'add the platform config files described in FIREBASE_SETUP.md.',
      );
    }
    return _available;
  }
}
