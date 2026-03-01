import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
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

  Future<Map<String, dynamic>> getMe() async {
    final response = await ApiClient.get(AppConstants.me);
    return response['user'] as Map<String, dynamic>;
  }

  Future<String> uploadProfileImage(File file) async {
    final token = TokenStorage.getToken();
    if (token == null) throw Exception('No token found');

    final uri = Uri.parse('${AppConstants.baseUrl}/auth/profile-image');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll({
        'Authorization': 'Bearer $token',
      });

    final fileStream = http.ByteStream(file.openRead());
    final length = await file.length();
    final ext = path.extension(file.path).toLowerCase();
    
    // Determine content type based on extension
    MediaType contentType;
    if (ext == '.png') {
      contentType = MediaType('image', 'png');
    } else if (ext == '.jpeg' || ext == '.jpg') {
      contentType = MediaType('image', 'jpeg');
    } else {
      contentType = MediaType('application', 'octet-stream');
    }

    final multipartFile = http.MultipartFile(
      'profile_image',
      fileStream,
      length,
      filename: path.basename(file.path),
      contentType: contentType,
    );

    request.files.add(multipartFile);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      // Typically need to parse the JSON and return the profile image url.
      // But for simplicity, the provider will just call getMe() again to update state.
      return 'success';
    } else {
      throw Exception('Failed to upload image: ${response.body}');
    }
  }

  Future<void> logout() async {
    await TokenStorage.clearAuth();
  }
}
