// FILE: features/onboarding/presentation/widgets/welcome_page.dart
// The four welcome pages: what each one says and the real exchange it plays, plus the widget
// that lays one page out. The exchange sits up under the mark and the words sit low, near the
// thumb and the button, so each page reads top to bottom like a turn. A page keeps its state
// when swiped away, so going back shows it finished instead of playing it again.

import 'package:flutter/material.dart';

import '../../../../core/theme/parley_colors.dart';
import '../../../../core/widgets/reveal.dart';
import 'exchange.dart';

typedef WelcomeContent = ({String title, String body, List<Widget> exchange});

const List<WelcomeContent> welcomePages = [
  (
    title: 'Ask, and see\nhow it knows.',
    body:
        'Answers stream in as Claude writes them, with its reasoning and the '
        'pages it read one tap away.',
    exchange: [
      YouSaid('Is the ferry to Cacilhas running today?'),
      ParleyLabel(),
      StepLine(
        'Searched the web for "Cacilhas ferry today"',
        icon: Icons.travel_explore,
      ),
      ParleySaid(
        'Yes. Boats leave Cais do Sodré every 20 minutes until 21:00, then '
        'every 30.',
      ),
      SourceLine(title: 'Ferry timetable', detail: 'transtejo.pt'),
    ],
  ),
  (
    title: 'Hand it the\nfine print.',
    body:
        'Photos, receipts and PDFs. Every answer points to the page and the '
        'exact words.',
    exchange: [
      YouSaid('When is rent due?', attachment: 'Rental agreement.pdf'),
      ParleyLabel(),
      ParleySaid(
        'On the 1st of each month. A EUR 50 fee applies after five days.',
      ),
      SourceLine(
        title: 'Page 1',
        detail:
            '"A late fee of EUR 50 applies if rent is more than 5 days late."',
      ),
    ],
  ),
  (
    title: 'Give it work,\nnot just questions.',
    body:
        'Tasks lets Claude use the app’s own tools: your list, your '
        'reminders, on your phone.',
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
        'They stay on this phone, saved per account. The Claude key never '
        'leaves Parley’s server, and you can delete your account any time.',
      ),
    ],
  ),
];

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key, required this.content});
  final WelcomeContent content;

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final text = Theme.of(context).textTheme;
    final page = widget.content;
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Exchange(lines: page.exchange),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 28, bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Reveal(child: Text(page.title, style: text.headlineMedium)),
                    const SizedBox(height: 12),
                    Reveal(
                      delay: const Duration(milliseconds: 120),
                      child: Text(
                        page.body,
                        style: text.bodyLarge?.copyWith(
                          color: context.colors.muted,
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
  }
}
