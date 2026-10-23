// FILE: features/receipt/data/repositories/receipt_repository_impl.dart
// The real ReceiptRepository. The server adds the JSON schema (RECEIPT_SCHEMA in
// supabase/functions/claude/schemas.ts), so the answer always has exactly the receipt fields.
// Scans are saved on the phone under the "receipts" collection, the photo as its own file.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/media/photo_picker.dart';
import '../../../../core/models/claude_model.dart';
import '../../../../core/network/cancel_token.dart';
import '../../../../core/network/claude_client.dart';
import '../../../../core/storage/local_store.dart';
import '../../../../core/storage/saved_collection.dart';
import '../../domain/entities/receipt.dart';
import '../../domain/entities/scanned_receipt.dart';
import '../../domain/repositories/receipt_repository.dart';

class ReceiptRepositoryImpl implements ReceiptRepository {
  ReceiptRepositoryImpl(this._client, this._picker, LocalStore store)
    : _saved = SavedCollection(store, 'receipts');
  final ClaudeClient _client;
  final PhotoPicker _picker;
  final SavedCollection _saved;

  static const _photo = 'photo';

  @override
  Future<ReceiptPhoto?> pickPhoto(PhotoSource source) => _picker.pick(source);

  @override
  Future<ScanResult> scan({
    required ReceiptPhoto photo,
    required ClaudeModel model,
    CancelToken? cancel,
  }) async {
    final json = await _client.request(
      mode: ClaudeMode.receipt,
      model: model,
      messages: [
        {
          'role': 'user',
          'content': [
            {
              'type': 'image',
              'source': {
                'type': 'base64',
                'media_type': photo.mediaType,
                'data': base64Encode(photo.bytes),
              },
            },
            {'type': 'text', 'text': 'Read this receipt.'},
          ],
        },
      ],
      cancel: cancel,
    );
    final fields = json['fields'];
    return fields is Map<String, dynamic>
        ? Scanned(Receipt.fromJson(fields))
        : NotScanned(json['stop_reason'] as String?);
  }

  @override
  Future<List<SavedSummary>> history(String userId) => _saved.history(userId);

  @override
  Future<ScannedReceipt?> load(String userId, String id) =>
      _saved.load(userId, id, (json) async {
        final photo = await _saved.file(userId, id, _photo);
        if (photo == null) return null;
        return ScannedReceipt(
          id: id,
          photo: photo,
          photoType: json['photo_type'] as String,
          receipt: Receipt.fromJson(json['receipt'] as Map<String, dynamic>),
          scannedAt: DateTime.parse(json['scanned_at'] as String),
        );
      });

  @override
  Future<void> save(String userId, ScannedReceipt scan) {
    final r = scan.receipt;
    return _saved.save(
      userId,
      SavedSummary(
        id: scan.id,
        title: r.merchant.isEmpty ? 'Receipt' : r.merchant,
        subtitle:
            '${r.currency} ${r.total.toStringAsFixed(2)} · ${r.items.length} items',
        updatedAt: scan.scannedAt,
      ),
      {
        'version': 1,
        'photo_type': scan.photoType,
        'scanned_at': scan.scannedAt.toIso8601String(),
        'receipt': r.toJson(),
      },
      file: (name: _photo, bytes: scan.photo),
    );
  }

  @override
  Future<void> delete(String userId, String id) => _saved.delete(userId, id);
}

final receiptRepositoryProvider = Provider<ReceiptRepository>(
  (ref) => ReceiptRepositoryImpl(
    ref.watch(claudeClientProvider),
    ref.watch(photoPickerProvider),
    ref.watch(localStoreProvider),
  ),
);
