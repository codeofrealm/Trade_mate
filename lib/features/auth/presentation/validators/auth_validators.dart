class AuthValidators {
  static String? validateUsername(String? value) {
    final username = value?.trim() ?? '';
    if (username.isEmpty) {
      return 'Please enter your username';
    }

    if (username.length < 3) {
      return 'Username must be at least 3 characters';
    }

    return null;
  }

  static String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Please enter your email';
    }

    const pattern = r'^[\w\.-]+@[\w\.-]+\.\w{2,}$';
    if (!RegExp(pattern).hasMatch(email)) {
      return 'Please enter a valid email';
    }

    return null;
  }

  static String? validatePassword(String? value, {int minLength = 6}) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Please enter your password';
    }

    if (password.length < minLength) {
      return 'Password must be at least $minLength characters';
    }

    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    final confirmPassword = value ?? '';
    if (confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }

    if (confirmPassword != password) {
      return 'Passwords do not match';
    }

    return null;
  }
}
