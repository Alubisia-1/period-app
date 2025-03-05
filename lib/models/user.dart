class User {
  final int id;
  final String fullName; // Maps to 'name' in the database

  User({
    required this.id,
    required this.fullName,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int,
      fullName: map['name'] as String, // 'name' in the database
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': fullName, // 'name' in the database
    };
  }
}