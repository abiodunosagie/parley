// Drives the real app against the real backend and captures the README screenshots: every tab
// and tool doing its job. The photo and PDF pickers are swapped for the sample files in
// fixtures.dart, because a test cannot tap the system pickers. Needs a signed-in Simulator; the
// welcome pages are marked seen here so the run starts in the app. Run with the command in
// test_driver/integration_test.dart.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:parley/app/app.dart';
import 'package:parley/core/config/env.dart';
import 'package:parley/core/media/photo_picker.dart';
import 'package:parley/core/models/claude_model.dart';
import 'package:parley/core/session/access_token_provider.dart';
import 'package:parley/core/state/selected_model_provider.dart';
import 'package:parley/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:parley/features/conversation/data/repositories/document_repository_impl.dart';
import 'package:parley/features/conversation/domain/entities/attachment.dart';
import 'package:parley/features/conversation/domain/repositories/document_repository.dart';
import 'package:parley/features/home/presentation/widgets/parley_tab_bar.dart';
import 'package:parley/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../test/helpers/fakes.dart';
import '../test/helpers/launch.dart';
import 'fixtures.dart';

class _SamplePhoto extends PhotoPicker {
  @override
  Future<PickedPhoto?> pick(PhotoSource source) async =>
      (bytes: receiptPhoto, mediaType: 'image/jpeg');
}

class _SamplePdf implements DocumentRepository {
  @override
  Future<Attachment?> pick() async =>
      Attachment(leasePdf, Attachment.pdf, name: 'Rental agreement.pdf');
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screenshots', (tester) async {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabasePublishableKey,
    );
    final container = ProviderContainer(
      overrides: [
        accessTokenProvider.overrideWith(
          (ref) => ref.watch(authRepositoryProvider).accessToken,
        ),
        photoPickerProvider.overrideWithValue(_SamplePhoto()),
        documentRepositoryProvider.overrideWithValue(_SamplePdf()),
        onboardingRepositoryProvider.overrideWithValue(
          MemoryOnboarding(seen: true),
        ),
      ],
    );
    container.read(selectedModelProvider.notifier).select(ClaudeModel.sonnet);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ParleyApp()),
    );
    await pumpPastLaunch(tester);
    expect(
      find.byType(ParleyTabBar),
      findsOneWidget,
      reason: 'sign in on the Simulator first',
    );

    Future<void> shot(String name) async {
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump(const Duration(milliseconds: 600));
      await binding.takeScreenshot(name);
    }

    Future<void> waitWhile(Finder busy, {int seconds = 120}) async {
      // Let the request start, then wait until the busy control goes away.
      for (var i = 0; i < 10 && busy.evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      for (var i = 0; i < seconds * 4 && busy.evaluate().isNotEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      await tester.pump(const Duration(seconds: 1));
    }

    Future<void> tab(String label) async {
      await tester.tap(
        find.descendant(
          of: find.byType(ParleyTabBar),
          matching: find.text(label),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> ask(String text) async {
      await tester.enterText(find.byType(TextField).last, text);
      await tester.pump();
      await tester.tap(find.byTooltip('Send'));
      await waitWhile(find.byTooltip('Stop'));
    }

    final stop = find.byTooltip('Stop');

    // Chat with web search: reasoning folded above, sources below.
    await tab('Chat');
    await tester.tap(find.byType(Switch));
    await tester.pump();
    await ask(
      'What is new in the latest stable Flutter release? Three short bullets.',
    );
    expect(stop, findsNothing);
    await shot('chat');

    // Look: a photo of a receipt.
    await tab('Look');
    await tester.tap(find.text('Choose from library'));
    await tester.pumpAndSettle();
    await ask('What is in this photo, and what was the most expensive item?');
    await shot('look');

    // Read: a PDF, answers with page citations.
    await tab('Read');
    await tester.tap(find.text('Open a PDF'));
    await tester.pumpAndSettle();
    await ask('When is rent due, and what happens if I pay late?');
    await shot('read');

    // Tasks: the agent calls tools on the phone.
    await tab('Tasks');
    await ask(
      'Add "call the landlord about the heating" for tomorrow, high priority',
    );
    await shot('tasks');

    // Tools.
    await tab('Tools');
    await shot('tools');

    await tester.tap(find.text('Rewrite'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).first,
      'hey, cant make the 3pm today, something came up. can we do tmrw same time? sorry!!',
    );
    await tester.tap(find.text('Formal'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Rewrite'));
    await waitWhile(find.widgetWithText(OutlinedButton, 'Stop'));
    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();
    await shot('rewrite');
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Receipts'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from library'));
    await waitWhile(find.text('Reading the receipt...'));
    await tester.drag(find.byType(ListView).first, const Offset(0, -260));
    await tester.pumpAndSettle();
    await shot('receipts');
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Extract'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use a sample post'));
    await tester.tap(find.text('Extract fields'));
    await waitWhile(find.textContaining('tap to stop'));
    await tester.drag(find.byType(ListView).first, const Offset(0, -420));
    await tester.pumpAndSettle();
    await shot('extract');
  });
}
