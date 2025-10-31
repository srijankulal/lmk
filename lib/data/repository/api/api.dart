import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class Api {
  Dio _dio = Dio();

  Api() {
    _dio.options.baseUrl = "https://lmk-api.vercel.app";
    // _dio.options.baseUrl = "https://78f016841f04.ngrok-free.app";
    _dio.interceptors.add(PrettyDioLogger());
  }

  Dio get sendRequest => _dio;
}
