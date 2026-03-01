import 'package:hive/hive.dart';

class TokenStorage {
  TokenStorage._();

  static const String boxName = 'authBox';
  static const String _tokenKey = 'token';
  static const String _roleKey = 'role';
  static const String _statusKey = 'account_status';

  static Box get _box => Hive.box(boxName);

  static Future<void> saveToken(String token) async {
    await _box.put(_tokenKey, token);
  }

  static Future<void> saveRole(String role) async {
    await _box.put(_roleKey, role);
  }

  static Future<void> saveStatus(String status) async {
    await _box.put(_statusKey, status);
  }

  static String? getToken() => _box.get(_tokenKey);

  static String? getRole() => _box.get(_roleKey);

  static String? getStatus() => _box.get(_statusKey);

  static Future<void> clearAuth() async {
    await _box.delete(_tokenKey);
    await _box.delete(_roleKey);
    await _box.delete(_statusKey);
  }
}
