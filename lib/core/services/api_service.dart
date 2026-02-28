import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'local_storage.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();

  static Map<String, String> _headers({bool auth = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (auth) {
      final token = TokenStorage.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static dynamic _handleResponse(http.Response response,
      {bool isAuthRoute = false}) {
    final body = jsonDecode(response.body);

    if (response.statusCode == 401 && !isAuthRoute) {
      TokenStorage.clearAuth();
      throw ApiException('Session expired. Please login again.',
          statusCode: 401);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message = body['message'] ?? 'Something went wrong.';
    throw ApiException(message, statusCode: response.statusCode);
  }

  static Future<dynamic> get(String endpoint) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
      final response = await http.get(uri, headers: _headers());
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error. Please check your connection.');
    }
  }

  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
      final response = await http.post(
        uri,
        headers: _headers(auth: auth),
        body: jsonEncode(body),
      );
      return _handleResponse(response, isAuthRoute: !auth);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error. Please check your connection.');
    }
  }

  static Future<dynamic> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
      final response = await http.put(
        uri,
        headers: _headers(),
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error. Please check your connection.');
    }
  }

  static Future<dynamic> patch(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
      final response = await http.patch(
        uri,
        headers: _headers(),
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error. Please check your connection.');
    }
  }
}
