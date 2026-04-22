import 'package:talk_gym/feature/auth/data/model/auth_user.dart';

class AuthResponse {
  const AuthResponse({
    required this.token,
    required this.user,
    this.tokenType = 'bearer',
  });

  final String token;
  final AuthUser user;
  final String tokenType;
}
