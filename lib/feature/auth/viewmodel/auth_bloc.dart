import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talk_gym/feature/auth/data/model/auth_exception.dart';
import 'package:talk_gym/feature/auth/data/model/auth_response.dart';
import 'package:talk_gym/feature/auth/data/model/auth_user.dart';
import 'package:talk_gym/feature/auth/data/repository/auth_repository.dart';

@immutable
sealed class AuthEvent {
  const AuthEvent();
}

class LoginSubmitted extends AuthEvent {
  const LoginSubmitted({required this.usernameOrEmail, required this.password});

  final String usernameOrEmail;
  final String password;
}

class SignUpSubmitted extends AuthEvent {
  const SignUpSubmitted({
    required this.username,
    required this.email,
    required this.password,
    required this.passwordConfirm,
  });

  final String username;
  final String email;
  final String password;
  final String passwordConfirm;
}

class GoogleAuthRequested extends AuthEvent {
  const GoogleAuthRequested();
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class CheckAuthStatus extends AuthEvent {
  const CheckAuthStatus();
}

@immutable
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  const Authenticated({required this.user, required this.token});

  final AuthUser user;
  final String token;
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class AuthError extends AuthState {
  const AuthError(this.message);

  final String message;
}

class SignUpSuccess extends AuthState {
  const SignUpSuccess();
}

class GoogleAuthLoading extends AuthState {
  const GoogleAuthLoading();
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository repository})
      : _repository = repository,
        super(const AuthInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<SignUpSubmitted>(_onSignUpSubmitted);
    on<GoogleAuthRequested>(_onGoogleAuthRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
  }

  final AuthRepository _repository;

  AuthRepository get repository => _repository;

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final AuthResponse response = await _repository.login(
        usernameOrEmail: event.usernameOrEmail.trim(),
        password: event.password,
      );
      await _repository.saveToken(response.token);
      emit(Authenticated(user: response.user, token: response.token));
    } on AuthException catch (error) {
      emit(AuthError(error.message));
      emit(const Unauthenticated());
    } catch (_) {
      emit(const AuthError('Network error'));
      emit(const Unauthenticated());
    }
  }

  Future<void> _onSignUpSubmitted(
    SignUpSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final AuthResponse response = await _repository.register(
        username: event.username.trim(),
        email: event.email.trim(),
        password: event.password,
        passwordConfirm: event.passwordConfirm,
      );
      await _repository.saveToken(response.token);
      emit(const SignUpSuccess());
      emit(const Unauthenticated());
    } on AuthException catch (error) {
      emit(AuthError(error.message));
      emit(const Unauthenticated());
    } catch (_) {
      emit(const AuthError('Network error'));
      emit(const Unauthenticated());
    }
  }

  Future<void> _onGoogleAuthRequested(
    GoogleAuthRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const GoogleAuthLoading());

    try {
      final AuthResponse response = await _repository.googleAuth();
      await _repository.saveToken(response.token);
      emit(Authenticated(user: response.user, token: response.token));
    } on AuthException catch (error) {
      emit(AuthError(error.message));
      emit(const Unauthenticated());
    } catch (_) {
      emit(const AuthError('Network error'));
      emit(const Unauthenticated());
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _repository.clearToken();
    emit(const Unauthenticated());
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    final String? token = await _repository.getStoredToken();

    if (token == null || token.isEmpty) {
      emit(const Unauthenticated());
      return;
    }

    if (!_isTokenUsable(token)) {
      await _repository.clearToken();
      emit(const Unauthenticated());
      return;
    }

    emit(
      Authenticated(
        token: token,
        user: const AuthUser(id: 'stored', username: 'authenticated_user', email: ''),
      ),
    );
  }

  bool _isTokenUsable(String token) {
    final List<String> parts = token.split('.');
    if (parts.length != 3) {
      return false;
    }

    try {
      final String normalized = base64Url.normalize(parts[1]);
      final String payloadJson = utf8.decode(base64Url.decode(normalized));
      final dynamic decoded = jsonDecode(payloadJson);
      if (decoded is! Map<String, dynamic>) {
        return false;
      }

      final dynamic expRaw = decoded['exp'];
      int? expSeconds;
      if (expRaw is int) {
        expSeconds = expRaw;
      } else if (expRaw is num) {
        expSeconds = expRaw.toInt();
      } else if (expRaw is String) {
        expSeconds = int.tryParse(expRaw);
      }

      if (expSeconds == null) {
        return false;
      }

      final DateTime expiresAt = DateTime.fromMillisecondsSinceEpoch(
        expSeconds * 1000,
        isUtc: true,
      );

      return expiresAt.isAfter(DateTime.now().toUtc());
    } catch (_) {
      return false;
    }
  }
}
