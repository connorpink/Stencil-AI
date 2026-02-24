import 'package:dio/dio.dart';
import 'package:flutter_frontend/services/logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const storage = FlutterSecureStorage();

// variables to make sure only on refresh request is active at any given time
bool _refreshInProgress = false;
List<Function> _requestsWaitingForRefresh = [];

// establish a connection to the server
final dio = Dio(BaseOptions(
  baseUrl: 'http://localhost:3000',
  connectTimeout: Duration(seconds: 10),
  receiveTimeout: Duration(seconds: (60 * 60)), //! this is a 1 hour timeout for testing, only createArtwork in the drawing repo should need this much time before timeout
  headers: {'Content-Type': 'application/json'}
));

// ? A version of dio that is clean and without interceptors, this should be used inside the dio interceptors to avoid loops
final _dioWithoutInterceptors = Dio(BaseOptions(
  baseUrl: 'http://localhost:3000',
  connectTimeout: Duration(seconds: 10),
  receiveTimeout: Duration(seconds: (60 * 60)), //! this is a 1 hour timeout for testing, only createArtwork in the drawing repo should need this much time before timeout
  headers: {'Content-Type': 'application/json'}
));

// A faster version of dio interceptors that fetch jwt tokens from the memory
void setupDioAuth(String? Function() getAccessToken, String? Function() getRefreshToken, void Function(String) setAccessToken) {

  //! this clears all interceptors, if permanent interceptors are being added before this function is called, make sure this section of code is modified
  dio.interceptors.clear();

  dio.interceptors.add(InterceptorsWrapper(

    // attach JWT access_token to each request (if it exists)
    onRequest: (options, handler) {
      final accessToken = getAccessToken();
      options.headers['Authorization'] = 'Bearer $accessToken';
      handler.next(options);
    },

    // If the request fails, check if it failed with a 401 error and a refresh_token can be used to resend the request with a fresh access_token
    onError: (baseError, handler) async {
      if (baseError.response?.statusCode == 401) {
        final refreshToken = getRefreshToken();
        if (refreshToken != null) {
          try { 
            await _handleRefresh(getAccessToken, setAccessToken, refreshToken, baseError, handler);
            return;
          }
          catch (unexpectedError){
            appLogger.e('dio ran into an unexpected error while attempting a token refresh', error: unexpectedError);
            return handler.next(baseError);
          }
        }
      }
      handler.next(baseError);
    },
  ));
}

Future<void> _handleRefresh(String? Function() getAccessToken, void Function(String) setAccessToken, String refreshToken, DioException oldDioError, ErrorInterceptorHandler handler) async {
  // first check to make sure a refresh request isn't already being made
  if (_refreshInProgress) {
    // add the _retryRequest function to the que and let the first refresh pass handle the request form there
    _requestsWaitingForRefresh.add(() => _retryRequest(getAccessToken, oldDioError, handler));
    return;
  }

  // handle the refresh on this pass if refresh isn't yet in progress
  _refreshInProgress = true;

  late final String newAccessToken;
  try {
    final response = await _dioWithoutInterceptors.post(
      '/auth/refresh',
      data: {'refreshToken': refreshToken}
    );
    newAccessToken = response.data['accessToken'];
  }
  on DioException catch (error) {
    appLogger.w("Token refresh failed", error: error);
    _handleRefreshTokenRejected();
    return handler.next(oldDioError);
  }

  // Store new tokens
  await storage.write(key: 'access_token', value: newAccessToken);
  setAccessToken(newAccessToken);

  // complete current request
  await _retryRequest(getAccessToken, oldDioError, handler);

  for ( var request in _requestsWaitingForRefresh) { await request(); }
  _requestsWaitingForRefresh.clear();

  // cleanup variable before exiting code
  _requestsWaitingForRefresh.clear();
  _refreshInProgress = false;

  return;
}

void _handleRefreshTokenRejected() async {
  // remove tokens from the keychain
  await storage.delete(key: 'access_token');
  await storage.delete(key: 'refresh_token');

  _requestsWaitingForRefresh.clear();
  _refreshInProgress = false;
}

// executes a failed request a second time
Future<void> _retryRequest(String? Function() getAccessToken, DioException oldDioError, ErrorInterceptorHandler handler) async {

  // get the new access token and make sure it exists
  late final String? accessToken;
  accessToken = getAccessToken();

  if (accessToken == null) { return handler.next(oldDioError); }

  // resend the original request with the new access tokens
  final oldOptions = oldDioError.requestOptions;
  final newOptions = Options(
    method: oldOptions.method,
    headers: {
      ...oldOptions.headers,
      'Authorization': 'Bearer $accessToken',
    },
  );

  final response = await _dioWithoutInterceptors.request(
    oldOptions.path,
    data: oldOptions.data,
    queryParameters: oldOptions.queryParameters,
    options: newOptions,
  );

  return handler.resolve(response);
}

// All objects returned to client from dio.sendRequest are ApiResponse objects
class ApiResponse<T> {
  final int code;
  final T data;
  final String message;

  ApiResponse({
    required this.code,
    required this.data,
    required this.message
  });

  // for logging whats been received from the server
  @override
  String toString() => 'ApiResponse(code: $code, data: $data, message: $message)';
}

extension DioApiExtension on Dio {

  Future<ApiResponse<T>> sendRequest<T>(
    String method, // request type being sent to the server
    String path, // path to the server endpoint
    {
      dynamic data, // body fields that should be sent with the request
      Map<String, dynamic>? queryParameters, // parameters that should be sent with the request
      T Function(dynamic)? responseProcessor, // function that converts JSON responses from the server to the expected T variable types
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
        if (responseProcessor != null) {
          returnedObject = responseProcessor(response.data); 
        }
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
        rethrow;
      }
      
      return ApiResponse<T>(
        code: response.statusCode ?? 0,
        data: returnedObject,
        message: response.statusMessage ?? "Server failed to attach a statusMessage",
      );
    }
    on DioException catch (error) {
      // log what went wrong
      appLogger.w('Request failed: $method $path', error: 'API error response: ${error.response?.data}');
      rethrow;
    }
    catch (error) {
      appLogger.e("unexpectedError from dio", error: error);
      rethrow;
    }
  }
}