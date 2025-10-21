// To parse this JSON data, do
//
//     final reminderDate = reminderDateFromJson(jsonString);

import 'dart:convert';

ReminderDate reminderDateFromJson(String str) =>
    ReminderDate.fromJson(json.decode(str));

String reminderDateToJson(ReminderDate data) => json.encode(data.toJson());

class ReminderDate {
  List<ReminderModel>? reminders;

  ReminderDate({this.reminders});

  factory ReminderDate.fromJson(Map<String, dynamic> json) => ReminderDate(
    reminders: json["reminders"] == null
        ? []
        : List<ReminderModel>.from(
            json["reminders"]!.map((x) => ReminderModel.fromJson(x)),
          ),
  );

  Map<String, dynamic> toJson() => {
    "reminders": reminders == null
        ? []
        : List<dynamic>.from(reminders!.map((x) => x.toJson())),
  };
}

class ReminderModel {
  String? id;
  String? uid;
  int? index;
  String? title;
  String? time;
  DateTime? expiryDate;
  DateTime? setDate;
  bool? isEnabled;
  String? user;
  DateTime? createdAt;
  DateTime? updatedAt;
  int? v;

  ReminderModel({
    this.id,
    this.uid,
    this.index,
    this.title,
    this.time,
    this.expiryDate,
    this.setDate,
    this.isEnabled,
    this.user,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json) => ReminderModel(
    // id: json["_id"],
    // uid: json["uid"],
    // index: json["index"],
    title: json["title"],
    time: json["time"],
    expiryDate: json["expiryDate"] == null
        ? null
        : DateTime.parse(json["expiryDate"]),
    // setDate: json["setDate"] == null ? null : DateTime.parse(json["setDate"]),
    // isEnabled: json["isEnabled"],
    // user: json["user"],
    // createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
    // updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
    // v: json["__v"],
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "uid": uid,
    "index": index,
    "title": title,
    "time": time,
    "expiryDate": expiryDate?.toIso8601String(),
    "setDate": setDate?.toIso8601String(),
    "isEnabled": isEnabled,
    "user": user,
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
    "__v": v,
  };
}
