import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient(this._tokenStorage)
    : dio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: ApiConfig.connectTimeout,
          receiveTimeout: ApiConfig.receiveTimeout,
          headers: const {'Accept': 'application/json'},
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) async {
          final t = await _tokenStorage.read();
          if (t != null) o.headers['Authorization'] = 'Bearer $t';
          h.next(o);
        },
      ),
    );
  }
  final TokenStorage _tokenStorage;
  final Dio dio;
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return (await dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
      )).data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<dynamic> post(String path, {Object? data}) async {
    try {
      return (await dio.post<dynamic>(path, data: data)).data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<dynamic> delete(String path) async {
    try {
      return (await dio.delete<dynamic>(path)).data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  ApiException _mapError(DioException e) {
    final d = e.response?.data;
    final detail = d is Map<String, dynamic> ? d['detail']?.toString() : null;
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout)
      return const ApiException('El servidor tardÃ³ demasiado en responder.');
    if (e.type == DioExceptionType.connectionError)
      return const ApiException('No fue posible conectar con SIDE B.');
    return ApiException(
      detail ?? 'OcurriÃ³ un error al consultar SIDE B.',
      statusCode: e.response?.statusCode,
    );
  }
}
