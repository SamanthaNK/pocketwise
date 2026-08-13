import 'package:dio/dio.dart';

class AuthApi {
  AuthApi(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> register({required String name, required String email, required String password}) async {
    final response = await _dio.post('/auth/register', data: {'name': name, 'email': email, 'password': password});
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login({required String email, required String password}) async {
    final response = await _dio.post('/auth/login', data: {'email': email, 'password': password});
    return response.data as Map<String, dynamic>;
  }
}