import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/app_preferences.dart';
import '../../core/theme.dart';
import '../../core/widgets/weft_buttons.dart';

/// Onboarding (task 2.3): three slides — report, track, upvote — with Skip.
/// Shown once: completing or skipping marks it seen and the router moves on.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _Slide {
  const _Slide(this.icon, this.title, this.body);
  final IconData icon;
  final String title;
  final String body;
}

const _slides = [
  _Slide(
    Icons.photo_camera_outlined,
    'Report in seconds',
    'Snap a photo of a pothole, broken light or overflowing drain. '
        'We add the location — you can even report anonymously.',
  ),
  _Slide(
    Icons.track_changes,
    'Track every step',
    'See your report move from Reported to In Progress to Resolved, '
        'and get notified when something changes.',
  ),
  _Slide(
    Icons.thumb_up_alt_outlined,
    'Upvote what matters',
    'Spotted an issue someone already reported? Upvote it so the city '
        'knows how many people it affects.',
  ),
];

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  bool get _isLast => _page == _slides.length - 1;

  Future<void> _finish() =>
      ref.read(onboardingSeenProvider.notifier).markSeen();

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(WeftSpacing.sm),
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Skip'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) =>
                    _SlideView(slide: _slides[i], index: i),
              ),
            ),
            Semantics(
              label: 'Slide ${_page + 1} of ${_slides.length}',
              excludeSemantics: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _slides.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _page ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page
                            ? WeftColors.tealAccessible
                            : WeftColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(WeftSpacing.screen),
              child: WeftPrimaryButton(
                label: _isLast ? 'Get started' : 'Next',
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide, required this.index});

  final _Slide slide;
  final int index;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: WeftSpacing.xl),
      child: Column(
        children: [
          const SizedBox(height: WeftSpacing.xl),
          ExcludeSemantics(
            child: Container(
              width: 160,
              height: 160,
              decoration: const BoxDecoration(
                color: WeftColors.tealBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(slide.icon, size: 80, color: WeftColors.tealDark),
            ),
          ),
          const SizedBox(height: WeftSpacing.xxl),
          Semantics(
            header: true,
            child: Text(
              slide.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: WeftColors.navy,
              ),
            ),
          ),
          const SizedBox(height: WeftSpacing.md),
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: WeftColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
