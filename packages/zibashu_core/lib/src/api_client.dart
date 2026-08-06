import 'package:dio/dio.dart';

import 'api_config.dart';
import 'result.dart';

/// Thin Dio wrapper. Attach Sanctum bearer tokens via [authToken].
class ApiClient {
  ApiClient(this.config, {String? authToken})
      : _dio = Dio(
          BaseOptions(
            baseUrl: config.baseUrl,
            connectTimeout: config.connectTimeout,
            receiveTimeout: config.receiveTimeout,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              if (authToken != null && authToken.isNotEmpty)
                'Authorization': 'Bearer $authToken',
            },
          ),
        );

  final ApiConfig config;
  final Dio _dio;

  Dio get dio => _dio;

  void setAuthToken(String? token) {
    if (token == null || token.isEmpty) {
      _dio.options.headers.remove('Authorization');
    } else {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<Result<Response<dynamic>>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    return _guard(() => _dio.get<dynamic>(path, queryParameters: query));
  }

  Future<Result<Response<dynamic>>> post(
    String path, {
    Object? data,
  }) async {
    return _guard(() => _dio.post<dynamic>(path, data: data));
  }

  Future<Result<Response<dynamic>>> _guard(
    Future<Response<dynamic>> Function() run,
  ) async {
    try {
      final response = await run();
      return Ok(response);
    } on DioException catch (e) {
      return Err(e);
    } catch (e) {
      return Err(e);
    }
  }
}
