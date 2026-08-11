import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';

class DioClient {
  DioClient({
    required SecureStorageService secureStorage,
    required Future<void> Function() onAuthFailure,
  })  : _secureStorage = secureStorage,
        _onAuthFailure = onAuthFailure {
    dio = Dio(
      BaseOptions(
        baseUrl: 'http://10.0.2.2:8000/v1',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final isAuthEndpoint = options.path.startsWith('/auth/');
          if (!isAuthEndpoint) {
            final token = await _secureStorage.readAccessToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final isUnauthorized = error.response?.statusCode == 401;
          final isAuthEndpoint = error.requestOptions.path.startsWith('/auth/');

          if (isUnauthorized && !isAuthEndpoint) {
            final retried = await _retryWithRefreshedToken(error.requestOptions);
            if (retried != null) {
              handler.resolve(retried);
              return;
            }
            await _onAuthFailure();
          }
          handler.next(error);
        },
      ),
    );
  }

  late final Dio dio;
  final SecureStorageService _secureStorage;
  final Future<void> Function() _onAuthFailure;

  Future<String?>? _refreshFuture;

  Future<Response<dynamic>?> _retryWithRefreshedToken(RequestOptions requestOptions) async {
    _refreshFuture ??= _refreshAccessToken();
    final newToken = await _refreshFuture;
    _refreshFuture = null;
    if (newToken == null) return null;

    requestOptions.headers['Authorization'] = 'Bearer $newToken';
    try {
      return await dio.fetch(requestOptions);
    } catch (_) {
      return null;
    }
  }

  Future<String?> _refreshAccessToken() async {
    final refreshToken = await _secureStorage.readRefreshToken();
    if (refreshToken == null) return null;

    try {
      final response = await dio.post('/auth/refresh', data: {'refresh_token': refreshToken});
      final newAccessToken = response.data['access_token'] as String;
      final newRefreshToken = response.data['refresh_token'] as String;
      await _secureStorage.writeTokens(accessToken: newAccessToken, refreshToken: newRefreshToken);
      return newAccessToken;
    } catch (_) {
      return null;
    }
  }
}