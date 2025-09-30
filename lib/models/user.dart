class User {
  final int id;
  final String username;
  final String email;
  final int phone;
  final String? password; // Solo para registro/login

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.phone,
    this.password,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'phone': phone,
      'password': password ?? '',
    };
  }

  User copyWith({
    int? id,
    String? username,
    String? email,
    int? phone,
    String? password,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
    );
  }
}