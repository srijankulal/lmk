import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class Api {
  Dio _dio = Dio();

  Api() {
    // _dio.options.baseUrl = "https://lmk-api.vercel.app";
    _dio.options.baseUrl = "https://d81b92c93140.ngrok-free.app";
    _dio.interceptors.add(PrettyDioLogger());
  }

  Dio get sendRequest => _dio;
}
