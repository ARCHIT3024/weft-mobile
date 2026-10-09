import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/firebase_bootstrap.dart';
import 'core/storage/app_preferences.dart';

export 'app.dart' show WeftApp;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Never blocks start-up on missing Firebase config (see firebase_bootstrap).
  await FirebaseBootstrap.initialize();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const WeftApp(),
    ),
  );
}
