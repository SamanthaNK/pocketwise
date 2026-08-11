import 'package:dio/dio.dart';

String extractErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return data['message'] as String;
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.connectionError) {
      return "You're offline. We'll sync everything when you're back online.";
    }
  }
  return 'Something went wrong. Please try again.';
}