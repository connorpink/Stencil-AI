import 'package:flutter_frontend/features/auth/domain/entities/app_user.dart';
import 'package:flutter_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_frontend/services/logger.dart';
import '../../../services/dio_client.dart';

class NestJsAuthRepo implements AuthRepository {

  @override
  Future<AppUser?> loginWithUsernamePassword(String username, String password) async {

    late final AppUser? appUser;
    late final String responseMessage;
    try {
      final response = await dio.sendRequest<AppUser>(
        'POST', 
        '/auth/login', 
        data: {'username': username, 'password': password},
        fromJson: AppUser.fromJson
      );
      appUser = response.data;
      responseMessage = response.message;
    }
    catch (error, stack) {
      appLogger.e(
        "dio failed to register user with uncaught exception",
        error: error,
        stackTrace: stack,
      );
      throw 'dio failed to catch exception';
    }

    if (appUser != null) { return appUser; }
    else { throw responseMessage; }
  }

  @override
  Future<AppUser?> registerWithUsernamePassword(String username, String email, String password) async {

    late final AppUser? appUser;
    late final String responseMessage;
    try {
      final ApiResponse response = await dio.sendRequest<AppUser>(
        'POST',
        '/auth/register', 
        data: {'username': username, 'email': email, 'password': password},
        fromJson: AppUser.fromJson
      );
      appUser = response.data;
      responseMessage = response.message;
    }
    catch (error, stack) {
      appLogger.e(
        "dio failed to register user with uncaught exception",
        error: error,
        stackTrace: stack,
      );
      throw 'dio failed to catch exception';
    }

    if (appUser != null) { return appUser; }
    else { throw responseMessage; }
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
  Future<AppUser?> getCurrentUser() async {
    try {
      final response = await dio.sendRequest<AppUser>('GET', '/auth/status');
      if (response.code == 200) { return response.data; }
      if (response.code == 401) { return null; }
      else { throw Exception("Failed to get status from server"); }
    }
    catch (error) {
      throw Exception('Status check failed $error');
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