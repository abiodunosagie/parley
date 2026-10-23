// FILE: features/receipt/presentation/providers/receipt_controller.dart
// RECEIPT LOGIC: vision plus structured output. Take or pick a photo and it is read straight
// away into a Receipt with fixed fields, then saved to history. The screen shows one of five
// explicit states: empty, scanning, read, or failed (with the photo, to try again).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_log.dart';
import '../../../../core/errors/user_messages.dart';
import '../../../../core/network/cancel_token.dart';
import '../../../../core/state/selected_model_provider.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../data/repositories/receipt_repository_impl.dart';
import '../../domain/entities/scanned_receipt.dart';
import '../../domain/repositories/receipt_repository.dart';
import 'receipt_history_provider.dart';

sealed class ReceiptState {
  const ReceiptState();
}

/// No photo yet. [notice] says why the last photo could not be used, if it could not.
class ReceiptEmpty extends ReceiptState {
  const ReceiptEmpty([this.notice]);
  final String? notice;
}

class ReceiptScanning extends ReceiptState {
  const ReceiptScanning(this.photo);
  final ReceiptPhoto photo;
}

class ReceiptRead extends ReceiptState {
  const ReceiptRead(this.scan);
  final ScannedReceipt scan;
}

class ReceiptFailed extends ReceiptState {
  const ReceiptFailed(this.photo, this.message);
  final ReceiptPhoto photo;
  final String message;
}

class ReceiptController extends Notifier<ReceiptState> {
  static const _uuid = Uuid();
  CancelToken? _cancel;

  @override
  ReceiptState build() {
    ref.onDispose(() => _cancel?.cancel());
    return const ReceiptEmpty();
  }

  String? get _userId => ref.read(currentUserProvider).value?.id;

  void reset() {
    _cancel?.cancel();
    state = const ReceiptEmpty();
  }

  void cancel() => _cancel?.cancel();

  Future<void> pickPhoto(PhotoSource source) async {
    try {
      final photo = await ref.read(receiptRepositoryProvider).pickPhoto(source);
      if (photo == null || !ref.mounted) return;
      await scan(photo);
    } on AppException catch (e) {
      if (ref.mounted) state = ReceiptEmpty(e.message);
    }
  }

  Future<void> scan(ReceiptPhoto photo) async {
    if (state is ReceiptScanning) return;
    state = ReceiptScanning(photo);
    final cancel = _cancel = CancelToken();
    try {
      final result = await ref
          .read(receiptRepositoryProvider)
          .scan(
            photo: photo,
            model: ref.read(selectedModelProvider),
            cancel: cancel,
          );
      if (!ref.mounted || !identical(_cancel, cancel)) return;
      switch (result) {
        case Scanned(:final receipt) when receipt.isReceipt:
          final scan = ScannedReceipt(
            id: _uuid.v4(),
            photo: photo.bytes,
            photoType: photo.mediaType,
            receipt: receipt,
            scannedAt: DateTime.now(),
          );
          state = ReceiptRead(scan);
          await _save(scan);
        case Scanned():
          state = ReceiptFailed(
            photo,
            'That does not look like a receipt. Try another photo.',
          );
        case NotScanned(:final stopReason):
          state = ReceiptFailed(
            photo,
            stopReasonNote(stopReason) ??
                'The receipt could not be read. Try again.',
          );
      }
    } catch (e) {
      if (ref.mounted && identical(_cancel, cancel)) {
        state = ReceiptFailed(
          photo,
          reportError(e, cancelled: cancel.isCancelled, tag: 'receipt'),
        );
      }
    }
  }

  Future<void> open(String id) async {
    final userId = _userId;
    if (userId == null) return;
    final saved = await ref.read(receiptRepositoryProvider).load(userId, id);
    if (!ref.mounted) return;
    _cancel?.cancel();
    state = saved == null
        ? const ReceiptEmpty('That receipt could not be opened.')
        : ReceiptRead(saved);
  }

  Future<void> deleteSaved(String id) async {
    final userId = _userId;
    if (userId == null) return;
    await ref.read(receiptRepositoryProvider).delete(userId, id);
    if (!ref.mounted) return;
    ref.invalidate(receiptHistoryProvider);
    if (state case ReceiptRead(:final scan) when scan.id == id) reset();
  }

  Future<void> _save(ScannedReceipt scan) async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await ref.read(receiptRepositoryProvider).save(userId, scan);
      if (ref.mounted) ref.invalidate(receiptHistoryProvider);
    } catch (e) {
      reportError(e, cancelled: false, tag: 'history');
    }
  }
}

final receiptControllerProvider =
    NotifierProvider<ReceiptController, ReceiptState>(ReceiptController.new);
