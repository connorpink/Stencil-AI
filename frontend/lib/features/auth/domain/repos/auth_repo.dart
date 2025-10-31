import '../entities/app_user.dart';

abstract class AuthRepo {
  Future<AppUser?> loginWithUsernamePassword(String username, String password);
  Future<AppUser?> registerWithUsernamePassword(String username, String email, String password);
  Future<void> logout();
  Future<AppUser?> getCurrentUser();
  Future<String> sendPasswordResetEmail(String email);
  Future<void> deleteAccount();
}