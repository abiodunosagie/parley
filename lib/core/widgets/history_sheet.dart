// FILE: core/widgets/history_sheet.dart
// The history list every feature shares: tap an entry to open it again, swipe it away to delete
// it. Features pass their own list provider and what opening or deleting means for them.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

import '../models/saved_summary.dart';
import '../theme/parley_colors.dart';

/// Opens the history sheet for one feature.
Future<void> showHistorySheet(
  BuildContext context, {
  required ProviderListenable<AsyncValue<List<SavedSummary>>> entries,
  required ValueChanged<String> onOpen,
  required ValueChanged<String> onDelete,
  String empty = 'Nothing saved yet.',
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.6,
    maxChildSize: 0.92,
    builder: (context, scroll) => HistorySheet(
      entries: entries,
      scrollController: scroll,
      empty: empty,
      onOpen: (id) {
        Navigator.of(context).pop();
        onOpen(id);
      },
      onDelete: onDelete,
    ),
  ),
);

class HistorySheet extends ConsumerWidget {
  const HistorySheet({
    super.key,
    required this.entries,
    required this.onOpen,
    required this.onDelete,
    required this.empty,
    this.scrollController,
  });

  final ProviderListenable<AsyncValue<List<SavedSummary>>> entries;
  final ValueChanged<String> onOpen;
  final ValueChanged<String> onDelete;
  final String empty;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final list = ref.watch(entries);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text('History', style: Theme.of(context).textTheme.titleLarge),
        ),
        Expanded(
          child: switch (list) {
            AsyncData(:final value) when value.isEmpty => _Message(empty),
            AsyncData(:final value) => ListView.separated(
              controller: scrollController,
              itemCount: value.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: colors.line),
              itemBuilder: (context, i) {
                final entry = value[i];
                return Dismissible(
                  key: ValueKey(entry.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => onDelete(entry.id),
                  background: Container(
                    color: colors.danger,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: Text(
                      'Delete',
                      style: TextStyle(
                        color: colors.background,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  child: ListTile(
                    title: Text(
                      entry.title.isEmpty ? 'Untitled' : entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      [
                        whenLabel(entry.updatedAt),
                        if (entry.subtitle.isNotEmpty) entry.subtitle,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => onOpen(entry.id),
                  ),
                );
              },
            ),
            AsyncError() => const _Message('History could not be loaded.'),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Text(text, style: TextStyle(color: context.colors.muted)),
  );
}

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// "Today 14:05", "Yesterday", or "Mon 20 Oct", in the phone's time zone.
String whenLabel(DateTime when, {DateTime? now}) {
  final local = when.toLocal();
  final today = DateUtils.dateOnly(now ?? DateTime.now());
  final day = DateUtils.dateOnly(local);
  final daysAgo = today.difference(day).inDays;
  if (daysAgo == 0) {
    String two(int n) => n.toString().padLeft(2, '0');
    return 'Today ${two(local.hour)}:${two(local.minute)}';
  }
  if (daysAgo == 1) return 'Yesterday';
  final label =
      '${_weekdays[local.weekday - 1]} ${local.day} ${_months[local.month - 1]}';
  return local.year == today.year ? label : '$label ${local.year}';
}
