// cubits are responsible for state management
import 'package:flutter_frontend/core/core.dart';
import 'package:flutter_frontend/features/auth/domain/entities/authenticated_user_entity.dart';
import 'package:flutter_frontend/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_frontend/features/auth/domain/repositories/auth_repository_interface.dart';
import 'package:flutter_frontend/features/auth/presentation/cubits/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_frontend/services/logger.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepositoryInterface authRepository;
  AuthenticatedUserEntity? _currentAuthenticatedUser;

  AuthCubit({
    required this.authRepository,
  }) : super(AuthInitial());

  // get current user
  UserEntity? get user => _currentAuthenticatedUser?.user;

  // get access tokens for authenticated user (will return [accessToken, refreshToken] or null);
  String? get accessToken => _currentAuthenticatedUser?.accessToken;
  set accessToken(String value) => _currentAuthenticatedUser?.accessToken = value;
  String? get refreshToken => _currentAuthenticatedUser?.refreshToken;
  set refreshToken(String value) => _currentAuthenticatedUser?.accessToken = value;

  // check if user is authenticated
  Future<void> setInitialAuthentication(String? accessToken, String? refreshToken, UserEntity? user) async {
    // set to loading
    emit(AuthLoading());

    if (accessToken != null && refreshToken != null && user != null) {
      _currentAuthenticatedUser = AuthenticatedUserEntity(
        accessToken: accessToken, 
        refreshToken: refreshToken, 
        user: user
      );
      emit(Authenticated(_currentAuthenticatedUser!));
    }
    else {
      emit(Unauthenticated());
    }
  }

  Future<void> login(String username, String password) async {
    emit(AuthLoading());
    try {
      final AuthenticatedUserEntity authenticatedUser = await authRepository.loginWithUsernamePassword(username, password);
      _currentAuthenticatedUser = authenticatedUser;
      emit(Authenticated(authenticatedUser));
    }
    on ExpectedRepositoryException catch(error) {
      emit(AuthError(message: error.message));
    }
    catch (error) {
      appLogger.e("AuthCubit login failed", error: error);
      emit(AuthError(message: "login failed, unknown issue"));
    }
  }

  Future<void> register(String username, String email, String password) async {
    emit(AuthLoading());
    try {
      final AuthenticatedUserEntity authenticatedUser = await authRepository.registerWithUsernamePassword(username, email, password);
      _currentAuthenticatedUser = authenticatedUser;
      emit(Authenticated(authenticatedUser));
    }
    on ExpectedRepositoryException catch (error) {
      emit(AuthError(message:  error.message));
    }
    catch (error) {
      appLogger.e("AuthCubit register failed", error: error);
      emit(AuthError(message: "register failed, unknown issue")); 
    }
  }

  Future<void> logout() async {
    emit(AuthLoading());
    await authRepository.logout();
    _currentAuthenticatedUser = null;
    emit(Unauthenticated());
  }

  Future<String> forgotPassword(String email) async {
    try {
      final message = await authRepository.sendPasswordResetEmail(email);
      return message;
    }
    catch (error) {
      return error.toString();
    }
  }

  Future<void> deleteAccount() async {
    try {
      emit(AuthLoading());
      await authRepository.deleteAccount();
      emit(Unauthenticated());
    }
    catch (error) {
      emit(AuthError(message: error.toString()));
    }
  }
}