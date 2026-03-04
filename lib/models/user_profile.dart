import 'dart:convert';

class UserProfile {
  final String uid;
  final String fullName;
  final int age;
  final String gender;
  final double heightCm;
  final double weightKg;
  final String email;
  final String? photoUrl;
  final DateTime createdAt;
  final double? bmi;
  final double? bmr;
  final double? tdee;

  double get calculatedBmi {
    if (heightCm <= 0) return 0;
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  const UserProfile({
    required this.uid,
    required this.fullName,
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    required this.email,
    this.photoUrl,
    required this.createdAt,
    this.bmi,
    this.bmr,
    this.tdee,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'fullName': fullName,
        'age': age,
        'gender': gender,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'email': email,
        'photoUrl': photoUrl,
        'createdAt': createdAt.toIso8601String(),
        'bmi': bmi,
        'bmr': bmr,
        'tdee': tdee,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        uid: json['uid'] as String,
        fullName: json['fullName'] as String,
        age: json['age'] as int,
        gender: json['gender'] as String,
        heightCm: (json['heightCm'] as num).toDouble(),
        weightKg: (json['weightKg'] as num).toDouble(),
        email: json['email'] as String,
        photoUrl: json['photoUrl'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        bmi: json['bmi'] != null ? (json['bmi'] as num).toDouble() : null,
        bmr: json['bmr'] != null ? (json['bmr'] as num).toDouble() : null,
        tdee: json['tdee'] != null ? (json['tdee'] as num).toDouble() : null,
      );

  String toJsonString() => jsonEncode(toJson());

  UserProfile copyWith({
    String? uid,
    String? fullName,
    int? age,
    String? gender,
    double? heightCm,
    double? weightKg,
    String? email,
    String? photoUrl,
    DateTime? createdAt,
    double? bmi,
    double? bmr,
    double? tdee,
  }) =>
      UserProfile(
        uid: uid ?? this.uid,
        fullName: fullName ?? this.fullName,
        age: age ?? this.age,
        gender: gender ?? this.gender,
        heightCm: heightCm ?? this.heightCm,
        weightKg: weightKg ?? this.weightKg,
        email: email ?? this.email,
        photoUrl: photoUrl ?? this.photoUrl,
        createdAt: createdAt ?? this.createdAt,
        bmi: bmi ?? this.bmi,
        bmr: bmr ?? this.bmr,
        tdee: tdee ?? this.tdee,
      );
}
