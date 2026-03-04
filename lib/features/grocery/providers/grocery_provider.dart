import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/api_service.dart';
import '../../../services/firestore_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';

/// Raw category from API: {category, items: [{name, quantity, price}]}
class GroceryCategory {
  final String name;
  final List<Map<String, dynamic>> items;

  const GroceryCategory({required this.name, required this.items});
}

final groceryListProvider = FutureProvider.family<List<GroceryCategory>, String>((ref, period) async {
  final uid = ref.watch(authUserIdProvider);
  if (uid == null) return [];
  final profile = await ref.watch(profileFutureProvider.future);
  final prefs = await ref.watch(preferencesFutureProvider.future);
  final budget = 'medium';
  final people = 2;
  final list = await ApiService.instance.getGroceryList(
    uid,
    period: period,
    budget: budget,
    people: people,
    profile: profile,
    prefs: prefs,
  );
  return list.map((e) {
    final items = (e['items'] as List<dynamic>?)
        ?.map((i) => {
              'name': i['name'],
              'qty': i['quantity'] ?? i['qty'] ?? '—',
              'price': i['price'] ?? 0,
              'checked': false,
            })
        .toList() ?? [];
    return GroceryCategory(
      name: e['category'] as String? ?? 'Items',
      items: List<Map<String, dynamic>>.from(items),
    );
  }).toList();
});
