import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user_profile.dart';
import '../../../models/user_preferences.dart';
import '../../../services/firestore_service.dart';
import '../../auth/providers/auth_provider.dart';

final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService.instance);

final preferencesFutureProvider = FutureProvider<UserPreferences?>((ref) async {
  final uid = ref.watch(authUserIdProvider);
  if (uid == null) return null;
  return FirestoreService.instance.getPreferences(uid);
});

Future<void> savePreferences(
    WidgetRef ref, String uid, UserPreferences prefs) async {
  await FirestoreService.instance.savePreferences(uid, prefs);
  ref.invalidate(preferencesFutureProvider);
}

Future<void> saveProfile(WidgetRef ref, UserProfile profile) async {
  await FirestoreService.instance.saveProfile(profile);
  ref.invalidate(profileFutureProvider);
}
