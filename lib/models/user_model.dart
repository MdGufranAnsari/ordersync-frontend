class AuthModel {
  final String id;
  final String name;
  final String phone;
  final String role;

  AuthModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      role: json['role'] as String,
    );
  }
}
