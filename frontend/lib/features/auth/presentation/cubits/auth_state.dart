import 'package:flutter_frontend/features/auth/domain/entities/authenticated_user_entity.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends  AuthState {}

class Authenticated extends AuthState {
  final AuthenticatedUserEntity user;
  Authenticated(this.user);
}

class Unauthenticated extends AuthState {
  Unauthenticated();
}

class AuthError extends AuthState {
  final String? message;
  AuthError({this.message});
}