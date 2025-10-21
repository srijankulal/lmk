

import 'package:dio/dio.dart';
import 'package:lmk/data/repository/api/api.dart';

class UserRegister {
  Api api = Api();
  Future<void> registerUser(
    String token,
    Map<String, dynamic> userDetails,
  ) async {
    try {
      // The backend expects uid, name, email, profileUrl in userDetails
      Response response = await api.sendRequest.post(
        '/user/register',
        data: userDetails, // Dio automatically handles JSON encoding for maps
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          // The backend might return 400, 409, 500, etc. on failure
          // We handle these explicitly, so don't throw an exception for them.
          validateStatus: (status) {
            return status != null && status < 500;
          },
        ),
      );

      // Backend returns 201 on successful creation
      if (response.statusCode == 201) {
        print("User registered successfully: ${response.data['message']}");
      } else {
        // Handle other status codes like 400 (Bad Request) or 409 (Conflict)
        print(
          "Failed to register user (Status ${response.statusCode}): ${response.data['message']}",
        );
      }
    } on DioException catch (e) {
      // Handle Dio-specific errors (e.g., network issues, server 5xx errors)
      if (e.response != null) {
        print("Error calling backend API: ${e.response?.data}");
      } else {
        print("Error calling backend API: ${e.message}");
      }
    } catch (e) {
      print("An unexpected error occurred: $e");
    }
  }
}
