import 'package:isar/isar.dart';

part 'pending_deletion.g.dart';

@collection
class PendingDeletion {
  Id id = Isar.autoIncrement;

  late String remoteIndex; // The ID used for remote server deletion
  late DateTime deletedAt;
}
