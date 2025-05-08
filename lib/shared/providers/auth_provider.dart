import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final authProvider = StateNotifierProvider<AuthNotifier, bool>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<bool> {
  AuthNotifier() : super(false) {
    _listenAuthChanges();
  }

  final _auth = FirebaseAuth.instance;

  void _listenAuthChanges() {
    _auth.authStateChanges().listen((user) {
      state = user != null;
    });
  }

  /// Signup with email and password
  Future<void> signup(String email, String password, String name) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save additional user data in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
            'name': name,
            'email': email,
            'createdAt': FieldValue.serverTimestamp(),
          });

      // no need to manually set state; listener handles it
    } catch (e) {
      rethrow;
    }
  }

  /// Login with email and password
  Future<void> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // state handled by listener
    } catch (e) {
      rethrow;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
      // state handled by listener
    } catch (e) {
      rethrow;
    }
  }
}
