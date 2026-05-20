import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_user_store.dart';

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;
}

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _fixedAdminUsername = 'Admin';
  static const String _fixedAdminEmail = 'admin@gmail.com';
  static const String adminPhoneNumber = '1234567890';

  static bool _equalsIgnoreCase(String a, String b) {
    return a.trim().toLowerCase() == b.trim().toLowerCase();
  }

  static String _normalizePhoneNumber(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

  static Future<QueryDocumentSnapshot<Map<String, dynamic>>?>
      _findUserByPhoneNumber(String phoneNumber) async {
    final normalizedPhone = _normalizePhoneNumber(phoneNumber);
    if (normalizedPhone.isEmpty) return null;

    final topLevelMatch = await _firestore
        .collection('users')
        .where('phoneNumber', isEqualTo: normalizedPhone)
        .limit(1)
        .get();
    if (topLevelMatch.docs.isNotEmpty) {
      return topLevelMatch.docs.first;
    }

    final addressMatch = await _firestore
        .collection('users')
        .where('address.phone', isEqualTo: normalizedPhone)
        .limit(1)
        .get();
    if (addressMatch.docs.isNotEmpty) {
      return addressMatch.docs.first;
    }

    return null;
  }

  static Future<bool> isSignedIn() async {
    return _auth.currentUser != null;
  }

  static Future<void> hydrateCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      AuthUserStore.clear();
      return;
    }

    final normalizedEmail = (user.email ?? '').trim().toLowerCase();
    final userDocRef = _firestore.collection('users').doc(user.uid);

    try {
      final userDoc = await userDocRef.get();

      String profileRole = 'user';
      String profileUsername = user.displayName?.trim() ?? '';
      String profileEmail = normalizedEmail;
      String profilePhoneNumber = '';

      if (userDoc.exists) {
        final data = userDoc.data() ?? <String, dynamic>{};
        final roleValue = data['role']?.toString().trim().toLowerCase();
        final nameValue = data['username']?.toString().trim();
        final emailValue = data['email']?.toString().trim().toLowerCase();
        final phoneValue = data['phoneNumber']?.toString().trim();

        if (roleValue != null && roleValue.isNotEmpty) {
          profileRole = roleValue;
        }
        if (nameValue != null && nameValue.isNotEmpty) {
          profileUsername = nameValue;
        }
        if (emailValue != null && emailValue.isNotEmpty) {
          profileEmail = emailValue;
        }
        if (phoneValue != null && phoneValue.isNotEmpty) {
          profilePhoneNumber = phoneValue;
        }
      } else {
        final isAdminIdentity = normalizedEmail == _fixedAdminEmail;
        if (isAdminIdentity) {
          await userDocRef.set({
            'username': _fixedAdminUsername,
            'email': _fixedAdminEmail,
            'phoneNumber': adminPhoneNumber,
            'role': 'admin',
            'updatedAt': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          profileRole = 'admin';
          profileUsername = _fixedAdminUsername;
          profileEmail = _fixedAdminEmail;
          profilePhoneNumber = adminPhoneNumber;
        } else {
          if (profileUsername.isEmpty) {
            profileUsername = (normalizedEmail.isNotEmpty
                    ? normalizedEmail.split('@').first
                    : 'User')
                .trim();
          }

          await userDocRef.set({
            'username': profileUsername,
            'email': normalizedEmail,
            'phoneNumber': '',
            'role': 'user',
            'updatedAt': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }

      final isAdminIdentity = normalizedEmail == _fixedAdminEmail;
      if (isAdminIdentity && (profileRole != 'admin')) {
        await userDocRef.set({
          'username': _fixedAdminUsername,
          'email': _fixedAdminEmail,
          'phoneNumber': adminPhoneNumber,
          'role': 'admin',
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        profileRole = 'admin';
        profileUsername = _fixedAdminUsername;
        profileEmail = _fixedAdminEmail;
        profilePhoneNumber = adminPhoneNumber;
      }

      AuthUserStore.username = profileUsername.isNotEmpty
          ? profileUsername
          : (normalizedEmail.isNotEmpty ? normalizedEmail.split('@').first : '');
      AuthUserStore.email = profileEmail.isNotEmpty ? profileEmail : normalizedEmail;
      AuthUserStore.phoneNumber = profilePhoneNumber;
      AuthUserStore.role = profileRole;
    } on FirebaseException catch (_) {
      // If offline, still treat the Firebase user as signed-in and use
      // best-effort defaults until Firestore becomes available.
      final isAdminIdentity = normalizedEmail == _fixedAdminEmail;
      AuthUserStore.username = user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : (isAdminIdentity ? _fixedAdminUsername : normalizedEmail.split('@').first);
      AuthUserStore.email = normalizedEmail;
      AuthUserStore.phoneNumber = isAdminIdentity ? adminPhoneNumber : null;
      AuthUserStore.role = isAdminIdentity ? 'admin' : 'user';
    } catch (_) {
      // Keep the session but avoid crashing the app on startup.
      final isAdminIdentity = normalizedEmail == _fixedAdminEmail;
      AuthUserStore.username = user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : (isAdminIdentity ? _fixedAdminUsername : normalizedEmail.split('@').first);
      AuthUserStore.email = normalizedEmail;
      AuthUserStore.phoneNumber = isAdminIdentity ? adminPhoneNumber : null;
      AuthUserStore.role = isAdminIdentity ? 'admin' : 'user';
    }
  }

  static Future<void> registerUser({
    required String username,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    final cleanUsername = username.trim();
    final cleanEmail = email.trim();
    final normalizedEmail = cleanEmail.toLowerCase();
    final normalizedPhone = _normalizePhoneNumber(phoneNumber);

    if (normalizedEmail == _fixedAdminEmail) {
      throw const AuthException(
        'admin@gmail.com is reserved for Admin Login only.',
      );
    }

    if (cleanUsername.toLowerCase() == _fixedAdminUsername.toLowerCase()) {
      throw const AuthException(
        'Admin username is reserved and cannot be used for user registration.',
      );
    }

    if (normalizedPhone.length != 10) {
      throw const AuthException('Please enter a valid 10-digit phone number.');
    }

    if (normalizedPhone == adminPhoneNumber) {
      throw const AuthException(
        '1234567890 is reserved for Admin Login only.',
      );
    }

    final existingUserByPhone = await _findUserByPhoneNumber(normalizedPhone);
    if (existingUserByPhone != null) {
      throw const AuthException('This phone number is already registered.');
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const AuthException(
          'Unable to create account. Please try again.',
        );
      }

      await _firestore.collection('users').doc(user.uid).set({
        'username': cleanUsername,
        'email': normalizedEmail,
        'phoneNumber': normalizedPhone,
        'role': 'user',
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await user.updateDisplayName(cleanUsername);
      AuthUserStore.username = cleanUsername;
      AuthUserStore.email = normalizedEmail;
      AuthUserStore.phoneNumber = normalizedPhone;
      AuthUserStore.role = 'user';
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (error) {
      throw AuthException(_firebaseAuthMessage(error));
    } on FirebaseException catch (_) {
      throw const AuthException(
        'Database error while saving your profile. Please try again.',
      );
    } catch (_) {
      throw const AuthException(
        'Auth service is not available on this platform.',
      );
    }
  }

  static Future<void> login({
    required String phoneNumber,
    required String password,
  }) async {
    final normalizedPhone = _normalizePhoneNumber(phoneNumber);
    if (normalizedPhone.length != 10) {
      throw const AuthException('Please enter a valid 10-digit phone number.');
    }

    String normalizedEmail;
    if (normalizedPhone == adminPhoneNumber) {
      normalizedEmail = _fixedAdminEmail;
    } else {
      final matchedUser = await _findUserByPhoneNumber(normalizedPhone);
      if (matchedUser == null) {
        throw const AuthException('Invalid phone number or password.');
      }
      final matchedEmail = matchedUser.data()['email']?.toString().trim().toLowerCase() ?? '';
      if (matchedEmail.isEmpty) {
        throw const AuthException('This account is missing an email record.');
      }
      normalizedEmail = matchedEmail;
    }
    final cleanEmail = normalizedEmail;

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const AuthException('Login failed. Please try again.');
      }

      final userDocRef = _firestore.collection('users').doc(user.uid);
      final userDoc = await userDocRef.get();

      String profileRole = 'user';
      String profileUsername = user.displayName?.trim() ?? '';
      String profileEmail = normalizedEmail;
      String profilePhoneNumber = normalizedPhone;
      bool hasDbUsername = false;
      bool hasDbEmail = false;

      if (userDoc.exists) {
        final data = userDoc.data() ?? <String, dynamic>{};
        final roleValue = data['role']?.toString().trim().toLowerCase();
        final nameValue = data['username']?.toString().trim();
        final emailValue = data['email']?.toString().trim().toLowerCase();
        final phoneValue = data['phoneNumber']?.toString().trim();

        if (roleValue != null && roleValue.isNotEmpty) {
          profileRole = roleValue;
        }
        if (nameValue != null && nameValue.isNotEmpty) {
          profileUsername = nameValue;
          hasDbUsername = true;
        }
        if (emailValue != null && emailValue.isNotEmpty) {
          profileEmail = emailValue;
          hasDbEmail = true;
        }
        if (phoneValue != null && phoneValue.isNotEmpty) {
          profilePhoneNumber = phoneValue;
        }
      } else {
        final isAdminIdentity = normalizedEmail == _fixedAdminEmail;

        if (isAdminIdentity) {
          // Bootstrap admin profile document when account exists in Auth
          // but the Firestore profile is missing.
          await userDocRef.set({
            'username': _fixedAdminUsername,
            'email': _fixedAdminEmail,
            'phoneNumber': adminPhoneNumber,
            'role': 'admin',
            'updatedAt': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          profileRole = 'admin';
          profileUsername = _fixedAdminUsername;
          profileEmail = _fixedAdminEmail;
          profilePhoneNumber = adminPhoneNumber;
          hasDbUsername = true;
          hasDbEmail = true;
        } else {
          if (profileUsername.isEmpty) {
            profileUsername = cleanEmail.split('@').first;
          }

          await userDocRef.set({
            'username': profileUsername,
            'email': normalizedEmail,
            'phoneNumber': normalizedPhone,
            'role': 'user',
            'updatedAt': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }

      final isAdminIdentityValid = normalizedEmail == _fixedAdminEmail;

      if (isAdminIdentityValid &&
          (profileRole != 'admin' ||
              !hasDbUsername ||
              !_equalsIgnoreCase(profileUsername, _fixedAdminUsername) ||
              !hasDbEmail ||
              profileEmail != _fixedAdminEmail)) {
        // Heal existing mismatched admin profile to avoid configuration errors.
        await userDocRef.set({
          'username': _fixedAdminUsername,
          'email': _fixedAdminEmail,
          'phoneNumber': adminPhoneNumber,
          'role': 'admin',
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        profileRole = 'admin';
        profileUsername = _fixedAdminUsername;
        profileEmail = _fixedAdminEmail;
        profilePhoneNumber = adminPhoneNumber;
        hasDbUsername = true;
        hasDbEmail = true;
      }

      AuthUserStore.username = profileUsername.isNotEmpty
          ? profileUsername
          : cleanEmail.split('@').first;
      AuthUserStore.email = normalizedEmail;
      AuthUserStore.phoneNumber = profilePhoneNumber;
      AuthUserStore.role = profileRole;
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (error) {
      throw AuthException(_firebaseAuthMessage(error));
    } on FirebaseException catch (_) {
      throw const AuthException(
        'Database read failed. Please check your connection and try again.',
      );
    } catch (_) {
      throw const AuthException(
        'Auth service is not available on this platform.',
      );
    }
  }

  static Future<void> logout() async {
    AuthUserStore.clear();
    await _auth.signOut();
  }

  static Future<void> sendPasswordResetEmail({required String email}) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      throw const AuthException('Please enter your email address.');
    }

    try {
      await _auth.sendPasswordResetEmail(email: normalizedEmail);
    } on FirebaseAuthException catch (error) {
      throw AuthException(_firebaseAuthMessage(error));
    } catch (_) {
      throw const AuthException(
        'Auth service is not available on this platform.',
      );
    }
  }

  static String _firebaseAuthMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'missing-email':
        return 'Please enter your email address.';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Invalid phone number or password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your internet and try again.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }
}
