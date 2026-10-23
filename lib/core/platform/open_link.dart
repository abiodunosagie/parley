// FILE: core/platform/open_link.dart
// Opens a web link in the phone's browser. Only http and https links: a cited source can never
// open an app scheme or a file.

import 'package:url_launcher/url_launcher.dart';

/// Returns false when the link was not opened.
Future<bool> openLink(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
    return false;
  }
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
