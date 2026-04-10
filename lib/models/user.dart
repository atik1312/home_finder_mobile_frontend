import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 1) // Unique typeId for this class
class User {
  @HiveField(0)
  final int? userId;

  @HiveField(1)
  final String? profilePicture;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final String phoneNumber;
  @HiveField(4)
  final String? name;
  User({
    this.userId,
    this.profilePicture,
    required this.email,
    required this.phoneNumber,
    required this.name,
  });

  @override
  String toString() {
    return 'User{userId: $userId, profilePicture: $profilePicture, email: $email, phoneNumber: $phoneNumber, name: $name}';
  }

  User copyWith({
    int? userId,
    String? profilePicture,
    String? email,
    String? phoneNumber,
    String? name,
  }) {
    return User(
      userId: userId ?? this.userId,
      profilePicture: profilePicture ?? this.profilePicture,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'],
      name: json['name'],
      profilePicture: json['profile_picture'],
      email: json['email'],
      phoneNumber: json['phone_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'profile_picture': profilePicture,
      'email': email,
      'phone_number': phoneNumber,
      'name': name,
    };
  }
}