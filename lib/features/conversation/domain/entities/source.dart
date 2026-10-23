// FILE: features/conversation/domain/entities/source.dart
// A source Claude cited for a reply: a web page it found while searching, or the pages of the PDF
// it read. Shown under the reply so every claim can be checked.

import 'package:meta/meta.dart';

enum SourceKind { web, page }

@immutable
class Source {
  const Source.web({
    required this.title,
    required String this.url,
    required this.citedText,
  }) : kind = SourceKind.web,
       startPage = null,
       endPage = null;

  const Source.page({
    required this.title,
    required int this.startPage,
    required int this.endPage,
    required this.citedText,
  }) : kind = SourceKind.page,
       url = null;

  final SourceKind kind;
  final String title;

  /// The words Claude relied on, as they appear in the source.
  final String citedText;
  final String? url;
  final int? startPage;
  final int? endPage;

  /// "Page 3" or "Pages 3 to 5" for a PDF source.
  String get pages =>
      startPage == endPage ? 'Page $startPage' : 'Pages $startPage to $endPage';

  /// Two citations of the same page or the same quote count once in the list.
  String get key =>
      kind == SourceKind.web ? 'web|$url' : 'page|$startPage|$citedText';

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'title': title,
    'cited_text': citedText,
    'url': ?url,
    'start_page': ?startPage,
    'end_page': ?endPage,
  };

  /// Null for anything that is not a source this app understands.
  static Source? fromJson(Map<String, dynamic> json) {
    final title = json['title'] as String? ?? '';
    final cited = json['cited_text'] as String? ?? '';
    switch (json['kind']) {
      case 'web':
        final url = json['url'];
        return url is String
            ? Source.web(title: title, url: url, citedText: cited)
            : null;
      case 'page':
        final start = json['start_page'];
        final end = json['end_page'];
        return start is int && end is int
            ? Source.page(
                title: title,
                startPage: start,
                endPage: end,
                citedText: cited,
              )
            : null;
    }
    return null;
  }
}
