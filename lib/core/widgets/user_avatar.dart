import 'package:flutter/material.dart';
import '../utils/constants.dart';

class UserAvatar extends StatelessWidget {
  final String? profileImage;
  final String name;
  final double radius;
  final Color backgroundColor;
  final Color textColor;

  const UserAvatar({
    super.key,
    required this.profileImage,
    required this.name,
    this.radius = 20,
    this.backgroundColor = const Color(0xFFEEEFF8),
    this.textColor = const Color(0xFF3D52D5),
  });

  @override
  Widget build(BuildContext context) {
    if (profileImage != null && profileImage!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor.withValues(alpha: 0.1),
        backgroundImage: NetworkImage('${AppConstants.imageBaseUrl}$profileImage'),
      );
    }

    final String initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: Text(
        initial,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.7,
        ),
      ),
    );
  }
}
