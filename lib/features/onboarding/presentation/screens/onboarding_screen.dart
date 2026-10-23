// FILE: features/onboarding/presentation/screens/onboarding_screen.dart
// The welcome pages, shown once per install before sign-in. The mark meets once at the top and
// then stays still. Each of the four pages plays a real exchange: asking with web search, a PDF
// with its page cited, the agent using tools, and where your conversations go. Skip or Get
// started both mark the pages seen, and the router moves on to sign-in.
// This widget only owns the PageController and the current page.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/dimens.dart';
import '../../../../core/theme/parley_colors.dart';
import '../../../../core/widgets/parley_mark.dart';
import '../providers/onboarding_controller.dart';
import '../widgets/exchange.dart';
import '../widgets/reveal.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

typedef _Page = ({String title, String body, List<Widget> exchange});

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  var _current = 0;

  static const List<_Page> _content = [
    (
      title: 'Ask, and see\nhow it knows.',
      body: 'Answers stream in as Claude writes them, with its reasoning and the pages it read one tap away.',
      exchange: [
        YouSaid('Is the ferry to Cacilhas running today?'),
        ParleyLabel(),
        StepLine(
          'Searched the web for "Cacilhas ferry today"',
          icon: Icons.travel_explore,
        ),
        ParleySaid(
          'Yes. Boats leave Cais do Sodré every 20 minutes until 21:00, then every 30.',
        ),
        SourceLine(title: 'Ferry timetable', detail: 'transtejo.pt'),
      ],
    ),
    (
      title: 'Hand it the\nfine print.',
      body: 'Photos, receipts and PDFs. Every answer points to the page and the exact words.',
      exchange: [
        YouSaid('When is rent due?', attachment: 'Rental agreement.pdf'),
        ParleyLabel(),
        ParleySaid(
          'On the 1st of each month. A EUR 50 fee applies after five days.',
        ),
        SourceLine(
          title: 'Page 1',
          detail: '"A late fee of EUR 50 applies if rent is more than 5 days late."',
        ),
      ],
    ),
    (
      title: 'Give it work,\nnot just questions.',
      body: 'Tasks lets Claude use the app’s own tools: your list, your reminders, on your phone.',
      exchange: [
        YouSaid('Remind me to call the landlord tomorrow at 9'),
        ParleyLabel(),
        StepLine(
          'add_task  "Call the landlord"  tomorrow',
          icon: Icons.bolt,
          mono: true,
        ),
        StepLine('set_reminder  09:00', icon: Icons.bolt, mono: true),
        ParleySaid('Done. It is on tomorrow’s list, with a reminder at 9.'),
      ],
    ),
    (
      title: 'You and Claude,\nturn by turn.',
      body: 'Create an account or sign in, and start with anything.',
      exchange: [
        YouSaid('Where do my conversations go?'),
        ParleyLabel(),
        ParleySaid(
          'They stay on this phone, saved per account. The Claude key never leaves Parley’s server, and you can delete your account any time.',
        ),
      ],
    ),
  ];

  bool get _last => _current == _content.length - 1;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _finish() => ref.read(onboardingSeenProvider.notifier).finish();

  void _next() {
    if (_last) return _finish();
    _pages.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Text(
                      '${_current + 1} of ${_content.length}',
                      style: TextStyle(
                        color: colors.muted,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (!_last)
                    TextButton(onPressed: _finish, child: const Text('Skip')),
                ],
              ),
            ),
            // The mark plays its meeting once, as the welcome opens, then stays still on every
            // page: one constant, like the splash before it.
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(
                    begin: MediaQuery.disableAnimationsOf(context) ? 1 : 0,
                    end: 1,
                  ),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  builder: (_, meet, _) => ParleyMark(size: 88, meet: meet),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: _content.length,
                onPageChanged: (page) => setState(() => _current = page),
                itemBuilder: (context, i) {
                  final page = _content[i];
                  return LayoutBuilder(
                    builder: (context, box) => SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: box.maxHeight),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          // The exchange sits up under the mark; the words sit low, near the
                          // thumb and the button, so each page reads top to bottom like a turn.
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Exchange(lines: page.exchange),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 28,
                                bottom: 8,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Reveal(
                                    child: Text(
                                      page.title,
                                      style: text.headlineMedium,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Reveal(
                                    delay: const Duration(milliseconds: 120),
                                    child: Text(
                                      page.body,
                                      style: text.bodyLarge?.copyWith(
                                        color: colors.muted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
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
