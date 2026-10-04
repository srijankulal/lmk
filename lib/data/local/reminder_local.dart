import 'package:lmk/data/repository/local/isar_service.dart';
import 'package:lmk/data/models/local/local_reminder.dart' as model;
import 'package:isar/isar.dart';

class ReminderLocalDataSource {
  final IsarService _isarService = IsarService();

  // Add a new reminder
  Future<void> addReminder(model.ReminderLocal reminder) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async => await isar.reminderLocals.put(reminder));
  }

  // Get all reminders for a user
  Future<List<model.ReminderLocal>> getReminders(String userId) async {
    final isar = await _isarService.db;
    return await isar.reminderLocals.filter().userIdEqualTo(userId).findAll();
  }

  // Get reminder by unique index
  Future<model.ReminderLocal?> getReminderByIndex(int index) async {
    final isar = await _isarService.db;
    return await isar.reminderLocals.filter().indexEqualTo(index).findFirst();
  }

  // Get reminder by Isar auto-increment ID
  Future<model.ReminderLocal?> getReminderById(int id) async {
    final isar = await _isarService.db;
    return await isar.reminderLocals.get(id);
  }

  // Update a reminder
  Future<void> updateReminder(model.ReminderLocal reminder) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async => await isar.reminderLocals.put(reminder));
  }

  // Delete a reminder
  Future<bool> deleteReminder(int id) async {
    final isar = await _isarService.db;
    final deleted = await isar.writeTxn<bool>(() async {
      return await isar.reminderLocals.delete(id);
    });
    return deleted;
  }

  // Get unsynced reminders (for backend upload)
  Future<List<model.ReminderLocal>> getUnsynced() async {
    final isar = await _isarService.db;
    return await isar.reminderLocals.filter().syncedEqualTo(false).findAll();
  }

  // Watch for any changes to reminders in real-time
  Stream<void> watchReminders() async* {
    final isar = await _isarService.db;
    yield* isar.reminderLocals.watchLazy();
  }
}
