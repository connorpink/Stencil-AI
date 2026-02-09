import 'package:flutter_frontend/features/auth/data/models/user_model.dart';
import 'package:flutter_frontend/features/auth/domain/entities/authenticated_user_entity.dart';

class AuthenticatedUserModel {
  final String accessToken;
  final String refreshToken;
  final UserModel user;

  AuthenticatedUserModel({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  // convert a user entity to a json object
  Map<String, dynamic> toServerObject() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'email': user.toServerObject(),
    };
  }

  // convert a json object to a user entity
  factory AuthenticatedUserModel.fromServerObject(Map<String, dynamic> jsonAuthenticatedUser) {
    return AuthenticatedUserModel(
      accessToken: jsonAuthenticatedUser['accessToken'],
      refreshToken: jsonAuthenticatedUser['refreshToken'],
      user: UserModel.fromServerObject(jsonAuthenticatedUser['user']),
    );
  }

  AuthenticatedUserEntity toEntity() {
    return AuthenticatedUserEntity(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user.toEntity(),
    );
  }

  factory AuthenticatedUserModel.fromEntity(AuthenticatedUserEntity entity) {
    return AuthenticatedUserModel(
      accessToken: entity.accessToken,
      refreshToken: entity.refreshToken,
      user: UserModel.fromEntity(entity.user),
    );
  }
}