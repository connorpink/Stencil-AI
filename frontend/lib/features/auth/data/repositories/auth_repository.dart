import 'package:dio/dio.dart';
import 'package:flutter_frontend/core/core.dart';
import 'package:flutter_frontend/features/auth/data/models/authenticated_user_model.dart';
import 'package:flutter_frontend/features/auth/data/models/user_model.dart';
import 'package:flutter_frontend/features/auth/domain/entities/authenticated_user_entity.dart';
import 'package:flutter_frontend/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_frontend/features/auth/domain/repositories/auth_repository_interface.dart';
import 'package:flutter_frontend/services/dio_client.dart';
import 'package:flutter_frontend/services/logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthRepository implements AuthRepositoryInterface {
  final FlutterSecureStorage storage = FlutterSecureStorage();

  // default error handler for all functions inside the repository
  Future<T> _defaultErrorHandler<T>( String functionName, Future<T> Function() request) async {
    try { return await request(); }
    on DioException catch(error) { // If it was a DioException dio would have already logged it
      if (error.response == null) { rethrow; }
      final String? message = error.response!.data['message'];
      if(message != null) { throw ExpectedRepositoryException(message); }
      else { rethrow; }
    }
    on FormatException { // formatting exceptions are logged as they are happening
      rethrow;
    }
    catch (error) {
      appLogger.e("auth_repository.$functionName ran into an unexpected error", error: error);
      rethrow;
    }
  }

  @override
  Future<AuthenticatedUserEntity> loginWithUsernamePassword(String username, String password) async {
    return _defaultErrorHandler('loginWithUsernamePassword', () async {

      late final ApiResponse<AuthenticatedUserModel> response;
      response = await dio.sendRequest<AuthenticatedUserModel>(
        'POST', 
        '/auth/login', 
        data: {'username': username, 'password': password},
        responseProcessor: (jsonObject) {
          return AuthenticatedUserModel.fromServerObject(jsonObject);
        }
      );

      final AuthenticatedUserModel authenticatedUser = response.data;

      await storage.write(key: 'access_token', value: authenticatedUser.accessToken);
      await storage.write(key: 'refresh_token', value: authenticatedUser.refreshToken);

      return authenticatedUser.toEntity();

    });
  }

  @override
  Future<AuthenticatedUserEntity> registerWithUsernamePassword(String username, String email, String password) async {
    return _defaultErrorHandler('registerWithUsernamePassword', () async {

      final response = await dio.sendRequest<AuthenticatedUserModel>(
        'POST',
        '/auth/register', 
        data: {'username': username, 'email': email, 'password': password},
        responseProcessor: (jsonObject) {
          return AuthenticatedUserModel.fromServerObject(jsonObject);
        }
      );

      final AuthenticatedUserModel authenticatedUser = response.data;
      await storage.write(key: 'access_token', value: authenticatedUser.accessToken);
      await storage.write(key: 'refresh_token', value: authenticatedUser.refreshToken);

      return authenticatedUser.toEntity();

    });
  }
  
  @override
  Future<void> deleteAccount() async{
    return _defaultErrorHandler('deleteAccount', () async {

      await dio.sendRequest('POST', '/auth/deleteAccount');

    });
  }
  
  @override
  Future<UserEntity> fetchAuthenticatedUser() async {
    return _defaultErrorHandler('fetchAuthenticatedUser', () async {

      final response = await dio.sendRequest<UserModel>(
        'GET',
        '/auth/status',
        responseProcessor: (jsonObject) => UserModel.fromServerObject(jsonObject),
      );
      return response.data.toEntity();

    });
  }
  
  @override
  Future<void> logout() async {
    return _defaultErrorHandler('logout', () async {

      await Future.wait([
        storage.delete(key: 'access_token').catchError((error) { return appLogger.e("storage failed to delete access_token", error: error); }),
        storage.delete(key: 'refresh_token').catchError((error) { return appLogger.e("storage failed to delete refresh_token", error: error); }),
      ]);

    });
  }
  
  @override
  Future<String> sendPasswordResetEmail(String email) async { return _defaultErrorHandler('sendPasswordResetEmail', () async {
    return _defaultErrorHandler('sendPasswordResetEmail', () async {

      await dio.sendRequest('POST', '/auth/resetPassword');
      return "Password reset email sent! Check your inbox.";

    });
  });}
}