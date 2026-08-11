import 'package:dio/dio.dart';
import '../models/payment_method_model.dart';

class PaymentMethodApi {
  PaymentMethodApi(this._dio);
  final Dio _dio;

  Future<List<PaymentMethodModel>> fetchAll() async {
    final response = await _dio.get('/payment-methods', queryParameters: {'include_archived': true});
    final list = response.data as List;
    return list.map((e) => PaymentMethodModel.fromServerJson(e as Map<String, dynamic>)).toList();
  }
}