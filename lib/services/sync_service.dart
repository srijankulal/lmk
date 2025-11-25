import 'package:isar/isar.dart';
import 'package:lmk/data/local/reminder_local.dart';
import 'package:lmk/data/models/local/local_reminder.dart';
import 'package:lmk/data/models/local/pending_deletion.dart';
import 'package:lmk/data/repository/local/isar_service.dart';
import 'package:lmk/data/repository/remote/delete_reminder.dart';
import 'package:lmk/data/repository/remote/create_reminder.dart';
import 'package:lmk/data/repository/remote/update_reminder.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SyncService {
  // Singleton: Ensure only one instance of the service exists
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  // Lock to prevent concurrent syncs
  bool _isSyncing = false;

  Future<void> syncAll() async {
    // 1. If already syncing, stop here to prevent duplicates
    if (_isSyncing) {
      print("⚠️ Sync already in progress. Skipping.");
      return;
    }

    _isSyncing = true;

    try {
      final isar = await IsarService().db;
      final user = FirebaseAuth.instance.currentUser;
      final token = user != null ? await user.getIdToken() : null;

      if (token == null) {
        print("❌ No user token available for sync.");
        return;
      }

      // --- STEP 1: Sync Pending Creations & Updates ---
      final unsyncedReminders = await isar.reminderLocals
          .filter()
          .syncedEqualTo(false)
          .findAll();

      if (unsyncedReminders.isNotEmpty) {
        print("Syncing ${unsyncedReminders.length} pending items...");

        for (final reminder in unsyncedReminders) {
          try {
            if (reminder.isUploaded == false) {
              // CREATE: Not uploaded yet
              await CreateReminderRepository().createReminder(
                uid: reminder.userId,
                title: reminder.title,
                time: reminder.time!,
                expiryDate: reminder.expiryDate!,
                setDate: reminder.updatedAt!,
                isEnabled: reminder.isEnabled!,
                index: reminder.index!,
                token: token,
                issuedDate: reminder.issuedDate!,
              );

              await isar.writeTxn(() async {
                final freshReminder = await isar.reminderLocals.get(
                  reminder.id,
                );
                if (freshReminder != null) {
                  freshReminder.synced = true;
                  freshReminder.isUploaded = true; // ✅ Mark as uploaded
                  await isar.reminderLocals.put(freshReminder);
                }
              });
              print("✅ Synced creation: ${reminder.title}");
            } else {
              // UPDATE: Already uploaded, so update
              await UpdateReminder().updateReminder(
                index: reminder.index!,
                title: reminder.title,
                time: reminder.time,
                expiryDate: reminder.expiryDate,
                setDate: reminder.updatedAt,
                isEnabled: reminder.isEnabled,
                issuedDate: reminder.issuedDate,
              );

              await isar.writeTxn(() async {
                final freshReminder = await isar.reminderLocals.get(
                  reminder.id,
                );
                if (freshReminder != null) {
                  freshReminder.synced = true;
                  await isar.reminderLocals.put(freshReminder);
                }
              });
              print("✅ Synced update: ${reminder.title}");
            }
          } catch (e) {
            print("❌ Failed to sync item ${reminder.title}: $e");
          }
        }
      }

      // --- STEP 2: Sync Pending Deletions ---
      final pendingDeletions = await isar.pendingDeletions.where().findAll();

      if (pendingDeletions.isNotEmpty) {
        print("Syncing ${pendingDeletions.length} pending deletions...");

        for (final item in pendingDeletions) {
          try {
            // Call remote delete API
            await DeleteReminder().deleteReminder(item.remoteIndex);

            // Remove from pending queue after success
            await isar.writeTxn(() async {
              await isar.pendingDeletions.delete(item.id);
            });
            print("✅ Synced deletion for index: ${item.remoteIndex}");
          } catch (e) {
            print("❌ Failed to sync deletion: $e");
          }
        }
      }
    } catch (e) {
      print("Error during sync: $e");
    } finally {
      // 2. Release the lock so future syncs can run
      _isSyncing = false;
    }
  }
}
