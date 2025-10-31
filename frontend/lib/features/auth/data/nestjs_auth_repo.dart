
import 'package:flutter_frontend/features/auth/domain/entities/app_user.dart';
import 'package:flutter_frontend/features/auth/domain/repos/auth_repo.dart';
import '../../../services/dio_client.dart' as dio;

class NestJsAuthRepo implements AuthRepo {

  @override
  Future<AppUser?> loginWithUsernamePassword(String username, String password) async {
    try {
      AppUser appUser = await dio.sendRequest<AppUser>('POST', '/auth/login', {username, password});
      return appUser;
    }
    catch (error) {
      throw Exception('Login failed: $error');
    }
  }

  @override
  Future<AppUser?> registerWithUsernamePassword(String username, String email, String password) async {
    try {
      AppUser appUser = await dio.sendRequest<AppUser>('POST','/auth/register');
      return appUser;
    }
    catch (error) {
      throw Exception('Register failed $error');
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
  Future<AppUser?> getCurrentUser() async {
    try {
      final currentUser = await dio.sendRequest('GET', '/auth/status');
      if (currentUser == null) { return null; }
      return AppUser(id: currentUser.id, username: currentUser.username);
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