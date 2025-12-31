import '../entities/user_entity.dart';

abstract class AuthRepositoryInterface {
  Future<UserEntity?> loginWithUsernamePassword(String username, String password);
  Future<UserEntity?> registerWithUsernamePassword(String username, String email, String password);
  Future<void> logout();
  Future<UserEntity?> getCurrentUser();
  Future<String> sendPasswordResetEmail(String email);
  Future<void> deleteAccount();
}