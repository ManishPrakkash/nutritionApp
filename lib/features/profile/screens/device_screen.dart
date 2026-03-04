import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_nutrition_app/core/icons/lucide_fallback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/health_service.dart';
import '../../../services/firestore_service.dart';
import '../../auth/providers/auth_provider.dart';

class DeviceScreen extends ConsumerStatefulWidget {
  const DeviceScreen({super.key});

  @override
  ConsumerState<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends ConsumerState<DeviceScreen> {
  bool _googleFitConnected = false;
  String _syncFrequency = 'Hourly';
  String _lastSync = 'Never';
  String _metrics = '—';
  bool _syncing = false;

  void _showNoPermissionMessage() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Can't connect to device – this build has no permission to connect."),
      ),
    );
  }

  Future<void> _syncToFirestore() async {
    final uid = ref.read(authUserIdProvider);
    if (uid == null) return;
    setState(() => _syncing = true);
    try {
      final now = DateTime.now();
      final today = now.toIso8601String().split('T').first;
      final start = DateTime(now.year, now.month, now.day);
      final end = now;
      final steps = await HealthService.instance.getSteps(start, end);
      final sleep = await HealthService.instance.getSleepHours(start, end);
      final heartRate = await HealthService.instance.getLastHeartRate();
      final burned = await HealthService.instance.getCaloriesBurned(start, end);
      await FirestoreService.instance.saveDeviceData(
        uid,
        today,
        steps: steps,
        heartRateBpm: heartRate,
        sleepHours: sleep > 0 ? sleep : null,
        caloriesBurned: burned > 0 ? burned : null,
      );
      if (mounted) {
        setState(() {
          _lastSync = 'Just now';
          _metrics = 'Steps: $steps | Sleep: ${sleep.toStringAsFixed(1)}h';
          if (heartRate != null) _metrics += ' | HR: $heartRate';
        });
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sync failed')),
      );
    }
    if (mounted) setState(() => _syncing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Device Ecosystem'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DeviceIntegrationCard(
                title: 'Google Fit',
                icon: LucideIcons.smartphone,
                isConnected: _googleFitConnected,
                lastSync: _lastSync,
                metrics: _metrics,
                syncing: _syncing,
                onToggle: () async {
                  // Dummy integration: always show no-permission message
                  _showNoPermissionMessage();
                },
                onSync: () {
                  // Dummy integration: always show no-permission message
                  _showNoPermissionMessage();
                },
              ),
              const SizedBox(height: 20),
              _DeviceIntegrationCard(
                title: 'Apple Health',
                icon: LucideIcons.watch,
                isConnected: false,
                onToggle: _showNoPermissionMessage,
              ),
              const SizedBox(height: 48),
              Text(
                'Synchronization Protocol',
                style: AppTypography.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Define the frequency of biometric data ingestion.',
                style: AppTypography.textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              Container(
                decoration: premiumCardDecoration(),
                child: Column(
                  children: ['Real-time', 'Hourly', 'Daily'].map((s) {
                    final selected = _syncFrequency == s;
                    return InkWell(
                      onTap: () => setState(() => _syncFrequency = s),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            Text(s, style: AppTypography.textTheme.bodyMedium),
                            const Spacer(),
                            Icon(
                              selected ? LucideIcons.checkCircle2 : LucideIcons.circle,
                              color: selected ? AppColors.primary : AppColors.border,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  const Icon(LucideIcons.info, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Biometrics collected: Steps, Heart Rate, Sleep, Calories Burned.',
                      style: AppTypography.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeviceIntegrationCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isConnected;
  final String? lastSync;
  final String? metrics;
  final bool syncing;
  final VoidCallback onToggle;
  final VoidCallback? onSync;

  const _DeviceIntegrationCard({
    required this.title,
    required this.icon,
    required this.isConnected,
    required this.onToggle,
    this.lastSync,
    this.metrics,
    this.syncing = false,
    this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: premiumCardDecoration(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.textTheme.titleMedium),
                    Text(
                      isConnected ? 'OPERATIONAL' : 'OFFLINE',
                      style: AppTypography.textTheme.bodySmall?.copyWith(
                        color: isConnected ? AppColors.success : AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isConnected)
                ElevatedButton(
                  onPressed: onToggle,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    minimumSize: const Size(0, 36),
                  ),
                  child: const Text('LINK'),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onSync != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: TextButton.icon(
                          onPressed: syncing ? null : onSync,
                          icon: syncing
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(LucideIcons.refreshCw, size: 14),
                          label: Text(syncing ? 'Sync…' : 'Sync'),
                        ),
                      ),
                    OutlinedButton(
                      onPressed: onToggle,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        minimumSize: const Size(0, 36),
                        foregroundColor: AppColors.error,
                      ),
                      child: const Text('UNLINK'),
                    ),
                  ],
                ),
            ],
          ),
          if (isConnected && (lastSync != null || metrics != null)) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                const Icon(LucideIcons.refreshCw, size: 12, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Text('Last Sync: $lastSync', style: AppTypography.textTheme.bodySmall),
              ],
            ),
            if (metrics != null && metrics!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(LucideIcons.activity, size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  Expanded(child: Text(metrics!, style: AppTypography.textTheme.bodySmall)),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}
