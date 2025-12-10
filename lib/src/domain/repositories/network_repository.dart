import 'package:dio/dio.dart';

import '../../utils/exceptions.dart';

abstract class _NetworkRepository {
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  });

  Future<Map<String, dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  });

  Future<Map<String, dynamic>> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  });

  Future<Map<String, dynamic>> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  });

  Future<Map<String, dynamic>> patch(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  });
}

class NetworkRepository implements _NetworkRepository {
  final Dio _dio;

  static final NetworkRepository instance = NetworkRepository._internal();

  NetworkRepository._internal()
    : _dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ) {
    _dio.interceptors.addAll([_defaultInterceptor()]);
  }

  Interceptor _defaultInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        // Add Auth Token here if needed
        // options.headers['Authorization'] = 'Bearer $token';
        print('🌐 REQUEST[${options.method}] => PATH: ${options.path}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print(
          '✅ RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
        );
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        print(
          '❌ ERROR[${e.response?.statusCode}] => PATH: ${e.requestOptions.path}',
        );
        return handler.next(e);
      },
    );
  }

  // --- HELPER TO HANDLE ALL CASES ---

  /// Centralized request handler to wrap Dio calls and handle errors uniformly.
  Future<Map<String, dynamic>> _safeApiCall(
    Future<Response> Function() apiCall,
  ) async {
    try {
      final response = await apiCall();

      // If the response data is a Map, return it.
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      // If data is a List (common API pattern), wrap it in a Map.
      else if (response.data is List) {
        return {'data': response.data};
      }
      // Handle empty or primitive responses
      else {
        return {'data': response.data, 'message': 'Success'};
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(message: "Unexpected error occurred: $e");
    }
  }

  ApiException _handleDioError(DioException error) {
    String message = 'Unknown error occurred';
    int? statusCode = error.response?.statusCode;
    dynamic data = error.response?.data;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = "Connection timed out. Please check your internet.";
        break;
      case DioExceptionType.badResponse:
        // Try to extract error message from backend response if available
        if (data is Map && data.containsKey('message')) {
          message = data['message'];
        } else {
          message = "Received invalid status code: $statusCode";
        }
        break;
      case DioExceptionType.cancel:
        message = "Request to API was cancelled";
        break;
      case DioExceptionType.connectionError:
        message = "No internet connection";
        break;
      default:
        message = "Something went wrong";
        break;
    }

    return ApiException(message: message, statusCode: statusCode, data: data);
  }

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) {
    return _safeApiCall(
      () => _dio.getUri(
        Uri.parse(path),
        // queryParameters: queryParameters,
        options: Options(headers: headers),
      ),
    );
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) {
    return _safeApiCall(
      () => _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      ),
    );
  }

  @override
  Future<Map<String, dynamic>> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) {
    return _safeApiCall(
      () => _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      ),
    );
  }

  @override
  Future<Map<String, dynamic>> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) {
    return _safeApiCall(
      () => _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      ),
    );
  }

  @override
  Future<Map<String, dynamic>> patch(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) {
    return _safeApiCall(
      () => _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      ),
    );
  }
}
