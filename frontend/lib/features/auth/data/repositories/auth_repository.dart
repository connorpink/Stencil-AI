import 'package:dio/dio.dart';
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

  @override
  Future<AuthenticatedUserEntity?> loginWithUsernamePassword(String username, String password) async {

    try {
      final response = await dio.sendRequest<AuthenticatedUserModel>(
        'POST', 
        '/auth/login', 
        data: {'username': username, 'password': password},
        responseProcessor: (jsonObject) {
          return AuthenticatedUserModel.fromServerObject(jsonObject);
        }
      );

      final AuthenticatedUserModel authenticatedUser = response.data;

      storage.write(key: 'access_token', value: authenticatedUser.accessToken);
      storage.write(key: 'refresh_token', value: authenticatedUser.refreshToken);

      return authenticatedUser.toEntity();
    }
    on DioException catch (error) {
      appLogger.w("login request failed", error: error);
      throw Exception(error.message);
    }
    catch (error, stack) {
      appLogger.e(
        "dio failed to register user with uncaught exception",
        error: error,
        stackTrace: stack,
      );
      throw Exception('dio failed to catch exception');
    }
  }

  @override
  Future<AuthenticatedUserEntity?> registerWithUsernamePassword(String username, String email, String password) async {
    try {
      final response = await dio.sendRequest<AuthenticatedUserModel>(
        'POST',
        '/auth/register', 
        data: {'username': username, 'email': email, 'password': password},
        responseProcessor: (jsonObject) {
          return AuthenticatedUserModel.fromServerObject(jsonObject);
        }
      );

      final AuthenticatedUserModel authenticatedUser = response.data;
      storage.write(key: 'access_token', value: authenticatedUser.accessToken);
      storage.write(key: 'refresh_token', value: authenticatedUser.refreshToken);

      return authenticatedUser.toEntity();
    }
    on DioException catch (error){
      appLogger.w("login request failed", error: error);
      throw Exception(error.message);
    }
    catch (error, stack) {
      appLogger.e(
        "dio failed to register user with uncaught exception",
        error: error,
        stackTrace: stack,
      );
      throw Exception('dio failed to catch exception');
    }
  }
  
  @override
  Future<void> deleteAccount() async{
    try {
      await dio.sendRequest('POST', '/auth/deleteAccount');
    }
    catch (error) {
      throw Exception('Delete account failed $error');
    }
  }
  
  @override
  Future<UserEntity?> fetchAuthenticatedUser() async {
    try {
      final response = await dio.sendRequest<UserModel>(
        'GET',
        '/auth/status',
        responseProcessor: (jsonObject) => UserModel.fromServerObject(jsonObject),
      );
      return response.data.toEntity();
    }
    on DioException catch(error) {
      appLogger.w("server failed to return authentication status", error: error);
      return null;
    }
    catch (error) {
      appLogger.e("unexpected error occurred", error: error);
      throw Exception('Status check returned and error');
    }
  }
  
  @override
  Future<void> logout() async {
    try {
      await dio.sendRequest('POST', '/auth/logout');
    }
    catch (error) {
      throw Exception('Failed to log out $error');
    }
  }
  
  @override
  Future<String> sendPasswordResetEmail(String email) async {
    try {
      await dio.sendRequest('POST', '/auth/resetPassword');
      return "Password reset email sent! Check your inbox.";
    }
    catch (error) {
      throw Exception('failed to send password reset email $error');
    }
  }
}