// FILE: features/conversation/presentation/widgets/photo_preview.dart
// The chosen photo at the top of Look, before the first question.

import 'package:flutter/material.dart';

import '../../../../core/theme/dimens.dart';
import '../../domain/entities/attachment.dart';

class PhotoPreview extends StatelessWidget {
  const PhotoPreview(this.photo, {super.key});
  final Attachment photo;

  static const _height = 260.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: kRadius,
        child: Image.memory(photo.bytes, height: _height, fit: BoxFit.cover),
      ),
    );
  }
}
