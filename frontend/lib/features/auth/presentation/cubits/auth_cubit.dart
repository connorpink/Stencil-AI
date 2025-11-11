// cubits are responsible for state management

import 'package:flutter_frontend/features/auth/domain/entities/app_user.dart';
import 'package:flutter_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_frontend/features/auth/presentation/cubits/auth_states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_frontend/services/logger.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepo;
  AppUser? _currentUser;

  AuthCubit({required this.authRepo}) : super(AuthInitial());

  // get current user
  AppUser? get currentUser => _currentUser;

  // check if user is authenticated
  Future<void> checkAuth() async {
    // set to loading
    emit(AuthLoading());

    try {
      // get current user
      final AppUser? user = await authRepo.getCurrentUser();

      if (user != null) {
        _currentUser = user;
        emit(Authenticated(user));
      }
      else {
        emit(Unauthenticated());
      }
    }

    catch (error) {
      emit(AuthError(error.toString()));
    }
  }

  Future<void> login(String username, String password) async {
    try {
      emit(AuthLoading());
      final user = await authRepo.loginWithUsernamePassword(username, password);

      if (user != null) {
        _currentUser = user;
        emit(Authenticated(user));
      }
      else {
        emit(Unauthenticated());
      }
    }
    catch (error) {
      emit(AuthError(error.toString()));
    }
  }

  Future<void> register(String username, String email, String password) async {
    try {
      emit(AuthLoading());
      final user = await authRepo.registerWithUsernamePassword(username, email, password);
      if (user != null) {
        _currentUser = user;
        emit(Authenticated(user));
      }
      else {
        emit(Unauthenticated());
      }
    }
    catch (error, stack) {
      String errorString = error.toString();
      appLogger.e(
        'Something went wrong registering the user',
        error: error,
        stackTrace: stack
      );
      emit(AuthError(errorString));
    }
  }

  Future<void> logout() async {
    emit(AuthLoading());
    await authRepo.logout();
    emit(Unauthenticated());
  }

  Future<String> forgotPassword(String email) async {
    try {
      final message = await authRepo.sendPasswordResetEmail(email);
      return message;
    }
    catch (error) {
      return error.toString();
    }
  }

  Future<void> deleteAccount() async {
    try {
      emit(AuthLoading());
      await authRepo.deleteAccount();
      emit(Unauthenticated());
    }
    catch (error) {
      emit(AuthError(error.toString()));
    }
  }
}