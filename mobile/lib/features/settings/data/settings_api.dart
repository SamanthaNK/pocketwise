import 'package:dio/dio.dart';

class SettingsApi {
  SettingsApi(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get('/users/me');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile(String name) async {
    final response = await _dio.put('/users/me/profile', data: {'name': name});
    return response.data as Map<String, dynamic>;
  }

  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    await _dio.put('/auth/change-password', data: {'current_password': currentPassword, 'new_password': newPassword});
  }
}