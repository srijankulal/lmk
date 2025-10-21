import 'package:dio/dio.dart';
import 'package:lmk/data/models/reminders.dart';
import 'package:lmk/data/repository/api/api.dart';

class CreateReminderRepository {
  Api api = Api();

  Future<ReminderModel> createReminder({
    required String uid,
    required String title,
    required String time,
    required DateTime expiryDate,
    required DateTime setDate,
    required bool isEnabled,
    required int index,
    required String token,
  }) async {
    try {
      final response = await api.sendRequest.post(
        '/user/$uid/createReminder',
        data: {
          'uid': uid,
          'title': title,
          'time': time,
          'expiryDate': expiryDate.toIso8601String(),
          'setDate': setDate.toIso8601String(),
          'isEnabled': isEnabled,
          'index': index,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 201) {
        return ReminderModel.fromJson(response.data['reminder']);
      } else {
        throw Exception('Failed to create reminder');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception('Missing required fields');
      } else if (e.response?.statusCode == 404) {
        throw Exception('User not found');
      } else {
        throw Exception('Server error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}
