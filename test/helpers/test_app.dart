import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weft_mobile/core/constants.dart';
import 'package:weft_mobile/core/storage/app_preferences.dart';
import 'package:weft_mobile/core/storage/token_storage.dart';
import 'package:weft_mobile/data/api_providers.dart';
import 'package:weft_mobile/services/api_client.dart';

import 'fake_http.dart';

/// A ProviderContainer wired like production, but with in-memory tokens,
/// mock SharedPreferences and a fake HTTP adapter (no sockets).
Future<ProviderContainer> createTestContainer({
  required FakeHttpAdapter adapter,
  InMemoryTokenStorage? tokens,
  bool languageChosen = true,
  bool onboardingSeen = true,
  bool anonymous = false,
}) async {
  SharedPreferences.setMockInitialValues({
    if (languageChosen) AppConstants.prefLanguageCode: 'en',
    if (onboardingSeen) AppConstants.prefOnboardingSeen: true,
    if (anonymous) AppConstants.prefAnonymousMode: true,
  });
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      tokenStorageProvider.overrideWithValue(tokens ?? InMemoryTokenStorage()),
      // Real ApiClient (interceptors, refresh queue), fake transport for both
      // the main and the refresh Dio.
      apiClientProvider.overrideWith(
        (ref) => ApiClient(
          storage: ref.watch(tokenStorageProvider),
          dio: fakeDio(adapter),
          refreshDio: fakeDio(adapter),
          onSessionExpired: ref.watch(sessionEventsProvider).notifyExpired,
          enableLogging: false,
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Phone-sized surface (360×800 dp) so layouts behave as on a device.
void usePhoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Widget wrapWithContainer(ProviderContainer container, Widget child) =>
    UncontrolledProviderScope(container: container, child: child);
