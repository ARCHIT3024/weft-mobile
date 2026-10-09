import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/feature_flags.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../core/widgets/weft_buttons.dart';
import '../../core/widgets/weft_logo.dart';
import '../../core/widgets/weft_text_field.dart';
import '../../routing/routes.dart';
import 'state/auth_controller.dart';
import 'widgets/auth_widgets.dart';

/// Login (task 2.4): email + password, "Continue anonymously", link to
/// register. Google Sign-In only behind `FeatureFlags.googleSignIn` (off —
/// backend task 1.4 does not exist).
///
/// On success the router redirect takes over (to [from], or the map).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.from});

  /// Where to return after signing in (e.g. an issue the user wanted to
  /// upvote). Validated by the redirect policy.
  final String? from;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .login(email: _email.text, password: _password.text);
      // Navigation happens via the router redirect.
    } catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _continueAnonymously() async {
    await ref.read(authControllerProvider.notifier).continueAnonymously();
    // Anonymous users may stay on /login (to upgrade later), so the redirect
    // does not move them — navigate explicitly.
    if (mounted) context.go(Routes.map);
  }

  void _googleSignIn() {
    // TODO(task 2.4 / backend 1.4): obtain an ID token with the
    // google_sign_in package, then call
    // authController -> AuthRepository.loginWithGoogle(idToken).
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google Sign-In is not available yet.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final isAnonymous = auth.isAnonymous;
    final canPop = context.canPop();

    return Scaffold(
      appBar: canPop || isAnonymous
          ? AppBar(
              leading: BackButton(
                onPressed: () =>
                    canPop ? context.pop() : context.go(Routes.map),
              ),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(WeftSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!canPop && !isAnonymous) ...[
                        const Center(
                          child: WeftLogo(size: 64, showWordmark: false),
                        ),
                        const SizedBox(height: WeftSpacing.xl),
                      ],
                      AuthHeader(
                        title: 'Welcome back',
                        subtitle: isAnonymous
                            ? 'Sign in to upvote issues and track your reports.'
                            : 'Sign in to report and track civic issues.',
                      ),
                      const SizedBox(height: WeftSpacing.xl),
                      if (auth.sessionExpired && _error == null) ...[
                        const FormBanner.info(
                          'Your session has expired. Please sign in again.',
                        ),
                        const SizedBox(height: WeftSpacing.lg),
                      ],
                      if (_error != null) ...[
                        FormBanner.error(_error!),
                        const SizedBox(height: WeftSpacing.lg),
                      ],
                      WeftTextField(
                        fieldKey: const Key('login_email'),
                        label: 'Email',
                        controller: _email,
                        prefixIcon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        validator: Validators.email,
                      ),
                      const SizedBox(height: WeftSpacing.lg),
                      WeftPasswordField(
                        fieldKey: const Key('login_password'),
                        label: 'Password',
                        controller: _password,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        validator: Validators.loginPassword,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: WeftSpacing.xl),
                      WeftPrimaryButton(
                        key: const Key('login_submit'),
                        label: 'Sign in',
                        isLoading: _submitting,
                        onPressed: _submit,
                      ),
                      if (FeatureFlags.googleSignIn) ...[
                        const SizedBox(height: WeftSpacing.md),
                        WeftSecondaryButton(
                          label: 'Continue with Google',
                          icon: Icons.account_circle_outlined,
                          onPressed: _submitting ? null : _googleSignIn,
                        ),
                      ],
                      if (!isAnonymous) ...[
                        const SizedBox(height: WeftSpacing.md),
                        WeftSecondaryButton(
                          key: const Key('login_anonymous'),
                          label: 'Continue anonymously',
                          icon: Icons.visibility_off_outlined,
                          onPressed: _submitting ? null : _continueAnonymously,
                        ),
                        const SizedBox(height: WeftSpacing.xs),
                        const Text(
                          'Report without an account. No name or email is '
                          'stored. You can’t upvote until you sign in.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: WeftColors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: WeftSpacing.lg),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            'New to Weft?',
                            style: TextStyle(color: WeftColors.textSecondary),
                          ),
                          TextButton(
                            key: const Key('login_to_register'),
                            onPressed: _submitting
                                ? null
                                : () => context.push(Routes.register),
                            child: const Text('Create an account'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
