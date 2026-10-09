import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_language.dart';
import '../../core/storage/app_preferences.dart';
import '../../core/theme.dart';
import '../../core/widgets/weft_buttons.dart';
import '../../core/widgets/weft_logo.dart';
import 'widgets/language_picker.dart';

/// First-launch language choice (task 2.2). English is pre-selected; the
/// choice is stored locally and the router moves on to onboarding.
///
/// Real translations are task 4.13 — until then app copy stays English and
/// only framework widgets (dates, tooltips) follow the chosen locale.
class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({super.key});

  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> {
  late AppLanguage _selected =
      ref.read(selectedLanguageProvider) ?? AppLanguage.fallback;
  bool _saving = false;

  Future<void> _continue() async {
    setState(() => _saving = true);
    // The router redirects to onboarding as soon as this is stored.
    await ref.read(selectedLanguageProvider.notifier).select(_selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(WeftSpacing.screen),
                children: [
                  const SizedBox(height: WeftSpacing.lg),
                  const Center(child: WeftLogo(size: 64, showWordmark: false)),
                  const SizedBox(height: WeftSpacing.xl),
                  Semantics(
                    header: true,
                    child: const Text(
                      'Choose your language',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: WeftColors.navy,
                      ),
                    ),
                  ),
                  const SizedBox(height: WeftSpacing.sm),
                  const Text(
                    'You can change this later in your profile. '
                    'More translations are on the way.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: WeftColors.textSecondary),
                  ),
                  const SizedBox(height: WeftSpacing.lg),
                  LanguagePicker(
                    selected: _selected,
                    onChanged: (lang) => setState(() => _selected = lang),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(WeftSpacing.screen),
              child: WeftPrimaryButton(
                label: 'Continue',
                isLoading: _saving,
                onPressed: _continue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
