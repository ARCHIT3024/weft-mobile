import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../core/widgets/weft_buttons.dart';
import '../../core/widgets/weft_text_field.dart';
import '../../routing/routes.dart';
import 'state/auth_controller.dart';
import 'widgets/auth_widgets.dart';

/// Register (task 2.5): name, email, password, confirm. Validation mirrors
/// `RegisterRequest` in weft-backend/app/schemas/auth.py. The backend returns
/// a profile (not tokens), so the controller logs in immediately afterwards;
/// the router then redirects to the map.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
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
          .register(
            name: _name.text,
            email: _email.text,
            password: _password.text,
          );
    } on AccountCreatedButLoginFailed {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created. Please sign in to continue.'),
        ),
      );
      _goToLogin();
    } catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _goToLogin() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: _goToLogin)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              WeftSpacing.xl,
              0,
              WeftSpacing.xl,
              WeftSpacing.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AuthHeader(
                        title: 'Create your account',
                        subtitle:
                            'Track your reports, upvote issues near you '
                            'and earn civic points.',
                      ),
                      const SizedBox(height: WeftSpacing.xl),
                      if (_error != null) ...[
                        FormBanner.error(_error!),
                        const SizedBox(height: WeftSpacing.lg),
                      ],
                      WeftTextField(
                        fieldKey: const Key('register_name'),
                        label: 'Full name',
                        controller: _name,
                        prefixIcon: Icons.person_outline,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        validator: Validators.name,
                      ),
                      const SizedBox(height: WeftSpacing.lg),
                      WeftTextField(
                        fieldKey: const Key('register_email'),
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
                        fieldKey: const Key('register_password'),
                        label: 'Password',
                        helperText:
                            'At least ${Validators.passwordMinLength} characters',
                        controller: _password,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        validator: Validators.newPassword,
                      ),
                      const SizedBox(height: WeftSpacing.lg),
                      WeftPasswordField(
                        fieldKey: const Key('register_confirm'),
                        label: 'Confirm password',
                        controller: _confirm,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.newPassword],
                        validator: (v) =>
                            Validators.confirmPassword(v, _password.text),
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: WeftSpacing.xl),
                      WeftPrimaryButton(
                        key: const Key('register_submit'),
                        label: 'Create account',
                        isLoading: _submitting,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: WeftSpacing.lg),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            'Already have an account?',
                            style: TextStyle(color: WeftColors.textSecondary),
                          ),
                          TextButton(
                            onPressed: _submitting ? null : _goToLogin,
                            child: const Text('Sign in'),
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
