// lib/models/user.dart

class User {
  final String phone;
  final String name;
  final String token;

  const User({
    required this.phone,
    required this.name,
    required this.token,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  factory User.fromJson(Map<String, dynamic> json, String token) {
    return User(
      phone: json['phone'] as String,
      name:  json['name']  as String,
      token: token,
    );
  }
}
