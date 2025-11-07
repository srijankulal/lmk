import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lmk/data/repository/api/api.dart';

class DeleteReminder {
  Api api = Api();
  Future<String> deleteReminder(String reminderId) async {
    try {
      final token = await FirebaseAuth.instance.currentUser!.getIdToken();
      String uid = FirebaseAuth.instance.currentUser!.uid;
      Response response = await api.sendRequest.delete(
        '/user/$uid/deleteReminder',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
        data: {'index': reminderId},
      );

      if (response.statusCode == 200) {
        return "Deleted Successfully";
      } else {
        print(
          "Failed to delete reminder (Status ${response.statusCode}): ${response.data['message']}",
        );
        throw Exception('Failed to delete reminder');
      }
    } catch (e) {
      print("Error fetching reminders: $e");
      rethrow;
    }
  }
}
