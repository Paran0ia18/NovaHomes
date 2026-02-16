import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'firestore_service.dart';

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    FirestoreService? firestoreService,
  }) : _authOverride = auth,
       _googleSignInOverride = googleSignIn,
       _firestoreService = firestoreService ?? FirestoreService();

  final FirebaseAuth? _authOverride;
  final GoogleSignIn? _googleSignInOverride;
  GoogleSignIn? _googleSignInInstance;
  final FirestoreService _firestoreService;

  GoogleSignIn get _googleSignIn {
    return _googleSignInOverride ??
        (_googleSignInInstance ??= GoogleSignIn(scopes: <String>['email']));
  }

  FirebaseAuth get _auth {
    if (_authOverride != null) return _authOverride;
    if (Firebase.apps.isEmpty) {
      throw Exception(
        'Firebase is not configured. Run flutterfire configure first.',
      );
    }
    return FirebaseAuth.instance;
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final UserCredential credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    if (credential.user != null) {
      await _firestoreService.upsertUserProfile(credential.user!);
    }
    return credential;
  }

  Future<UserCredential> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final UserCredential credential = await _auth
        .createUserWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );
    final User? user = credential.user;
    if (user != null && name.trim().isNotEmpty) {
      await user.updateDisplayName(name.trim());
      await user.reload();
    }
    final User? refreshed = _auth.currentUser;
    if (refreshed != null) {
      await _firestoreService.upsertUserProfile(refreshed, fallbackName: name);
    }
    return credential;
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'aborted-by-user',
          message: 'Google sign-in was cancelled.',
        );
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      if (googleAuth.idToken == null || googleAuth.idToken!.isEmpty) {
        throw FirebaseAuthException(
          code: 'google-missing-id-token',
          message:
              'Google Sign-In is not fully configured. Add SHA-1/SHA-256 in Firebase and download google-services.json again.',
        );
      }

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      if (userCredential.user != null) {
        await _firestoreService.upsertUserProfile(userCredential.user!);
      }
      return userCredential;
    } on PlatformException catch (error) {
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: error.message ?? 'Google Sign-In failed.',
      );
    }
  }

  Future<UserCredential> signInWithApple() async {
    final bool isAvailable = await SignInWithApple.isAvailable();
    if (!isAvailable) {
      throw FirebaseAuthException(
        code: 'apple-not-supported',
        message: 'Apple Sign-In is only available on compatible Apple devices.',
      );
    }

    final String rawNonce = _generateNonce();
    final String nonce = _sha256ofString(rawNonce);

    final AuthorizationCredentialAppleID appleCredential =
        await SignInWithApple.getAppleIDCredential(
          scopes: <AppleIDAuthorizationScopes>[
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: nonce,
        );

    final OAuthCredential oauthCredential = OAuthProvider(
      'apple.com',
    ).credential(idToken: appleCredential.identityToken, rawNonce: rawNonce);

    final UserCredential userCredential = await _auth.signInWithCredential(
      oauthCredential,
    );

    final User? user = userCredential.user;
    if (user != null) {
      final String fullName = <String>[
        appleCredential.givenName ?? '',
        appleCredential.familyName ?? '',
      ].where((String part) => part.trim().isNotEmpty).join(' ');

      if ((user.displayName?.isEmpty ?? true) && fullName.isNotEmpty) {
        await user.updateDisplayName(fullName);
        await user.reload();
      }
      await _firestoreService.upsertUserProfile(
        _auth.currentUser ?? user,
        fallbackName: fullName,
      );
    }
    return userCredential;
  }

  Future<void> signOut() async {
    final List<Future<void>> tasks = <Future<void>>[_auth.signOut()];
    final GoogleSignIn? googleClient =
        _googleSignInOverride ?? _googleSignInInstance;
    if (googleClient != null) {
      tasks.add(googleClient.signOut());
    }
    await Future.wait<void>(tasks);
  }

  Future<void> updateProfilePhotoUrl(String? photoUrl) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated.');
    }
    final String normalized = photoUrl?.trim() ?? '';
    String? finalUrl;
    if (normalized.isNotEmpty) {
      final Uri? uri = Uri.tryParse(normalized);
      final bool valid =
          uri != null &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty &&
          _isSupportedProfileImagePath(uri.path);
      if (!valid) {
        throw Exception(
          'Use a direct .jpg/.jpeg/.webp image URL with http/https.',
        );
      }
      finalUrl = normalized;
    }

    await _firestoreService.upsertUserProfileFields(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : (user.email ?? 'Guest'),
      photoUrl: finalUrl ?? '',
    );
  }

  Future<void> updateDisplayName(String displayName) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated.');
    }
    final String normalized = displayName.trim();
    if (normalized.isEmpty) return;
    await user.updateDisplayName(normalized);
    await user.reload();
    final User? refreshed = _auth.currentUser;
    if (refreshed != null) {
      await _firestoreService.upsertUserProfile(
        refreshed,
        fallbackName: normalized,
      );
    }
  }

  String _generateNonce([int length = 32]) {
    const String charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final Random random = Random.secure();
    return List<String>.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final List<int> bytes = utf8.encode(input);
    final Digest digest = sha256.convert(bytes);
    return digest.toString();
  }

  bool _isSupportedProfileImagePath(String path) {
    final String lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
  }
}
