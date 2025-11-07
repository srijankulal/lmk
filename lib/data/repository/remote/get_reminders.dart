import 'package:dio/dio.dart';
import 'package:lmk/data/models/reminders.dart';
import 'package:lmk/data/repository/api/api.dart';

class GetReminders {
  Api api = Api();
  Future<ReminderDate> fetchReminders(String token, String uid) async {
    try {
      Response response = await api.sendRequest.get(
        '/user/$uid/getReminders',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        return ReminderDate.fromJson(response.data);
      } else {
        print(
          "Failed to fetch reminders (Status ${response.statusCode}): ${response.data['message']}",
        );
        throw Exception('Failed to fetch reminders');
      }
    } catch (e) {
      print("Error fetching reminders: $e");
      rethrow;
    }
  }
}
