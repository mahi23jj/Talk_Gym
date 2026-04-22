import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:talk_gym/feature/auth/data/model/auth_exception.dart';
import 'package:talk_gym/feature/auth/data/model/auth_response.dart';
import 'package:talk_gym/feature/auth/data/model/auth_user.dart';

class MockAuthApiService {
  static const String _loginEndpoint = 'http://127.0.0.1:8000/api/v1/auth/login';
  static const String _signInEndpoint = 'http://127.0.0.1:8000/api/v1/auth/signin';
  static const String _googleEndpoint = 'http://127.0.0.1:8000/api/v1/auth/google';

  // ignore: non_constant_identifier_names
  final String google_client_id = '949578675976-tdju2r1gntljnt70q3qld0to9o4akhcf.apps.googleusercontent.com';

  final http.Client _client;

  MockAuthApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<AuthResponse> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    final http.Response response = await _client.post(
      Uri.parse(_loginEndpoint),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, String>{
        'username': usernameOrEmail,
        'password': password,
      }),
    );

    final Map<String, dynamic> json = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(_extractErrorMessage(json, fallback: 'Invalid credentials'));
    }

    final String token = _extractAccessToken(json);
    final bool isEmail = usernameOrEmail.contains('@');

    return AuthResponse(
      token: token,
      tokenType: _extractTokenType(json),
      user: AuthUser(
        id: 'local_login',
        username: isEmail ? usernameOrEmail.split('@').first : usernameOrEmail,
        email: isEmail ? usernameOrEmail : '',
      ),
    );
  }

  Future<AuthResponse> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
  }) async {
    final http.Response response = await _client.post(
      Uri.parse(_signInEndpoint),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, String>{
        'username': username,
        'email': email,
        'password': password,
        'password_confirm': passwordConfirm,
      }),
    );

    final Map<String, dynamic> json = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(_extractErrorMessage(json, fallback: 'Sign up failed'));
    }

    return AuthResponse(
      token: _extractAccessToken(json),
      tokenType: _extractTokenType(json),
      user: AuthUser(id: 'local_signup', username: username, email: email),
    );
  }

  Future<AuthResponse> googleAuth() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: const <String>['email', 'profile'],
      serverClientId: google_client_id,
    );

    final GoogleSignInAccount? account = await googleSignIn.signIn();
    if (account == null) {
      throw const AuthException('Google sign in was cancelled');
    }

    final GoogleSignInAuthentication auth = await account.authentication;
    final String? idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const AuthException('Unable to retrieve Google token');
    }

    final http.Response response = await _client.post(
      Uri.parse(_googleEndpoint),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, String>{'token': idToken}),
    );

    final Map<String, dynamic> json = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(_extractErrorMessage(json, fallback: 'Google authentication failed'));
    }

    return AuthResponse(
      token: _extractAccessToken(json),
      tokenType: _extractTokenType(json),
      user: AuthUser(
        id: account.id,
        username: account.displayName ?? account.email.split('@').first,
        email: account.email,
      ),
    );
  }

  Future<bool> isUsernameAvailable(String username) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return username.toLowerCase() != 'testuser';
  }

  Map<String, dynamic> _decodeBody(String body) {
    if (body.isEmpty) {
      return <String, dynamic>{};
    }

    final dynamic decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return <String, dynamic>{};
  }

  String _extractAccessToken(Map<String, dynamic> json) {
    final dynamic token = json['access_token'];
    if (token is String && token.isNotEmpty) {
      return token;
    }
    throw const AuthException('Invalid server response: missing access_token');
  }

  String _extractTokenType(Map<String, dynamic> json) {
    final dynamic tokenType = json['token_type'];
    if (tokenType is String && tokenType.isNotEmpty) {
      return tokenType;
    }
    return 'bearer';
  }

  String _extractErrorMessage(Map<String, dynamic> json, {required String fallback}) {
    final dynamic directMessage = json['message'] ?? json['detail'] ?? json['error'];
    if (directMessage is String && directMessage.isNotEmpty) {
      return directMessage;
    }
    return fallback;
  }
}
