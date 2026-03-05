import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_nutrition_app/core/icons/lucide_fallback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../../bmi/screens/bmi_screen.dart';
import '../../streaks/screens/streaks_screen.dart';
import '../../home/services/streak_service.dart';
import 'device_screen.dart';
import '../../lifestyle/screens/lifestyle_screen.dart';
import 'profile_setup_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final currentStreakAsync = ref.watch(currentStreakProvider);
    final streakLabel = currentStreakAsync.when(
      data: (streak) => '$streak Days',
      loading: () => '—',
      error: (_, __) => '0 Days',
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Identity Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: premiumCardDecoration(),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 56,
                      backgroundColor: AppColors.background,
                      backgroundImage: profile?.photoUrl != null
                          ? NetworkImage(profile!.photoUrl!)
                          : null,
                      child: profile?.photoUrl == null
                          ? const Icon(LucideIcons.user, size: 48, color: AppColors.primary)
                          : null,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      profile?.fullName ?? 'Distinguished User',
                      style: AppTypography.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile?.email ?? '',
                      style: AppTypography.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _StatusBadge(
                          icon: LucideIcons.activity,
                          label: 'BMI: ${profile?.calculatedBmi.toStringAsFixed(1) ?? "—"}',
                        ),
                        const SizedBox(width: 12),
                        _StatusBadge(
                          icon: LucideIcons.flame,
                          label: streakLabel,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _ProfileSection(
                title: 'Personal Metrics',
                children: [
                  _ProfileTile(
                    label: 'Name',
                    value: profile?.fullName ?? '—',
                    icon: LucideIcons.user,
                  ),
                  _ProfileTile(
                    label: 'Age',
                    value: '${profile?.age ?? "—"} Years',
                    icon: LucideIcons.calendar,
                  ),
                  _ProfileTile(
                    label: 'Height',
                    value: '${profile?.heightCm ?? "—"} cm',
                    icon: LucideIcons.ruler,
                  ),
                  _ProfileTile(
                    label: 'Weight',
                    value: '${profile?.weightKg ?? "—"} kg',
                    icon: LucideIcons.package,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _ActionSection(
                title: 'Profile',
                children: [
                  _LinkTile(
                    label: 'Edit preferences',
                    icon: LucideIcons.settings,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ProfileSetupScreen(editMode: true, stepsGoal: 10000),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _ActionSection(
                title: 'Analytics & Rewards',
                children: [
                  _LinkTile(
                    label: 'Health Calculator',
                    icon: LucideIcons.calculator,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BmiScreen()),
                    ),
                  ),
                  _LinkTile(
                    label: 'Consistency Streaks',
                    icon: LucideIcons.flame,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const StreaksScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _ActionSection(
                title: 'Ecosystem',
                children: [
                  _LinkTile(
                    label: 'Device Integration',
                    icon: LucideIcons.smartphone,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DeviceScreen()),
                    ),
                  ),
                  _LinkTile(
                    label: 'Lifestyle Guide',
                    icon: LucideIcons.heart,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LifestyleScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              TextButton.icon(
                onPressed: () async {
                  await signOut(ref);
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(LucideIcons.logOut, size: 16),
                label: const Text('Logout'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatusBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            label, 
            style: AppTypography.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ProfileSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: AppTypography.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: premiumCardDecoration(),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: children.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
            itemBuilder: (_, index) => children[index],
          ),
        ),
      ],
    );
  }
}

class _ActionSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ActionSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: AppTypography.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: premiumCardDecoration(),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: children.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
            itemBuilder: (_, index) => children[index],
          ),
        ),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ProfileTile({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textMuted),
          const SizedBox(width: 16),
          Text(label, style: AppTypography.textTheme.bodyMedium),
          const Spacer(),
          Text(
            value, 
            style: AppTypography.textTheme.titleSmall?.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _LinkTile({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textMuted),
            const SizedBox(width: 16),
            Text(label, style: AppTypography.textTheme.bodyMedium),
            const Spacer(),
            const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
