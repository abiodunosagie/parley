import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parley/core/models/claude_model.dart';
import 'package:parley/core/network/cancel_token.dart';
import 'package:parley/core/storage/local_store.dart';
import 'package:parley/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:parley/features/auth/domain/entities/app_user.dart';
import 'package:parley/features/auth/presentation/providers/current_user_provider.dart';
import 'package:parley/features/receipt/data/repositories/receipt_repository_impl.dart';
import 'package:parley/features/receipt/domain/entities/receipt.dart';
import 'package:parley/features/receipt/domain/entities/scanned_receipt.dart';
import 'package:parley/features/receipt/domain/repositories/receipt_repository.dart';
import 'package:parley/features/receipt/presentation/providers/receipt_controller.dart';

import '../../../helpers/fakes.dart';

final _photo = (
  bytes: Uint8List.fromList([0xFF, 0xD8, 0xFF]),
  mediaType: 'image/jpeg',
);

const _receipt = Receipt(
  isReceipt: true,
  merchant: 'Cafe',
  date: '',
  currency: 'EUR',
  items: [],
  tax: 0,
  tip: 0,
  total: 3,
);

/// Each scan waits until the test completes it; cancelling throws like a real aborted request.
class _ManualScans implements ReceiptRepository {
  final pending = <Completer<ScanResult>>[];
  final saved = <String, ScannedReceipt>{};

  @override
  Future<ScanResult> scan({
    required ReceiptPhoto photo,
    required ClaudeModel model,
    CancelToken? cancel,
  }) {
    final c = Completer<ScanResult>();
    cancel?.whenCancelled.then((_) {
      if (!c.isCompleted) c.completeError(StateError('aborted'));
    });
    pending.add(c);
    return c.future;
  }

  @override
  Future<ReceiptPhoto?> pickPhoto(PhotoSource source) async => _photo;
  @override
  Future<List<SavedSummary>> history(String userId) async => const [];
  @override
  Future<ScannedReceipt?> load(String userId, String id) async => saved[id];
  @override
  Future<void> save(String userId, ScannedReceipt scan) async =>
      saved[scan.id] = scan;
  @override
  Future<void> delete(String userId, String id) async => saved.remove(id);
}

void main() {
  late _ManualScans scans;
  late ProviderContainer container;

  setUp(() async {
    scans = _ManualScans();
    container = ProviderContainer(
      overrides: [
        receiptRepositoryProvider.overrideWithValue(scans),
        localStoreProvider.overrideWithValue(MemoryStore()),
        authRepositoryProvider.overrideWithValue(
          FakeAuth(const AppUser(id: 'u1', email: 'a@b.c')),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(receiptControllerProvider, (_, _) {});
    // The app keeps the signed-in user alive (the router listens to it); so does the test.
    container.listen(currentUserIdProvider, (_, _) {});
    await pumpEventQueue();
  });

  ReceiptController controller() =>
      container.read(receiptControllerProvider.notifier);

  test('a scan is read and saved', () async {
    final scanning = controller().scan(_photo);
    await pumpEventQueue();
    scans.pending.single.complete(const Scanned(_receipt));
    await scanning;
    expect(container.read(receiptControllerProvider), isA<ReceiptRead>());
    expect(scans.saved, hasLength(1));
  });

  test(
    'New receipt during a scan stays empty when the old scan fails',
    () async {
      final scanning = controller().scan(_photo);
      await pumpEventQueue();
      controller().reset();
      await scanning;
      expect(container.read(receiptControllerProvider), isA<ReceiptEmpty>());
    },
  );

  test(
    'opening a saved receipt during a scan is not overwritten by it',
    () async {
      scans.saved['old'] = ScannedReceipt(
        id: 'old',
        photo: _photo.bytes,
        photoType: 'image/jpeg',
        receipt: _receipt,
        scannedAt: DateTime.utc(2026),
      );
      final scanning = controller().scan(_photo);
      await pumpEventQueue();
      await controller().open('old');
      await scanning;
      final state = container.read(receiptControllerProvider);
      expect(state, isA<ReceiptRead>());
      expect((state as ReceiptRead).scan.id, 'old');
    },
  );
}
