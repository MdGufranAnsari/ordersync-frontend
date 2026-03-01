class AuthModel {
  final String id;
  final String name;
  final String phone;
  final String role;
  final String? profileImage;

  AuthModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.profileImage,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      role: json['role'] as String,
      profileImage: json['profile_image'] as String?,
    );
  }
}
