// FILE: features/receipt/presentation/providers/receipt_controller.dart
// RECEIPT LOGIC: vision plus structured output. Take or pick a photo and it is read straight
// away into a Receipt with fixed fields, then saved to history. The screen shows one of four
// explicit states: empty, scanning, read, or failed (with the photo, to try again).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;
import 'package:uuid/uuid.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_log.dart';
import '../../../../core/errors/user_messages.dart';
import '../../../../core/network/cancel_token.dart';
import '../../../../core/state/saved_history.dart';
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

class ReceiptController extends Notifier<ReceiptState>
    with SavedHistory<ReceiptState> {
  static const _uuid = Uuid();

  /// The scan that owns the state. Anything that replaces the screen drops it, so a scan still
  /// finishing can never overwrite what you opened since.
  CancelToken? _current;

  @override
  ReceiptState build() {
    ref.onDispose(() => _current?.cancel());
    return const ReceiptEmpty();
  }

  @override
  String? get historyUserId => ref.read(currentUserIdProvider);

  @override
  ProviderOrFamily get historyList => receiptHistoryProvider;

  void _abandon() {
    _current?.cancel();
    _current = null;
  }

  void reset() {
    _abandon();
    state = const ReceiptEmpty();
  }

  void cancel() => _current?.cancel();

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
    final cancel = _current = CancelToken();
    bool stillMine() => ref.mounted && identical(_current, cancel);
    try {
      final result = await ref
          .read(receiptRepositoryProvider)
          .scan(
            photo: photo,
            model: ref.read(selectedModelProvider),
            cancel: cancel,
          );
      if (!stillMine()) return;
      _current = null;
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
          await changeSaved(
            (userId) => ref.read(receiptRepositoryProvider).save(userId, scan),
          );
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
      if (!stillMine()) return;
      _current = null;
      state = ReceiptFailed(
        photo,
        reportError(e, cancelled: cancel.isCancelled, tag: 'receipt'),
      );
    }
  }

  Future<void> open(String id) async {
    final saved = await loadSaved(
      (userId) => ref.read(receiptRepositoryProvider).load(userId, id),
    );
    if (!ref.mounted) return;
    _abandon();
    state = saved == null
        ? const ReceiptEmpty('That receipt could not be opened.')
        : ReceiptRead(saved);
  }

  Future<void> deleteSaved(String id) async {
    final deleted = await changeSaved(
      (userId) => ref.read(receiptRepositoryProvider).delete(userId, id),
    );
    if (!ref.mounted) return;
    if (state case ReceiptRead(:final scan) when scan.id == id) {
      reset();
    } else if (!deleted && state is ReceiptEmpty) {
      state = const ReceiptEmpty('That receipt could not be deleted.');
    }
  }
}

final receiptControllerProvider =
    NotifierProvider<ReceiptController, ReceiptState>(ReceiptController.new);
