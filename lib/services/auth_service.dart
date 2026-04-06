import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class AuthService {
  static const _webClientId =
      '598135360819-e2g2ove1rctlvf3fdj9ku3ju01fb3nnt.apps.googleusercontent.com';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? _webClientId : null,
    serverClientId: kIsWeb ? null : _webClientId,
  );

  Stream<User?> get user => _auth.authStateChanges();

  Future<UserCredential?> signInWithGoogle() async {
    try {
      GoogleSignInAccount? googleUser;
      
      if (kIsWeb) {
        googleUser = await googleSignIn.signInSilently() ?? await googleSignIn.signIn();
      } else {
        googleUser = await googleSignIn.signIn();
      }

      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      
      // Create or update user profile with username
      if (userCredential.user != null) {
        await _createOrUpdateUserProfile(userCredential.user!);
      }
      
      return userCredential;
    } catch (e) {
      print("Error signing in with Google: $e");
      return null;
    }
  }

  Future<void> _createOrUpdateUserProfile(User user) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await userDoc.get();
    
    if (!docSnapshot.exists) {
      // New user - generate username
      String baseUsername = UserProfile.generateUsername(user.displayName ?? user.email ?? 'user');
      String username = await _getUniqueUsername(baseUsername);
      
      final profile = UserProfile(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? 'User',
        username: username,
        photoURL: user.photoURL,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await userDoc.set(profile.toJson());
      
      // Also store username mapping for quick lookup
      await _firestore.collection('usernames').doc(username).set({
        'uid': user.uid,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } else {
      // Existing user - just update timestamp
      await userDoc.update({
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<String> _getUniqueUsername(String baseUsername) async {
    String username = baseUsername;
    int suffix = 1;
    
    while (await _usernameExists(username)) {
      username = '$baseUsername$suffix';
      suffix++;
    }
    
    return username;
  }

  Future<bool> _usernameExists(String username) async {
    final doc = await _firestore.collection('usernames').doc(username).get();
    return doc.exists;
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserProfile.fromJson(doc.data()!);
      }
    } catch (e) {
      print("Error fetching user profile: $e");
    }
    return null;
  }

  Future<UserProfile?> getUserProfileByUsername(String username) async {
    try {
      final usernameDoc = await _firestore.collection('usernames').doc(username).get();
      if (usernameDoc.exists) {
        final uid = usernameDoc.data()!['uid'];
        return getUserProfile(uid);
      }
    } catch (e) {
      print("Error fetching user by username: $e");
    }
    return null;
  }

  Future<void> signOut() async {
    await googleSignIn.signOut();
    await _auth.signOut();
  }
}
