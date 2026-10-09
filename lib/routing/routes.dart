/// Every route path in the app. Navigate with these constants, never string
/// literals: `context.go(Routes.map)`, `context.push(Routes.issueDetail(id))`.
///
/// Ownership (Phase 2 agents edit screen files, never the router):
///   splash/language/onboarding/login/register/profile — F-CORE
///   map, issueDetail, myReports                       — F-MAP
///   report, reportCategory, reportDetails, reportSuccess — F-REPORT
///   notifications                                     — notifications agent
library;

abstract final class Routes {
  // ── Pre-auth ───────────────────────────────────────────────────
  static const splash = '/splash';
  static const language = '/language';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';

  // ── Home shell tabs (StatefulShellRoute; each keeps its state) ─
  static const map = '/map';
  static const myReports = '/my-reports';
  static const notifications = '/notifications';
  static const profile = '/profile';

  /// Tab order in the bottom navigation bar.
  static const shellTabs = [map, myReports, notifications, profile];

  // ── Full-screen routes over the shell (root navigator) ─────────
  /// Report flow, step 1 (photo). Opened by the Report FAB.
  static const report = '/report';
  static const reportCategory = '/report/category';
  static const reportDetails = '/report/details';

  /// Pass the `CreateIssueResponse` as `extra`.
  static const reportSuccess = '/report/success';

  static const issueDetailPattern = '/issues/:id';
  static String issueDetail(String issueId) => '/issues/$issueId';

  /// Login that returns to [from] after a successful sign-in, e.g. the
  /// "Sign in to upvote" prompt: `context.push(Routes.loginFrom(location))`.
  static String loginFrom(String from) =>
      Uri(path: login, queryParameters: {'from': from}).toString();

  /// Query parameter carrying the post-login destination.
  static const fromParam = 'from';

  /// Routes only meaningful before signing in; a signed-in user is bounced
  /// from these to the app.
  static const preAuth = {splash, language, onboarding, login, register};
}
