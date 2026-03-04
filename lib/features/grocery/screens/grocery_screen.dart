import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_nutrition_app/core/icons/lucide_fallback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/grocery_provider.dart';

class GroceryScreen extends ConsumerStatefulWidget {
  const GroceryScreen({super.key});

  @override
  ConsumerState<GroceryScreen> createState() => _GroceryScreenState();
}

class _GroceryScreenState extends ConsumerState<GroceryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Provision Logic'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: AppColors.surface,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textMuted,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: 'Daily'),
                  Tab(text: 'Weekly'),
                  Tab(text: 'Monthly'),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _GroceryListView(period: 'day'),
                  _GroceryListView(period: 'week'),
                  _GroceryListView(period: 'month'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroceryListView extends ConsumerStatefulWidget {
  final String period;
  const _GroceryListView({required this.period});

  @override
  ConsumerState<_GroceryListView> createState() => _GroceryListViewState();
}

class _GroceryListViewState extends ConsumerState<_GroceryListView> {
  final Set<String> _selectedItems = {};

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(groceryListProvider(widget.period));
    return async.when(
      data: (categories) {
        if (categories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.shoppingCart, size: 48, color: AppColors.textMuted),
                const SizedBox(height: 16),
                Text('No items for ${widget.period == "day" ? "daily" : widget.period == "week" ? "weekly" : "monthly"} list', style: AppTypography.textTheme.bodyMedium),
              ],
            ),
          );
        }
        int totalPrice = 0;
        for (final c in categories) {
          for (final i in c.items) {
            final name = i['name'] as String? ?? '—';
            final itemId = '${c.name}_$name';
            if (!_selectedItems.contains(itemId)) {
              totalPrice += (i['price'] as num?)?.toInt() ?? 0;
            }
          }
        }
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            ...categories.asMap().entries.map((entry) {
              final catIdx = entry.key;
              final cat = entry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.leaf, size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      Text(
                        cat.name.toUpperCase(),
                        style: AppTypography.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...cat.items.asMap().entries.map((e) {
                    final item = e.value;
                    final itemIdx = e.key;
                    final name = item['name'] as String? ?? '—';
                    final qty = item['qty'] as String? ?? '—';
                    final price = (item['price'] as num?)?.toInt() ?? 0;
                    final itemId = '${cat.name}_$name';
                    final isSelected = _selectedItems.contains(itemId);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedItems.remove(itemId);
                            } else {
                              _selectedItems.add(itemId);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary.withOpacity(0.05) : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
                                color: isSelected ? AppColors.primary : AppColors.border,
                                size: 20
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: AppTypography.textTheme.bodyMedium?.copyWith(
                                        decoration: isSelected ? TextDecoration.lineThrough : null,
                                        color: isSelected ? AppColors.textMuted : AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(qty, style: AppTypography.textTheme.bodySmall),
                                  ],
                                ),
                              ),
                              Text(
                                '₹$price',
                                style: AppTypography.textTheme.titleSmall?.copyWith(
                                  color: isSelected ? AppColors.textMuted : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                ],
              );
            }),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: premiumCardDecoration(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Estimated total', style: AppTypography.textTheme.titleSmall),
                      Text('${widget.period == "day" ? "Daily" : widget.period == "week" ? "Weekly" : "Monthly"} list', style: AppTypography.textTheme.bodySmall),
                    ],
                  ),
                  Text('₹$totalPrice', style: AppTypography.textTheme.headlineSmall),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (_, __) => Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Could not load grocery list'),
          TextButton(onPressed: () => ref.invalidate(groceryListProvider(widget.period)), child: const Text('Retry')),
        ],
      )),
    );
  }
}
