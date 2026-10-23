// FILE: features/receipt/presentation/screens/receipt_screen.dart
// RECEIPT SCREEN: photo in, spending breakdown out. Pick or take a photo, Claude reads it into
// fixed fields, and the app adds it up by category. History in the app bar.
// Logic: receiptControllerProvider.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/dimens.dart';
import '../../../../core/widgets/history_sheet.dart';
import '../../../../core/widgets/notice.dart';
import '../../../../core/widgets/screen_intro.dart';
import '../../../home/presentation/widgets/feature_app_bar.dart';
import '../../domain/repositories/receipt_repository.dart';
import '../providers/receipt_controller.dart';
import '../providers/receipt_history_provider.dart';
import '../widgets/receipt_card.dart';

class ReceiptScreen extends ConsumerWidget {
  const ReceiptScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(receiptControllerProvider);
    final controller = ref.read(receiptControllerProvider.notifier);

    return Scaffold(
      appBar: FeatureAppBar(
        title: 'Receipts',
        actions: [
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.history),
            onPressed: () => showHistorySheet(
              context,
              entries: receiptHistoryProvider,
              onOpen: controller.open,
              onDelete: controller.deleteSaved,
              empty: 'Receipts you scan are kept here.',
            ),
          ),
          if (state is! ReceiptEmpty)
            IconButton(
              tooltip: 'New receipt',
              onPressed: controller.reset,
              icon: const Icon(Icons.add_a_photo_outlined),
            ),
        ],
      ),
      body: switch (state) {
        ReceiptEmpty(:final notice) => _PickPanel(
          notice: notice,
          onPick: controller.pickPhoto,
        ),
        ReceiptScanning(:final photo) => _Scroll([
          _Photo(photo.bytes),
          const LinearProgressIndicator(minHeight: 2),
          const SizedBox(height: 12),
          const Text('Reading the receipt...'),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: controller.cancel,
            child: const Text('Stop'),
          ),
        ]),
        ReceiptRead(:final scan) => _Scroll([
          _Photo(scan.photo),
          ReceiptCard(scan.receipt),
        ]),
        ReceiptFailed(:final photo, :final message) => _Scroll([
          _Photo(photo.bytes),
          Notice(message),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => controller.scan(photo),
            child: const Text('Try again'),
          ),
        ]),
      },
    );
  }
}

class _Scroll extends StatelessWidget {
  const _Scroll(this.children);
  final List<Widget> children;

  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.all(16), children: children);
}

class _Photo extends StatelessWidget {
  const _Photo(this.bytes);
  final Uint8List bytes;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: ClipRRect(
      borderRadius: kRadius,
      child: Image.memory(bytes, height: 180, fit: BoxFit.cover),
    ),
  );
}

class _PickPanel extends StatelessWidget {
  const _PickPanel({required this.onPick, this.notice});
  final ValueChanged<PhotoSource> onPick;
  final String? notice;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ScreenIntro(
          title: 'Snap a receipt.',
          body: 'Claude reads every line into fixed fields, so the app can add up your spending by category.',
        ),
        const Spacer(),
        if (notice != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Notice(notice!),
          ),
        FilledButton.icon(
          onPressed: () => onPick(PhotoSource.camera),
          icon: const Icon(Icons.photo_camera_outlined),
          label: const Text('Take a photo'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => onPick(PhotoSource.library),
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('Choose from library'),
        ),
        const SizedBox(height: 8),
      ],
    ),
  );
}
