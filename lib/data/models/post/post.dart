// To parse this JSON data, do
//
//     final docData = docDataFromJson(jsonString);

import 'dart:convert';

DocData docDataFromJson(String str) => DocData.fromJson(json.decode(str));

// String docDataToJson(DocData data) => json.encode(data.toJson());

class DocData {
  String? documentType;
  DateTime? issueDate;
  DateTime? expiryDate;
  DateTime? reminderDate;

  DocData({
    this.documentType,
    this.issueDate,
    this.expiryDate,
    this.reminderDate,
  });

  factory DocData.fromJson(Map<String, dynamic> json) => DocData(
    documentType: json["document_type"],
    issueDate: json["issue_date"] == null
        ? null
        : DateTime.parse(json["issue_date"]),
    expiryDate: json["expiry_date"] == null
        ? null
        : DateTime.parse(json["expiry_date"]),
  );

  // Map<String, dynamic> toJson() => {
  //   "document_type": documentType,
  //   "issue_date":
  //       "${issueDate!.year.toString().padLeft(4, '0')}-${issueDate!.month.toString().padLeft(2, '0')}-${issueDate!.day.toString().padLeft(2, '0')}",
  //   "expiry_date":
  //       "${expiryDate!.year.toString().padLeft(4, '0')}-${expiryDate!.month.toString().padLeft(2, '0')}-${expiryDate!.day.toString().padLeft(2, '0')}",
  // };
}
