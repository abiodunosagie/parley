// FILE: features/conversation/presentation/widgets/source_list.dart
// The sources under a reply. Web pages show their title and site and open in the browser; PDF
// sources show the page and the exact words Claude relied on.

import 'package:flutter/material.dart';

import '../../../../core/platform/open_link.dart';
import '../../../../core/theme/dimens.dart';
import '../../../../core/theme/parley_colors.dart';
import '../../domain/entities/source.dart';

class SourceList extends StatelessWidget {
  const SourceList(this.sources, {super.key});
  final List<Source> sources;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sources',
            style: TextStyle(
              color: colors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          for (final (i, source) in sources.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _SourceTile(number: i + 1, source: source),
            ),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({required this.number, required this.source});
  final int number;
  final Source source;

  Future<void> _open(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!await openLink(url)) {
      messenger.showSnackBar(
        const SnackBar(content: Text('That link could not be opened.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final url = source.url;
    final host = url == null ? null : Uri.tryParse(url)?.host;
    return Material(
      color: colors.code,
      borderRadius: kRadius,
      child: InkWell(
        borderRadius: kRadius,
        onTap: url == null ? null : () => _open(context, url),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$number',
                style: TextStyle(
                  color: colors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source.kind == SourceKind.web
                          ? source.title
                          : source.pages,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      host ?? '"${source.citedText.trim()}"',
                      maxLines: host == null ? 4 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (url != null)
                Icon(Icons.open_in_new, size: 16, color: colors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
