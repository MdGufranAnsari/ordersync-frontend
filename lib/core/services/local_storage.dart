import 'package:hive/hive.dart';

class TokenStorage {
  TokenStorage._();

  static const String boxName = 'authBox';
  static const String _tokenKey = 'token';
  static const String _roleKey = 'role';

  static Box get _box => Hive.box(boxName);

  static Future<void> saveToken(String token) async {
    await _box.put(_tokenKey, token);
  }

  static Future<void> saveRole(String role) async {
    await _box.put(_roleKey, role);
  }

  static String? getToken() => _box.get(_tokenKey);

  static String? getRole() => _box.get(_roleKey);

  static Future<void> clearAuth() async {
    await _box.delete(_tokenKey);
    await _box.delete(_roleKey);
  }
}
