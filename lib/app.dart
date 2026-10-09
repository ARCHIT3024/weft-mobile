import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/app_language.dart';
import 'core/storage/app_preferences.dart';
import 'core/theme.dart';
import 'routing/app_router.dart';

class WeftApp extends ConsumerWidget {
  const WeftApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final language = ref.watch(effectiveLanguageProvider);
    return MaterialApp.router(
      title: 'Weft',
      debugShowCheckedModeBanner: false,
      theme: WeftTheme.light,
      routerConfig: router,
      locale: language.locale,
      supportedLocales: AppLanguage.supportedLocales,
      // Task 4.13: add `AppLocalizations.delegate` here when ARB files land.
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
