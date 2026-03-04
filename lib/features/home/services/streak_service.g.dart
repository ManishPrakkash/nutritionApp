// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'streak_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$streakServiceHash() => r'cb5039111a58df64e3743f08b3d7cdd964211243';

/// See also [streakService].
@ProviderFor(streakService)
final streakServiceProvider = AutoDisposeProvider<StreakService>.internal(
  streakService,
  name: r'streakServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$streakServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StreakServiceRef = AutoDisposeProviderRef<StreakService>;
String _$currentStreakHash() => r'7f3a24cbcfc02e042f69754d337d7f890d5c9ed0';

/// See also [CurrentStreak].
@ProviderFor(CurrentStreak)
final currentStreakProvider =
    AutoDisposeAsyncNotifierProvider<CurrentStreak, int>.internal(
      CurrentStreak.new,
      name: r'currentStreakProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$currentStreakHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CurrentStreak = AutoDisposeAsyncNotifier<int>;
String _$weeklyProgressHash() => r'2d4b643ba33eb1f82f33f0effafb48bef58def17';

/// See also [WeeklyProgress].
@ProviderFor(WeeklyProgress)
final weeklyProgressProvider =
    AutoDisposeAsyncNotifierProvider<WeeklyProgress, List<bool>>.internal(
      WeeklyProgress.new,
      name: r'weeklyProgressProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$weeklyProgressHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$WeeklyProgress = AutoDisposeAsyncNotifier<List<bool>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
