// FILE: features/tasks/data/repositories/reminder_repository_impl.dart
// The real ReminderRepository, backed by local notifications.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/reminder_repository.dart';
import '../datasources/notification_datasource.dart';

class ReminderRepositoryImpl implements ReminderRepository {
  ReminderRepositoryImpl(this._notifications);
  final NotificationDataSource _notifications;

  @override
  Future<bool> schedule({required String text, required int minutesFromNow}) =>
      _notifications.schedule(text: text, minutesFromNow: minutesFromNow);
}

final reminderRepositoryProvider = Provider<ReminderRepository>(
  (ref) => ReminderRepositoryImpl(NotificationDataSource()),
);
