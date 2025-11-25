import 'package:isar/isar.dart';

part 'local_reminder.g.dart';

@collection
class ReminderLocal {
  Id id = Isar.autoIncrement;
  late String userId;
  late String title;
  int? index;
  String? time;
  DateTime? issuedDate;
  DateTime? expiryDate;
  DateTime? reminderDate;
  bool? isEnabled = true;
  bool? synced = false; // ✅ LOCAL ONLY
  bool? isUploaded = false; // ✅ Tracks if it exists on server
  late DateTime createdAt = DateTime.now();
  late DateTime? updatedAt;

  ReminderLocal({
    this.id = Isar.autoIncrement,
    required this.userId,
    required this.title,
    this.index,
    this.time,
    this.issuedDate,
    this.expiryDate,
    this.reminderDate,
    this.isEnabled = true,
    DateTime? updatedAt,
    this.synced = false,
    this.isUploaded = false,
  }) : updatedAt = updatedAt ?? DateTime.now();

  ReminderLocal copyWith({
    Id? id,
    String? userId,
    String? title,
    int? index,
    String? time,
    DateTime? issuedDate,
    DateTime? expiryDate,
    DateTime? reminderDate,
    bool? isEnabled,
    bool? synced,
    bool? isUploaded,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReminderLocal(
      id: this.id,
      userId: this.userId,
      title: title ?? this.title,
      index: index ?? this.index,
      time: time ?? this.time,
      issuedDate: issuedDate ?? this.issuedDate,
      expiryDate: expiryDate ?? this.expiryDate,
      reminderDate: reminderDate ?? this.reminderDate,
      isEnabled: isEnabled ?? this.isEnabled,
      synced: synced ?? this.synced,
      isUploaded: isUploaded ?? this.isUploaded,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
