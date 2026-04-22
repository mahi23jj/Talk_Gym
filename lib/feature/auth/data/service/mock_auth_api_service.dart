import 'package:talk_gym/feature/auth/data/model/auth_exception.dart';
import 'package:talk_gym/feature/auth/data/model/auth_response.dart';
import 'package:talk_gym/feature/auth/data/model/auth_user.dart';

class MockAuthApiService {
  final Set<String> _existingUsernames = <String>{'testuser', 'coachdemo'};
  final Set<String> _existingEmails = <String>{'user@example.com', 'demo@talkgym.ai'};
  final String google_client_id = '949578675976-tdju2r1gntljnt70q3qld0to9o4akhcf.apps.googleusercontent.com';

  Future<AuthResponse> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(seconds: 1));

    final bool isEmail = usernameOrEmail.contains('@');
    final bool userExists = isEmail
        ? _existingEmails.contains(usernameOrEmail.toLowerCase())
        : _existingUsernames.contains(usernameOrEmail.toLowerCase());

    if (!userExists) {
      throw const AuthException('User not found');
    }

    if (password != 'password123') {
      throw const AuthException('Invalid credentials');
    }

    return const AuthResponse(
      token: 'mock_jwt_token',
      user: AuthUser(id: '1', username: 'testuser', email: 'user@example.com'),
    );
  }

  Future<AuthResponse> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
  }) async {
    await Future<void>.delayed(const Duration(seconds: 1));

    final String normalizedUsername = username.toLowerCase();
    final String normalizedEmail = email.toLowerCase();

    if (_existingUsernames.contains(normalizedUsername)) {
      throw const AuthException('Username already exists');
    }

    if (_existingEmails.contains(normalizedEmail)) {
      throw const AuthException('Email already registered');
    }

    if (password != passwordConfirm) {
      throw const AuthException('Passwords do not match');
    }

    _existingUsernames.add(normalizedUsername);
    _existingEmails.add(normalizedEmail);

    return AuthResponse(
      token: 'mock_jwt_token',
      user: AuthUser(id: '1', username: username, email: email),
    );
  }

  Future<AuthResponse> googleAuth() async {
    await Future<void>.delayed(const Duration(seconds: 1));

    return const AuthResponse(
      token: 'mock_jwt_token',
      user: AuthUser(
        id: 'google_1',
        username: 'google_user',
        email: 'google.user@example.com',
      ),
    );
  }

  Future<bool> isUsernameAvailable(String username) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return !_existingUsernames.contains(username.toLowerCase());
  }
}
