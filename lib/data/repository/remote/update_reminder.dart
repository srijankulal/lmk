import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lmk/data/repository/api/api.dart';

class UpdateReminder {
  Api api = Api();

  Future<String> updateReminder({
    String? title,
    String? time,
    DateTime? expiryDate,
    DateTime? setDate,
    bool? isEnabled,
    required int index,
    DateTime? issuedDate,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return "Updated locally";
    }
    final token = await user.getIdToken();
    String uid = user.uid;
    print("Updating reminder with index: $index");
    print(uid);
    Response response = await api.sendRequest.patch(
      '/user/$uid/editReminder',

      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
      data: {
        'uid': uid,
        if (title != null) 'title': title,
        if (time != null) 'time': time,
        if (expiryDate != null) 'expiryDate': expiryDate.toIso8601String(),
        if (setDate != null) 'setDate': setDate.toIso8601String(),
        if (isEnabled != null) 'isEnabled': isEnabled,
        'index': index,
        if (issuedDate != null) 'issuedDate': issuedDate.toIso8601String(),
      },
    );
    if (response.statusCode != 200) {
      print(
        "Failed to update reminder (Status ${response.statusCode}): ${response.data['message']}",
      );
      return "Failed to Update";
    } else {
      return "Updated Successfully";
    }
  }
}
