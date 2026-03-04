import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../services/firestore_service.dart';

class PedometerService {
  PedometerService._();
  static final PedometerService instance = PedometerService._();

  late Stream<StepCount> _stepCountStream;
  late Stream<PedestrianStatus> _pedestrianStatusStream;
  
  int _todaySteps = 0;
  String? _userId;
  String _currentDate = '';
  Timer? _midnightTimer;
  final StreamController<int> _stepsController = StreamController<int>.broadcast();

  // Stream for UI to listen to real-time step updates
  Stream<int> get stepsStream => _stepsController.stream;

  Future<void> init(String userId) async {
    _userId = userId;
    _currentDate = DateTime.now().toIso8601String().split('T').first;
    
    // Request activity recognition permission
    final permissionStatus = await Permission.activityRecognition.request();
    if (permissionStatus.isDenied || permissionStatus.isPermanentlyDenied) {
      print('Activity recognition permission denied. Step counting will not work.');
      return;
    }
    
    await _loadTodaySteps();
    _setupMidnightReset();
    
    try {
      _stepCountStream = Pedometer.stepCountStream;
      _pedestrianStatusStream = Pedometer.pedestrianStatusStream;

      _stepCountStream.listen(_onStepCount).onError(_onStepCountError);
      _pedestrianStatusStream.listen(_onPedestrianStatus).onError(_onPedestrianStatusError);
    } catch (e) {
      print('Error initializing pedometer: $e');
    }
  }

  Future<void> _loadTodaySteps() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T').first;
    
    // Check if it's a new day
    final lastDate = prefs.getString('last_step_date') ?? '';
    if (lastDate != today) {
      // New day - reset steps
      _todaySteps = 0;
      await prefs.setString('last_step_date', today);
      await prefs.setInt('today_steps', 0);
      await prefs.remove('device_steps_baseline');
    } else {
      // Same day - load existing steps
      _todaySteps = prefs.getInt('today_steps') ?? 0;
    }
    _stepsController.add(_todaySteps);
  }

  void _setupMidnightReset() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = tomorrow.difference(now);

    _midnightTimer = Timer(timeUntilMidnight, () {
      _resetDailySteps();
      // Setup timer for next midnight (24 hours)
      _midnightTimer = Timer.periodic(const Duration(days: 1), (_) {
        _resetDailySteps();
      });
    });
  }

  Future<void> _resetDailySteps() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T').first;
    
    _todaySteps = 0;
    _currentDate = today;
    
    await prefs.setString('last_step_date', today);
    await prefs.setInt('today_steps', 0);
    await prefs.remove('device_steps_baseline');
    
    _stepsController.add(_todaySteps);
    _syncWithDatabase();
  }

  Future<void> _onStepCount(StepCount event) async {
    final prefs = await SharedPreferences.getInstance();
    final currentDeviceSteps = event.steps;
    final today = DateTime.now().toIso8601String().split('T').first;
    
    // Check if date changed (app was in background during midnight)
    if (_currentDate != today) {
      await _resetDailySteps();
      return;
    }
    
    // Get or set baseline for today
    int? baseline = prefs.getInt('device_steps_baseline');
    if (baseline == null) {
      // First reading of the day - set baseline
      baseline = currentDeviceSteps;
      await prefs.setInt('device_steps_baseline', baseline);
      _todaySteps = 0;
    } else {
      // Calculate steps taken today
      _todaySteps = (currentDeviceSteps - baseline).clamp(0, double.infinity).toInt();
    }
    
    await prefs.setInt('today_steps', _todaySteps);
    _stepsController.add(_todaySteps);
    _syncWithDatabase();
  }

  void _syncWithDatabase() {
    if (_userId == null) return;
    final date = DateTime.now().toIso8601String().split('T').first;
    FirestoreService.instance.saveDeviceData(
      _userId!,
      date,
      steps: _todaySteps,
    );
  }

  int get todaySteps => _todaySteps;

  // Get steps for a specific date from Firestore
  Future<int> getStepsForDate(String date) async {
    if (_userId == null) return 0;
    final deviceData = await FirestoreService.instance.getDeviceData(_userId!, date);
    return (deviceData?['steps'] as num?)?.toInt() ?? 0;
  }

  void _onPedestrianStatus(PedestrianStatus event) {
    // Can be used to show if user is 'walking' or 'stopped'
  }

  void _onStepCountError(error) {
    print('Pedometer Error: $error');
  }

  void _onPedestrianStatusError(error) {
    print('Pedestrian Status Error: $error');
  }

  void dispose() {
    _midnightTimer?.cancel();
    _stepsController.close();
  }
}
