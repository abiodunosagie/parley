// FILE: features/receipt/domain/repositories/receipt_repository.dart
// Reads a receipt photo with Claude, and keeps the receipts you scanned.
// Implemented in data/repositories/receipt_repository_impl.dart.

import 'dart:typed_data';

import '../../../../core/media/photo_source.dart';
import '../../../../core/models/claude_model.dart';
import '../../../../core/models/saved_summary.dart';
import '../../../../core/network/cancel_token.dart';
import '../entities/receipt.dart';
import '../entities/scanned_receipt.dart';

export '../../../../core/media/photo_source.dart';

typedef ReceiptPhoto = ({Uint8List bytes, String mediaType});

/// How a scan ended: the receipt, or why there is none.
sealed class ScanResult {
  const ScanResult();
}

class Scanned extends ScanResult {
  const Scanned(this.receipt);
  final Receipt receipt;
}

class NotScanned extends ScanResult {
  const NotScanned(this.stopReason);
  final String? stopReason;
}

abstract interface class ReceiptRepository {
  /// The chosen photo, or null when you cancelled. Throws AppException when access is denied.
  Future<ReceiptPhoto?> pickPhoto(PhotoSource source);

  /// Throws AppException when the request fails.
  Future<ScanResult> scan({
    required ReceiptPhoto photo,
    required ClaudeModel model,
    CancelToken? cancel,
  });

  Future<List<SavedSummary>> history(String userId);
  Future<ScannedReceipt?> load(String userId, String id);
  Future<void> save(String userId, ScannedReceipt scan);
  Future<void> delete(String userId, String id);
}
