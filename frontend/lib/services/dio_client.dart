import 'package:dio/dio.dart';

/* 
NEGATIVE ERROR CODES 
  -1: Response received but no status code
  -2: DioException (network error, timeout, etc.)
  -3: Unexpected exception
*/

final dio = Dio(BaseOptions(
  baseUrl: 'http://localhost:3000',
  connectTimeout: Duration(seconds: 10),
  receiveTimeout: Duration(seconds: 5),
  headers: {'Content-Type': 'application/json'}
));

// dio response object
class ApiResponse<T> {
  final int code;
  final T? data;
  final String? message;

  ApiResponse({
    required this.code, 
    this.data,
    this.message
  });

  // for logging whats been received from the server
  @override
  String toString() => 'ApiResponse(code: $code, data: $data, message: $message)';
}

extension DioApiExtension on Dio {
  Future<ApiResponse<T>> sendRequest<T>(
    String method, 
    String path,
    {
      dynamic data,
      Map<String, dynamic>? queryParameters,
      T Function(dynamic json)? fromJson,
    }
  ) async {
    try {
      final response = await request(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(method: method)
      );

      return ApiResponse<T>(
        code: response.statusCode ?? -1,
        data: fromJson != null && response.data != null ? fromJson(response.data) : response.data as T?,
        message: response.statusMessage,
      );
    }
    on DioException catch (error) {
      print('\nRequest failed: $method $path $data \nError Received: ${error.response?.statusCode} ${error.message}');
      final errorMessage = error.response?.data?['message'] ?? error.message;
      return ApiResponse<T>(
        code: error.response?.statusCode ?? -2,
        data: null,
        message: errorMessage,
      );
    }
    catch (error) {
      return ApiResponse<T>(
        code: -3, // make it clear the error did not come from the server
        data: null,
        message: error.toString(),
      );
    }
  }
}