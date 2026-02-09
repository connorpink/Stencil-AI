import 'package:flutter_frontend/features/auth/domain/entities/user_entity.dart';

class AuthenticatedUserEntity {
  String accessToken;
  String refreshToken;
  UserEntity user;

  AuthenticatedUserEntity({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });
}