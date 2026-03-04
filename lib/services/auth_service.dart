import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import 'firestore_service.dart';

class AuthService {
  AuthService._();
  static final AuthService _instance = AuthService._();
  static AuthService get instance => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestore = FirestoreService.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Waits for the first auth state (e.g. after app cold start). Use in splash to avoid routing before Firebase restores session.
  Future<User?> get firstAuthState => _auth.authStateChanges().first;

  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
        email: email, password: password);
  }


  Future<void> signOut() async {
    // Clear setup completion flag when user logs out
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('setup_completed');
    await prefs.remove('user_uid');
    
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> createProfileAfterSignUp(UserProfile profile,
      [Object? imageFile]) async {
    // Profile photo upload removed; save profile only
    try {
      await _firestore.saveProfile(profile);
    } catch (e) {
      throw Exception('Profile could not be saved. ${e.toString()}');
    }
  }

  Future<UserProfile?> getProfile() async {
    final uid = currentUser?.uid;
    if (uid == null) return null;
    return await _firestore.getProfile(uid);
  }
}
