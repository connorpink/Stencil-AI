import 'package:dio/dio.dart';

final dio = Dio(BaseOptions(
  baseUrl: 'http://localhost:3000',
  connectTimeout: Duration(seconds: 10),
  receiveTimeout: Duration(seconds: 5),
  headers: {'Content-Type': 'application/json'}
));

Future<T> sendRequest<T>(String method, String url, [dynamic data]) async {
  try {
    late Response response;

    switch (method.toUpperCase()) {
      case 'GET':
        response = await dio.get(url, queryParameters: data);
        break;
      case 'POST':
        response = await dio.post(url, data: data);
        break;
      case 'PUT':
        response = await dio.put(url, data: data);
        break;
      case 'DELETE':
        response = await dio.delete(url, data: data);
        break;
      default:
        throw ArgumentError('Unsupported method: $method');
    }

    print('[${response.statusCode}] ${response.data}');
    return response.data as T;
  }
  on DioException catch (error) {
    print('Request failed: ${error.response?.statusCode} ${error.message}');
    throw Exception("Dio caught exception");
  }
}