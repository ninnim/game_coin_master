import 'package:dio/dio.dart';
import '../config.dart';
import '../storage/secure_storage.dart';
import 'api_exception.dart';

class ApiClient {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          final statusCode = error.response?.statusCode ?? 500;
          final message =
              error.response?.data?['error'] ??
              error.message ??
              'Unknown error';
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              error: ApiException(message.toString(), statusCode),
              response: error.response,
              type: error.type,
            ),
          );
        },
      ),
    );

  static Future<T> get<T>(
    String path, {
    Map<String, dynamic>? params,
  }) async {
    final resp = await _dio.get(path, queryParameters: params);
    return resp.data as T;
  }

  static Future<T> post<T>(String path, {dynamic data}) async {
    final resp = await _dio.post(path, data: data);
    return resp.data as T;
  }

  static Future<T> put<T>(String path, {dynamic data}) async {
    final resp = await _dio.put(path, data: data);
    return resp.data as T;
  }

  static Future<void> delete(String path) async {
    await _dio.delete(path);
  }
}
