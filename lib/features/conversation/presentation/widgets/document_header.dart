// FILE: features/conversation/presentation/widgets/document_header.dart
// The opened PDF at the top of Read, before the first question: its name and size.

import 'package:flutter/material.dart';

import '../../../../core/theme/dimens.dart';
import '../../../../core/theme/parley_colors.dart';
import '../../domain/entities/attachment.dart';

class DocumentHeader extends StatelessWidget {
  const DocumentHeader(this.document, {super.key});
  final Attachment document;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final kb = (document.bytes.length / 1000).round();
    final size = kb < 1000 ? '$kb KB' : '${(kb / 1000).toStringAsFixed(1)} MB';
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.accentSoft,
        borderRadius: kRadius,
      ),
      child: Row(
        children: [
          Icon(Icons.picture_as_pdf_outlined, color: colors.accent, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.name ?? 'Document',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(size, style: TextStyle(color: colors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
