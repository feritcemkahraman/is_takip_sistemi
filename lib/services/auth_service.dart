import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:is_takip_sistemi/config/api_config.dart';
import 'package:is_takip_sistemi/models/user_model.dart';

class AuthService {
  final http.Client _client;

  AuthService({http.Client? client}) : _client = client ?? http.Client();

  Future<UserModel> login(String email, String password) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.login}'),
      headers: ApiConfig.getHeaders(),
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      return UserModel.fromJson(data['user']);
    } else {
      throw Exception('Giriş başarısız');
    }
  }

  Future<UserModel> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.register}'),
      headers: ApiConfig.getHeaders(),
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      return UserModel.fromJson(data['user']);
    } else {
      throw Exception('Kayıt başarısız');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) return null;

    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.profile}'),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(jsonDecode(response.body));
      } else {
        await logout();
        return null;
      }
    } catch (e) {
      await logout();
      return null;
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    final token = await _getToken();
    final response = await _client.put(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.changePassword}'),
      headers: ApiConfig.getHeaders(token: token),
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Şifre değiştirilemedi');
    }
  }

  Future<UserModel> updateProfile({
    String? username,
    String? email,
    String? avatar,
  }) async {
    final token = await _getToken();
    final response = await _client.put(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.updateProfile}'),
      headers: ApiConfig.getHeaders(token: token),
      body: jsonEncode({
        if (username != null) 'username': username,
        if (email != null) 'email': email,
        if (avatar != null) 'avatar': avatar,
      }),
    );

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Profil güncellenemedi');
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  void dispose() {
    _client.close();
  }
}
