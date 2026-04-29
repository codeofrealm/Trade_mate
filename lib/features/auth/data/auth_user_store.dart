class AuthUserStore {
  static String? username;
  static String? email;
  static String? role;

  static void clear() {
    username = null;
    email = null;
    role = null;
  }
}
