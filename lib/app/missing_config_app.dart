// FILE: app/missing_config_app.dart
// Shown when the app was started without `--dart-define-from-file`, instead of a blank crash.

import 'package:flutter/material.dart';

class MissingConfigApp extends StatelessWidget {
  const MissingConfigApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Parley needs its config.\n\nRun:\nflutter run --dart-define-from-file=config/parley.json',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
