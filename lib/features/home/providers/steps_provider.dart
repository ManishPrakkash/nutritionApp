import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/pedometer_service.dart';

// Provider for real-time step count
final stepsProvider = StreamProvider<int>((ref) {
  return PedometerService.instance.stepsStream;
});

// Provider for current step count (synchronous access)
final currentStepsProvider = Provider<int>((ref) {
  final stepsAsync = ref.watch(stepsProvider);
  return stepsAsync.when(
    data: (steps) => steps,
    loading: () => PedometerService.instance.todaySteps,
    error: (_, __) => PedometerService.instance.todaySteps,
  );
});