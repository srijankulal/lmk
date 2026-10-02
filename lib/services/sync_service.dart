import 'package:isar/isar.dart';
import 'package:lmk/data/models/local/local_reminder.dart';
import 'package:lmk/data/models/local/pending_deletion.dart';
import 'package:lmk/data/repository/local/isar_service.dart';
import 'package:lmk/data/repository/remote/delete_reminder.dart';
import 'package:lmk/data/repository/remote/create_reminder.dart';
import 'package:lmk/data/repository/remote/update_reminder.dart';
import 'package:lmk/data/repository/remote/get_reminders.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SyncService {
  // Singleton: Ensure only one instance of the service exists
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  // Lock to prevent concurrent syncs
  bool _isSyncing = false;

  Future<void> syncDown() async {
    if (_isSyncing) {
      print("⚠️ Sync already in progress. Skipping syncDown.");
      return;
    }
    _isSyncing = true;

    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = user != null ? await user.getIdToken() : null;

      if (user == null || token == null) {
        print("❌ No user/token available for syncDown.");
        return;
      }

      print("📥 Fetching reminders from cloud...");
      final reminderDate = await GetReminders().fetchReminders(token, user.uid);
      final remoteReminders = reminderDate.reminders ?? [];

      if (remoteReminders.isEmpty) {
        print("☁️ No reminders found on cloud.");
        return;
      }

      final isar = await IsarService().db;

      await isar.writeTxn(() async {
        for (final remote in remoteReminders) {
          // Check if exists locally by index (assuming index is unique per user)
          // Or we can just overwrite/insert.
          // Since we don't have a stable remoteId anymore, we rely on 'index'.

          final existing = await isar.reminderLocals
              .filter()
              .userIdEqualTo(user.uid)
              .indexEqualTo(remote.index)
              .findFirst();

          if (existing == null) {
            // Insert new
            final newLocal = ReminderLocal(
              userId: user.uid,
              title: remote.title ?? "Untitled",
              index: remote.index,
              time: remote.time,
              issuedDate: remote.issuedDate,
              expiryDate: remote.expiryDate,
              reminderDate: remote.reminderDate,
              isEnabled: remote.isEnabled ?? true,
              synced: true,
              isUploaded: true,
              updatedAt: remote.updatedAt,
            );
            await isar.reminderLocals.put(newLocal);
            print("📥 Imported: ${newLocal.title}");
          } else {
            // Update existing if remote is newer?
            // For now, let's assume remote is master during syncDown (e.g. new device)
            // But be careful not to overwrite unsynced local changes if any.
            if (existing.synced == true) {
              existing.title = remote.title ?? existing.title;
              existing.time = remote.time ?? existing.time;
              existing.expiryDate = remote.expiryDate ?? existing.expiryDate;
              existing.reminderDate =
                  remote.reminderDate ?? existing.reminderDate;
              existing.isEnabled = remote.isEnabled ?? existing.isEnabled;
              existing.updatedAt = remote.updatedAt ?? DateTime.now();
              existing.synced = true;
              existing.isUploaded = true;
              await isar.reminderLocals.put(existing);
              print("🔄 Updated local: ${existing.title}");
            }
          }
        }
      });
      print("✅ SyncDown complete. Processed ${remoteReminders.length} items.");
    } catch (e) {
      print("❌ Error during syncDown: $e");
    } finally {
      _isSyncing = false;
    }
  }

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
