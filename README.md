# weft_mobile — Weft citizen app (Flutter)

Citizens report civic issues (photo + category + location), track them, and
upvote issues near them. Talks to `weft-backend` (`/v1`).

## Running

```bash
flutter pub get
flutter run                                   # dev flavour (default)
flutter run --dart-define=WEFT_ENV=staging    # staging (not deployed yet)
flutter run --dart-define=WEFT_ENV=prod
# Override the API host, e.g. a physical phone → laptop on the LAN:
flutter run --dart-define=WEFT_API_BASE_URL=http://192.168.1.20:8000/v1
# Google Sign-In button (keep OFF until backend task 1.4 exists):
flutter run --dart-define=WEFT_ENABLE_GOOGLE_SIGN_IN=true
```

Dev API base URL (`lib/core/env_config.dart`): Android → `http://10.0.2.2:8000/v1`
(the emulator's alias for the host), everything else → `http://localhost:8000/v1`.
Cleartext http is allowed in **debug builds only**
(`android/app/src/debug/AndroidManifest.xml`).

Demo login (backend seed): `citizen@weft.local` / `DevPassword123!`.

Firebase: no `google-services.json` / `GoogleService-Info.plist` yet — the app
starts without them (`lib/core/firebase_bootstrap.dart`); see `FIREBASE_SETUP.md`.

## Checks

```bash
flutter analyze   # must print "No issues found!"
flutter test
```

## Architecture

- **State:** Riverpod 2 (`Notifier`/`Provider`, no code generation).
- **Navigation:** GoRouter with a `StatefulShellRoute` home shell (tabs keep state).
- **HTTP:** Dio via `ApiClient` (JWT header, 401 → single refresh → queued replay).
- **Models:** hand-written `fromJson`/`toJson` — no build_runner, no generated
  files. Field names are the backend's (`weft-backend/app/schemas/*.py` is the
  source of truth).
- **Tokens:** `flutter_secure_storage` (Keystore / Keychain). Unlike the web
  dashboard (memory-only, D-9 — XSS), a native app has no shared script
  context, so persisting the refresh token securely is the right trade-off.

```
lib/
  main.dart                 bootstrap: guarded Firebase, SharedPreferences, ProviderScope
  app.dart                  WeftApp (MaterialApp.router, theme, locale)
  core/
    constants.dart          URLs, map defaults, storage keys, server limits
    env_config.dart         flavours (--dart-define), API base URL + origin
    feature_flags.dart      compile-time flags (Google Sign-In: off)
    firebase_bootstrap.dart Firebase.initializeApp that never crashes start-up
    media_url.dart          resolveMediaUrl: "/media/..." → API origin
    validators.dart         form rules mirroring the backend schemas
    theme.dart              WeftColors / WeftSpacing / WeftTheme (WCAG notes)
    l10n/app_language.dart  the 6 supported languages (en hi ta te mr bn)
    storage/                token_storage.dart (secure), app_preferences.dart
    widgets/                shared UI kit (see below)
  services/api_client.dart  Dio + JWT + refresh/queue interceptor
  data/
    api_providers.dart      apiClientProvider, dioProvider, sessionEventsProvider
    models/                 UserProfile, AuthTokens, IssueSummary/Detail/Nearby, ...
    repositories/           Auth/User/Issue/Upvote/Notification repositories + providers
  routing/
    routes.dart             every path constant (Routes.*)
    redirect.dart           pure redirect policy (unit-tested)
    app_router.dart         routerProvider + the full route table
  features/
    splash/ language/ onboarding/ auth/ home/ profile/   (built)
    map/ issues/ my_reports/                             (F-MAP placeholders)
    report/                                              (F-REPORT placeholders + draft state)
    notifications/                                       (notifications/FCM placeholder)
test/                       mirrors lib/; helpers/ has a fake Dio adapter + JSON fixtures
```

### Rules for feature work

1. **Don't edit `routing/app_router.dart`.** Every Phase 2 route is already
   registered and points at a screen file in its feature folder — replace that
   file's contents. Navigate with `Routes.*` constants.
2. Call the API only through repositories (`ref.read(issueRepositoryProvider)`
   etc.). They throw only `ApiException` (`isNetwork`, `isUnauthorized`,
   `isNotFound`, `isConflict`, `isRateLimited`, `code`, `message`).
3. Display images with `IssueImage.url` / `resolveMediaUrl(...)`, never the raw
   `cdn_url` (it is root-relative in dev).
4. Use the UI kit: `StatusBadge`, `CategoryIcon`, `IssueCategory.visual` /
   `IssueStatus.visual` (label/icon/colour), `WeftPrimaryButton`,
   `WeftSecondaryButton`, `WeftTextField`, `WeftPasswordField`, `LoadingView`,
   `ErrorView.fromError(e, onRetry: ...)`, `EmptyView`.
5. Accessibility (WCAG 2.1 AA is a Phase 2 exit criterion): ≥ 48 dp touch
   targets, semantic labels on icon-only controls, status never by colour
   alone, text on teal uses `WeftColors.tealAccessible` (brand teal is 3:1).
6. Lists inside the home shell need `WeftSpacing.fabClearance` bottom padding.
7. Auth state: `ref.watch(authControllerProvider)` → `AuthState`
   (`isAuthenticated`, `isAnonymous`, `user`). Anonymous users cannot upvote,
   see My Reports or notifications — offer
   `context.push(Routes.loginFrom(currentLocation))`.

### Route ownership

| Route | Screen file | Owner |
|---|---|---|
| `/splash` `/language` `/onboarding` `/login` `/register` `/profile` | `features/{splash,language,onboarding,auth,profile}/` | F-CORE (done) |
| `/map` (+ marker bottom sheet) | `features/map/map_screen.dart`, `features/map/widgets/issue_preview_sheet.dart` | F-MAP |
| `/issues/:id` | `features/issues/issue_detail_screen.dart` | F-MAP |
| `/my-reports` | `features/my_reports/my_reports_screen.dart` | F-MAP |
| `/report` → `/report/category` → `/report/details` → `/report/success` (extra: `CreateIssueResponse`) | `features/report/*.dart`, state in `features/report/state/report_draft.dart` | F-REPORT |
| `/notifications` (+ FCM) | `features/notifications/notifications_screen.dart` | notifications agent |

## Contract notes

The running backend differs from `openapi.yaml` in a few places; the
repositories follow the **running backend**: `GET /issues` uses `radius`,
`sort`, `order` (not `radius_m`, `sort_by`, `sort_dir`), and
`GET /issues/nearby` returns a plain array of `NearbyIssue` (not a paginated
object). `PATCH /users/me`, `GET /users/me/reports` and `/notifications/*` are
still mocks — see `TODO(contract)` markers in `lib/data/`.
