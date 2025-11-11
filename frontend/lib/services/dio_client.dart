import 'package:dio/dio.dart';
import 'package:flutter_frontend/services/logger.dart';

/* 
NEGATIVE RESPONSE CODES 
  -1: Response received but no status code
  -2: DioException (network error, timeout, etc.)
  -3: Dio failed to process the returned object, either object requested or object returned was incorrect
*/

// establish a connection to the server
final dio = Dio(BaseOptions(
  baseUrl: 'http://localhost:3000',
  connectTimeout: Duration(seconds: 10),
  receiveTimeout: Duration(seconds: 5),
  headers: {'Content-Type': 'application/json'}
));

// All objects returned to client from dio.sendRequest are ApiResponse objects
class ApiResponse<T> {
  final int code;
  final T? data;
  final String message;

  ApiResponse({
    required this.code,
    this.data,
    required this.message
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
      T Function(Map<String, dynamic>)? fromJson,
    }
  ) async {

    try {
      // send the request to the server
      final response = await request(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(method: method)
      );

      late final T returnedObject;
      try {
        // convert the returned object using the fromJson method if provided
        if (fromJson != null) { returnedObject = fromJson(response.data); }
        else {
          appLogger.w('fromJson function was not provided, if you using an advanced interface please make sure to pass one');
          returnedObject = response.data as T;
        }
      }
      catch (error, stack) {
        appLogger.e(
          'dio failed to convert returned object into type T, make sure the api being called is responding with the object your expecting. \n'
          'Object returned: ${response.data}',
          error: error,
          stackTrace: stack,
        );
        return ApiResponse<T>(
          code: -3, // Dio ran into an issue processing the returned value
          data: null,
          message: "dio had an issue processing the returned data, please examine logs to find solution",
        );
      }
      
      return ApiResponse<T>(
        code: response.statusCode ?? -1, // send -1 if request was successful but error code was not provided for some reason
        data: returnedObject,
        message: response.statusMessage ?? "Server failed to attach a statusMessage",
      );
    }
    on DioException catch (error) {
      // log what went wrong
      appLogger.e(
        'Request failed: $method $path $data \n' 
        'Error Received: ${error.response?.statusCode} ${error.response?.data}',
      );

      // try and find a message from the backend explaining what went wrong
      final backendErrorMessage = error.response?.data is Map ? error.response?.data['message']?.toString() : null;
      return ApiResponse<T>(
        code: error.response?.statusCode ?? -2, // send -2 if request failed and error code was not provided for some reason
        data: null,
        message: backendErrorMessage ?? error.message ?? "API failed for unknown reason",
      );
    }

  }

}