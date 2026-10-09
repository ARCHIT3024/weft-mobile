import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_language.dart';
import '../../core/storage/app_preferences.dart';
import '../../core/theme.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/weft_buttons.dart';
import '../../data/models/user_profile.dart';
import '../../routing/routes.dart';
import '../auth/state/auth_controller.dart';
import '../language/widgets/language_picker.dart';

/// Profile tab (task 2.9): name, email, trust score, total points,
/// gamification title (from `GET /users/me`), language preference, logout
/// (`POST /auth/logout` with this device's refresh token, D-3).
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _loading = false;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    if (!ref.read(authControllerProvider).isAuthenticated) return;
    if (mounted) setState(() => _loading = true);
    await ref.read(authControllerProvider.notifier).refreshProfile();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _changeLanguage() async {
    final current = ref.read(effectiveLanguageProvider);
    final chosen = await showLanguagePickerSheet(context, current: current);
    if (chosen == null || chosen == current) return;
    await ref.read(selectedLanguageProvider.notifier).select(chosen);
    await ref
        .read(authControllerProvider.notifier)
        .updatePreferredLanguage(chosen);
  }

  Future<void> _logout({required bool anonymous}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(anonymous ? 'Leave anonymous mode?' : 'Log out?'),
        content: Text(
          anonymous
              ? 'You can sign in or create an account next.'
              : 'You will need to sign in again to upvote and track '
                    'your reports.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(anonymous ? 'Continue' : 'Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _loggingOut = true);
    // The router redirects to /login once auth state is unauthenticated.
    await ref.read(authControllerProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final language = ref.watch(effectiveLanguageProvider);

    final Widget body;
    if (auth.isAnonymous) {
      body = _AnonymousProfile(
        language: language,
        onChangeLanguage: _changeLanguage,
        onLeave: () => _logout(anonymous: true),
      );
    } else if (auth.user == null) {
      body = _loading
          ? const LoadingView(message: 'Loading your profile')
          : ErrorView(
              title: "Couldn't load your profile",
              message: 'Check your connection and try again.',
              onRetry: _refresh,
            );
    } else {
      body = RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            WeftSpacing.screen,
            WeftSpacing.screen,
            WeftSpacing.screen,
            WeftSpacing.fabClearance,
          ),
          children: [
            _ProfileHeader(user: auth.user!),
            const SizedBox(height: WeftSpacing.lg),
            _StatsRow(user: auth.user!),
            const SizedBox(height: WeftSpacing.lg),
            _LanguageTile(language: language, onTap: _changeLanguage),
            const SizedBox(height: WeftSpacing.xl),
            WeftSecondaryButton(
              key: const Key('profile_logout'),
              label: _loggingOut ? 'Logging out…' : 'Log out',
              icon: Icons.logout,
              onPressed: _loggingOut ? null : () => _logout(anonymous: false),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: body,
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    final initial = user.displayName.characters.first.toUpperCase();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(WeftSpacing.lg),
        child: Row(
          children: [
            ExcludeSemantics(
              child: CircleAvatar(
                radius: 32,
                backgroundColor: WeftColors.navy,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: WeftSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      user.displayName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: WeftColors.navy,
                      ),
                    ),
                  ),
                  if (user.email != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      user.email!,
                      style: const TextStyle(color: WeftColors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: WeftSpacing.sm),
                  _TitleChip(title: user.title),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleChip extends StatelessWidget {
  const _TitleChip({required this.title});

  final String? title;

  @override
  Widget build(BuildContext context) {
    final label = title ?? 'Newcomer';
    return Semantics(
      label: 'Title: $label',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events_outlined,
              size: 16,
              color: Color(0xFF92400E),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF92400E),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    final trust = user.trustScore;
    final trustText = trust == trust.roundToDouble()
        ? trust.toStringAsFixed(0)
        : trust.toStringAsFixed(1);
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.verified_user_outlined,
            label: 'Trust score',
            value: '$trustText%',
            hint: 'Share of your reports that were resolved',
          ),
        ),
        const SizedBox(width: WeftSpacing.md),
        Expanded(
          child: _StatCard(
            icon: Icons.star_outline,
            label: 'Points',
            value: '${user.totalPoints}',
            hint: 'Earned by reporting and upvoting',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.hint,
  });

  final IconData icon;
  final String label;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value. $hint',
      excludeSemantics: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(WeftSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: WeftColors.tealAccessible),
              const SizedBox(height: WeftSpacing.sm),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: WeftColors.navy,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: WeftColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({required this.language, required this.onTap});

  final AppLanguage language;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        minTileHeight: 56,
        leading: const Icon(Icons.translate),
        title: const Text('Language'),
        subtitle: Text(language.nativeName),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _AnonymousProfile extends StatelessWidget {
  const _AnonymousProfile({
    required this.language,
    required this.onChangeLanguage,
    required this.onLeave,
  });

  final AppLanguage language;
  final VoidCallback onChangeLanguage;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        WeftSpacing.screen,
        WeftSpacing.screen,
        WeftSpacing.screen,
        WeftSpacing.fabClearance,
      ),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(WeftSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.visibility_off_outlined, color: WeftColors.navy),
                    SizedBox(width: WeftSpacing.sm),
                    Expanded(
                      child: Text(
                        "You're browsing anonymously",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: WeftColors.navy,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: WeftSpacing.sm),
                const Text(
                  'You can report issues without an account. Sign in to '
                  'upvote, track your reports and earn points.',
                  style: TextStyle(color: WeftColors.textSecondary),
                ),
                const SizedBox(height: WeftSpacing.lg),
                WeftPrimaryButton(
                  label: 'Sign in',
                  onPressed: () =>
                      context.push(Routes.loginFrom(Routes.profile)),
                ),
                const SizedBox(height: WeftSpacing.sm),
                WeftSecondaryButton(
                  label: 'Create an account',
                  onPressed: () => context.push(Routes.register),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: WeftSpacing.lg),
        _LanguageTile(language: language, onTap: onChangeLanguage),
        const SizedBox(height: WeftSpacing.lg),
        TextButton.icon(
          onPressed: onLeave,
          icon: const Icon(Icons.logout),
          label: const Text('Leave anonymous mode'),
        ),
      ],
    );
  }
}
