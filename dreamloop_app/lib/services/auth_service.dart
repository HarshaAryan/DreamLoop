import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// AuthService — manages user authentication state.
/// Provides actual Firebase Auth implementation.

class AuthService extends ChangeNotifier {
  String? _userId;
  String? _displayName;
  String? _authProvider;
  String _relationshipType = '';
  Map<String, dynamic> _characterCustomization = {};
  bool _isLoading = false;

  String? get userId => _userId ?? FirebaseAuth.instance.currentUser?.uid;
  String? get displayName =>
      _displayName ?? FirebaseAuth.instance.currentUser?.displayName;
  String? get authProvider => _authProvider;
  String get relationshipType => _relationshipType;
  Map<String, dynamic> get characterCustomization => _characterCustomization;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => FirebaseAuth.instance.currentUser != null;

  AuthService() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _userId = user.uid;
        _displayName = user.displayName;
      } else {
        _userId = null;
        _displayName = null;
      }
      notifyListeners();
    });
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn(
        scopes: ['email'],
      ).signIn();
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      _userId = userCredential.user?.uid;
      _displayName = userCredential.user?.displayName ?? 'DreamLoop Explorer';
      _authProvider = 'google';

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Google sign-in error: $e');
      return false;
    }
  }

  /// Sign in with Apple
  Future<bool> signInWithApple() async {
    _isLoading = true;
    notifyListeners();

    try {
      final AuthorizationCredentialAppleID appleCredential =
          await SignInWithApple.getAppleIDCredential(
            scopes: [
              AppleIDAuthorizationScopes.email,
              AppleIDAuthorizationScopes.fullName,
            ],
          );

      final OAuthProvider oauthProvider = OAuthProvider('apple.com');
      final OAuthCredential credential = oauthProvider.credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      _userId = userCredential.user?.uid;
      _displayName =
          userCredential.user?.displayName ??
          (appleCredential.givenName != null
              ? '${appleCredential.givenName} ${appleCredential.familyName}'
              : 'DreamLoop Dreamer');
      _authProvider = 'apple';

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Apple sign-in error: $e');
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
    _userId = null;
    _displayName = null;
    _authProvider = null;
    _relationshipType = '';
    _characterCustomization = {};
    notifyListeners();
  }

  void setRelationshipType(String relationshipType) {
    _relationshipType = relationshipType;
    notifyListeners();
  }

  void setCharacterCustomization(Map<String, dynamic> customization) {
    _characterCustomization = customization;
    notifyListeners();
  }
}
