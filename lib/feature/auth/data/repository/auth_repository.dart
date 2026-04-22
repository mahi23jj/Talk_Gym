import 'package:talk_gym/feature/auth/data/model/auth_response.dart';

abstract class AuthRepository {
  Future<AuthResponse> login({
    required String usernameOrEmail,
    required String password,
  });

  Future<AuthResponse> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
  });

  Future<AuthResponse> googleAuth();

  Future<String?> getStoredToken();

  Future<void> saveToken(String token);

  Future<void> clearToken();

  Future<bool> isUsernameAvailable(String username);
}
