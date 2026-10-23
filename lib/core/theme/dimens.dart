// FILE: core/theme/dimens.dart
// Shared sizes. One corner radius for every box, button and bubble: rounded, never a pill.

import 'package:flutter/painting.dart';

const kCornerRadius = Radius.circular(12);
const kRadius = BorderRadius.all(kCornerRadius);

/// Full-width buttons on mobile, tall enough for a comfortable tap.
const kButtonHeight = 52.0;
