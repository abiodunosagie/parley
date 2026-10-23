// FILE: features/tasks/domain/repositories/reminder_repository.dart
// Local reminders for the set_reminder tool. Implemented with local notifications in
// data/repositories/reminder_repository_impl.dart.

abstract interface class ReminderRepository {
  /// Asks for permission the first time, then schedules. Returns false when the user said no.
  Future<bool> schedule({required String text, required int minutesFromNow});
}
