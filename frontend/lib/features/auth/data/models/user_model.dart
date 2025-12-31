import 'package:flutter_frontend/features/auth/domain/entities/user_entity.dart';

class UserModel {
  final int id;
  final String username;
  final String? email;

  UserModel({
    required this.id,
    required this.username,
    this.email,
  });

  // convert a user entity to a json object
  Map<String, dynamic> toServerObject() {
    return {
      'id': id,
      'username': username,
      'email': email,
    };
  }

  // convert a json object to a user entity
  factory UserModel.fromServerObject(Map<String, dynamic> jsonUser) {
    return UserModel(
      id: jsonUser['id'],
      username: jsonUser['username'],
      email: jsonUser['email'],
    );
  }

    UserEntity toEntity() {
    return UserEntity(
      id: id,
      username: username,
      email: email,
    );
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      username: entity.username,
      email: entity.email,
    );
  }
}