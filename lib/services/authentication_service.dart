import 'package:bookmark/utilities/helper_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthenticationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleInitialized = false;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> _createUserDocument(User user, {String? email}) async {
    final userEmail = email ?? user.email ?? '';

    final userDoc = _firestore.collection('users').doc(user.uid);
    final snapshot = await userDoc.get();

    if (!snapshot.exists) {
      await userDoc.set({
        'uid': user.uid,
        'email': userEmail,
        'name': user.displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'sets': {},
        'library': {},
      });
    } else {
      await userDoc.update({'lastLoginAt': FieldValue.serverTimestamp()});
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password is too weak.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'invalid-credential':
        return 'Invalid credentials.';
      default:
        return 'Authentication failed.';
    }
  }

  Future<User?> signUpWithEmail(
    String email,
    String password,
    BuildContext context,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      await _createUserDocument(credential.user!, email: email.trim());
      return credential.user;
    } on FirebaseAuthException catch (e) {
      displayErrorToUser(_handleAuthException(e), context);
      return null;
    }
  }

  Future<User?> signInWithEmail(
    String email,
    String password,
    BuildContext context,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      await _createUserDocument(credential.user!, email: email.trim());
      Navigator.pushNamed(context, "/app");
      return credential.user;
    } on FirebaseAuthException catch (e) {
      displayErrorToUser(_handleAuthException(e), context);
      return null;
    }
  }

  Future<User?> signInAnonymously() async {
    final credential = await _auth.signInAnonymously();
    await _createUserDocument(credential.user!);
    return credential.user;
  }

  Future<User?> linkAnonymousToEmailPassword(
    String email,
    String password,
  ) async {
    if (currentUser == null || !currentUser!.isAnonymous) {
      throw Exception('No anonymous user.');
    }

    final credential = EmailAuthProvider.credential(
      email: email.trim(),
      password: password.trim(),
    );

    final result = await currentUser!.linkWithCredential(credential);
    await _firestore.collection('users').doc(result.user!.uid).update({
      'email': email.trim(),
    });

    return result.user;
  }

  Future<void> _initGoogle() async {
    if (!_googleInitialized) {
      await _googleSignIn.initialize();
      _googleInitialized = true;
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        final credential = await _auth.signInWithPopup(provider);

        await _createUserDocument(credential.user!);
        Navigator.pushNamed(context, "/app");
        return;
      }

      await _initGoogle();

      final googleUser = await _googleSignIn.authenticate(scopeHint: ['email']);

      final auth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(idToken: auth.idToken);

      final userCredential = await _auth.signInWithCredential(credential);

      await _createUserDocument(userCredential.user!);
      Navigator.pushNamed(context, "/app");
    } catch (e) {
      displayErrorToUser("Google Sign-In failed: $e", context);
    }
  }

  Future<void> signOut(BuildContext context) async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    Navigator.pushNamed(context, '/');
  }

  Future<void> deleteAccount() async {
    final uid = currentUser?.uid;
    if (uid == null) return;

    await currentUser!.delete();
    await _firestore.collection('users').doc(uid).delete();
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  Future<bool> isCurrentUserBCA() async {
    if (currentUser == null) return false;
    final data = await getUserData(currentUser!.uid);
    return data?['isBCA'] ?? false;
  }

  Future<void> sendPasswordResetEmail(
    String email,
    BuildContext context,
  ) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      displayErrorToUser(
        "Sent the email to ${email}, if you can not see it, check spam/junk",
        context,
      );
    } on FirebaseAuthException catch (e) {
      displayErrorToUser(_handleAuthException(e), context);
    } catch (e) {
      displayErrorToUser('Failed to send password reset email.', context);
    }
  }
}
