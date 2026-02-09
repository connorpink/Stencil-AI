import 'package:flutter_frontend/features/auth/domain/entities/authenticated_user_entity.dart';
import 'package:flutter_frontend/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepositoryInterface {
  Future<AuthenticatedUserEntity?> loginWithUsernamePassword(String username, String password);
  Future<AuthenticatedUserEntity?> registerWithUsernamePassword(String username, String email, String password);
  Future<void> logout();
  Future<UserEntity?> fetchAuthenticatedUser();
  Future<String> sendPasswordResetEmail(String email);
  Future<void> deleteAccount();
}