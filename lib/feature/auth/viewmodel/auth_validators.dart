enum PasswordStrength { weak, medium, strong }

class AuthValidators {
  static String? validateUsernameOrEmail(String value) {
    if (value.trim().isEmpty) {
      return 'Please enter email or username';
    }

    if (value.contains('@')) {
      final RegExp emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
      if (!emailRegex.hasMatch(value.trim())) {
        return 'Please enter a valid email address';
      }
      return null;
    }

    if (value.trim().length < 3) {
      return 'Username must be at least 3 characters';
    }

    return null;
  }

  static String? validateUsername(String value) {
    if (value.trim().isEmpty) {
      return 'Please enter a username';
    }

    final RegExp usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(value.trim())) {
      return 'Only letters, numbers and underscore are allowed';
    }

    if (value.trim().length < 3) {
      return 'Username must be at least 3 characters';
    }

    return null;
  }

  static String? validateEmail(String value) {
    if (value.trim().isEmpty) {
      return 'Please enter an email';
    }

    final RegExp emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  static String? validatePassword(String value) {
    if (value.isEmpty) {
      return 'Please enter a password';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    return null;
  }

  static String? validateConfirmPassword(String password, String confirm) {
    if (confirm.isEmpty) {
      return 'Please confirm your password';
    }

    if (password != confirm) {
      return 'Passwords do not match';
    }

    return null;
  }

  static PasswordStrength passwordStrength(String password) {
    final bool hasMix = RegExp(r'(?=.*[A-Za-z])(?=.*\d)').hasMatch(password);

    if (password.length >= 10 && hasMix) {
      return PasswordStrength.strong;
    }
    if (password.length >= 6) {
      return PasswordStrength.medium;
    }
    return PasswordStrength.weak;
  }

  static int strengthSegments(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return 1;
      case PasswordStrength.medium:
        return 2;
      case PasswordStrength.strong:
        return 3;
    }
  }
}
