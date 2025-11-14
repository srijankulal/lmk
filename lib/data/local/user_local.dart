import 'package:lmk/data/models/local/local_user.dart';
import 'package:lmk/data/repository/local/isar_service.dart';
import 'package:lmk/data/models/local/local_user.dart' as model;


class UserLocalDataSource {
  final IsarService _isarService = IsarService();

  /// Returns the saved user or null if none.
  /// Usage:
  /// final user = await UserLocalDataSource().getUser();
  /// if (user != null) { /* handle user */ }
  Future<model.UserLocal?> getUser() async {
    final isar = await _isarService.db;
    return isar.userLocals.get(UserLocal.singletonId);
  }

  Future<void> saveUser(model.UserLocal user) async {
    final isar = await _isarService.db;
    return isar.writeTxn(
      () => isar.userLocals.put(user..id = UserLocal.singletonId),
    );
  }

  Future<void> clearUser() async {
    final isar = await _isarService.db;
    return isar.writeTxn(() => isar.userLocals.delete(UserLocal.singletonId));
  }
}
