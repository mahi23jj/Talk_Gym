import 'package:shared_preferences/shared_preferences.dart';
import 'package:talk_gym/feature/auth/data/model/auth_response.dart';
import 'package:talk_gym/feature/auth/data/repository/auth_repository.dart';
import 'package:talk_gym/feature/auth/data/service/mock_auth_api_service.dart';

class MockAuthRepository implements AuthRepository {
  MockAuthRepository({required MockAuthApiService apiService}) : _apiService = apiService;

  static const String _tokenKey = 'auth_token';

  final MockAuthApiService _apiService;

  @override
  Future<void> clearToken() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove(_tokenKey);
  }

  @override
  Future<String?> getStoredToken() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getString(_tokenKey);
  }

  @override
  Future<AuthResponse> googleAuth() {
    return _apiService.googleAuth();
  }

  @override
  Future<AuthResponse> login({
    required String usernameOrEmail,
    required String password,
  }) {
    return _apiService.login(usernameOrEmail: usernameOrEmail, password: password);
  }

  @override
  Future<AuthResponse> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
  }) {
    return _apiService.register(
      username: username,
      email: email,
      password: password,
      passwordConfirm: passwordConfirm,
    );
  }

  @override
  Future<void> saveToken(String token) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(_tokenKey, token);
  }

  @override
  Future<bool> isUsernameAvailable(String username) {
    return _apiService.isUsernameAvailable(username);
  }
}
