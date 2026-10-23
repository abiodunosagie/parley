// FILE: features/receipt/domain/entities/scanned_receipt.dart
// A receipt you scanned, as saved in history: the photo and what Claude read from it.

import 'dart:typed_data';

import 'package:meta/meta.dart';

import 'receipt.dart';

@immutable
class ScannedReceipt {
  const ScannedReceipt({
    required this.id,
    required this.photo,
    required this.photoType,
    required this.receipt,
    required this.scannedAt,
  });

  final String id;
  final Uint8List photo;
  final String photoType;
  final Receipt receipt;
  final DateTime scannedAt;
}
