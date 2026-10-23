// FILE: features/onboarding/presentation/screens/onboarding_screen.dart
// The welcome pages, shown once per install before sign-in. The mark meets once at the top and
// then stays still; under it the four pages in widgets/welcome_page.dart each play a real
// exchange. Skip or Get started both mark the pages seen, and the router moves on to sign-in.
// This widget only owns the PageController and the current page.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/dimens.dart';
import '../../../../core/theme/parley_colors.dart';
import '../../../../core/widgets/parley_mark.dart';
import '../providers/onboarding_controller.dart';
import '../widgets/welcome_page.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  var _current = 0;

  bool get _last => _current == welcomePages.length - 1;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _finish() => ref.read(onboardingSeenProvider.notifier).finish();

  void _next() {
    // A second tap while the pages are still sliding would skip one (or finish early from the
    // third page), so it is ignored until the slide lands.
    final page = _pages.page;
    if (page != null && page != page.roundToDouble()) return;
    if (_last) return _finish();
    _pages.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              step: _current + 1,
              of: welcomePages.length,
              onSkip: _last ? null : _finish,
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 4),
              child: Center(child: MeetingMark(size: 88)),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: welcomePages.length,
                onPageChanged: (page) => setState(() => _current = page),
                itemBuilder: (context, i) =>
                    WelcomePage(content: welcomePages[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: SizedBox(
                height: kButtonHeight,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(_last ? 'Get started' : 'Continue'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "2 of 4" on the left, Skip on the right (gone on the last page).
class _Header extends StatelessWidget {
  const _Header({required this.step, required this.of, this.onSkip});
  final int step;
  final int of;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Text(
            '$step of $of',
            style: TextStyle(
              color: context.colors.muted,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const Spacer(),
        if (onSkip != null)
          TextButton(onPressed: onSkip, child: const Text('Skip')),
      ],
    ),
  );
}
