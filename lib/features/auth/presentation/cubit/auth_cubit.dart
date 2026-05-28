import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:TBConsult/core/usecases/usecase.dart';
import 'package:TBConsult/features/auth/domain/usecases/auth_usecases.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final RegisterUseCase registerUseCase;
  final LoginUseCase loginUseCase;
  final GetSavedTokenUseCase getSavedTokenUseCase;
  final LogoutUseCase logoutUseCase;
  final SharedPreferences prefs;

  static const _displayNameKey = 'user_display_name';

  AuthCubit({
    required this.registerUseCase,
    required this.loginUseCase,
    required this.getSavedTokenUseCase,
    required this.logoutUseCase,
    required this.prefs,
  }) : super(const AuthInitial());

  // ── Check persisted session ───────────────────────────────────────────────

  Future<void> checkAuthStatus() async {
    emit(const AuthLoading());
    try {
      final token = await getSavedTokenUseCase(const NoParams());
      if (token != null && token.isNotEmpty) {
        emit(const AuthAuthenticated());
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (_) {
      emit(const AuthUnauthenticated());
    }
  }

  // ── Register ──────────────────────────────────────────────────────────────

  Future<void> register({
    required String email,
    required String password,
    String? fullName,
  }) async {
    emit(const AuthLoading());
    try {
      final user = await registerUseCase(RegisterParams(
        email: email,
        password: password,
        fullName: fullName,
      ));
      emit(AuthRegistered(user: user));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());
    try {
      final token = await loginUseCase(
        LoginParams(email: email, password: password),
      );
      // Persist the display name so DashboardCubit can read it
      // without a separate /me endpoint.
      final name = token.user.fullName?.isNotEmpty == true
          ? token.user.fullName!
          : token.user.email.split('@').first;
      await prefs.setString(_displayNameKey, name);

      emit(AuthLoginSuccess(token: token));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await logoutUseCase(const NoParams());
    await prefs.remove(_displayNameKey);
    emit(const AuthUnauthenticated());
  }
}
