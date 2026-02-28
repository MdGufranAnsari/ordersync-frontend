import '../core/utils/constants.dart';
import '../core/services/api_service.dart';
import '../core/services/local_storage.dart';

class AuthRepository {
  Future<void> register({
    required String name,
    required String phone,
    required String password,
    required String role,
  }) async {
    await ApiClient.post(
      AppConstants.register,
      {
        'name': name,
        'phone': phone,
        'password': password,
        'role': role,
      },
      auth: false,
    );
  }

  Future<String> login({
    required String phone,
    required String password,
  }) async {
    final response = await ApiClient.post(
      AppConstants.login,
      {'phone': phone, 'password': password},
      auth: false,
    );

    final token = response['token'] as String;
    return token;
  }

  Future<void> logout() async {
    await TokenStorage.clearAuth();
  }
}
