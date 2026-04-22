import 'package:flutter/foundation.dart';

@immutable
class AuthUser {
  const AuthUser({required this.id, required this.username, required this.email});

  final String id;
  final String username;
  final String email;
}
