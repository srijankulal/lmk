import 'package:isar/isar.dart';

part 'local_user.g.dart';

@collection
class UserLocal {
  static const Id singletonId = 0;

  Id id = singletonId;
  String uid = '';
  String name = '';
  String photoUrl = '';
  bool guest = true;
}
