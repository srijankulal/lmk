import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lmk/data/models/local/local_reminder.dart';

class IsarService {
  static Isar? _isar;

  Future<Isar> get db async {
    if (_isar != null) return _isar!;

    final dir = await getApplicationDocumentsDirectory();

    _isar = await Isar.open(
      [ReminderLocalSchema],
      inspector: true,
      directory: dir.path,
    );
    return _isar!;
  }

  Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
}
