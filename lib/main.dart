import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'routing/app_router.dart';
import 'services/api_client.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Dio HTTP client with JWT interceptors
  ApiClient.init();

  runApp(
    const ProviderScope(
      child: WeftApp(),
    ),
  );
}

class WeftApp extends StatelessWidget {
  const WeftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Weft',
      debugShowCheckedModeBanner: false,
      theme: WeftTheme.light,
      routerConfig: appRouter,
    );
  }
}
