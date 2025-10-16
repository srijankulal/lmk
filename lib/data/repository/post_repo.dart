import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:lmk/data/models/post/post.dart';
import 'package:lmk/data/repository/api/api.dart';

class PostRepository {
  Api api = Api();
  Future<void> fetchDocData(String imagePath) async {
    try {
      FormData formData = FormData.fromMap({
        'img': await MultipartFile.fromFile(imagePath),
      });

      Response response = await api.sendRequest.post(
        "/process",
        data: formData,
      );
      DocData docData = DocData.fromJson(response.data);

      debugPrint(docData.documentType.toString());
      debugPrint(docData.issueDate.toString());
      debugPrint(docData.expiryDate.toString());
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
