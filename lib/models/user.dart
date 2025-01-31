// File: models/user.dart

class User {
  final int id;
  final String password;
  final String fullName; // Maps to 'name' in the database

  User({
    required this.id,
    required this.password,
    required this.fullName,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int,
      password: map['password'] as String,
      fullName: map['name'] as String, // 'name' in the database
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'password': password,
      'name': fullName, // 'name' in the database
    };
  }
}