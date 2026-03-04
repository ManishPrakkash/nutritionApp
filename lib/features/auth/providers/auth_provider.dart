import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/user_profile.dart';
import '../../../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService.instance);

final authStateProvider = StreamProvider<User?>((ref) {
  return AuthService.instance.authStateChanges;
});

final authUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.uid;
});

final profileFutureProvider = FutureProvider<UserProfile?>((ref) async {
  final uid = ref.watch(authUserIdProvider);
  if (uid == null) return null;
  return AuthService.instance.getProfile();
});

final profileProvider = Provider<AsyncValue<UserProfile?>>((ref) {
  return ref.watch(profileFutureProvider);
});

Future<void> signUpWithEmail(WidgetRef ref, String email, String password,
    UserProfile profile, [Object? imageFile]) async {
  final cred = await AuthService.instance.signUpWithEmail(email, password);
  if (cred?.user == null) return;
  final updatedProfile = profile.copyWith(uid: cred!.user!.uid);
  await AuthService.instance.createProfileAfterSignUp(updatedProfile, imageFile);
}

Future<void> signInWithEmail(WidgetRef ref, String email, String password) async {
  await AuthService.instance.signInWithEmail(email, password);
}

Future<void> signOut(WidgetRef ref) async {
  await AuthService.instance.signOut();
}

Future<void> sendPasswordReset(WidgetRef ref, String email) async {
  await AuthService.instance.sendPasswordResetEmail(email);
}
