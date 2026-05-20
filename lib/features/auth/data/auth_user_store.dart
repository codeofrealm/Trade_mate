class AuthUserStore {
  static String? username;
  static String? email;
  static String? phoneNumber;
  static String? role;

  static void clear() {
    username = null;
    email = null;
    phoneNumber = null;
    role = null;
  }
}
