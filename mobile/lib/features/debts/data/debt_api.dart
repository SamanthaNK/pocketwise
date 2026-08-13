import 'package:dio/dio.dart';
import '../models/debt_model.dart';

class DebtApi {
  DebtApi(this._dio);
  final Dio _dio;

  Future<List<DebtModel>> fetchAll() async {
    final unsettled = await _fetch(isSettled: false);
    final settled = await _fetch(isSettled: true);
    return [...unsettled, ...settled];
  }

  Future<List<DebtModel>> _fetch({required bool isSettled}) async {
    final response = await _dio.get('/debts', queryParameters: {'is_settled': isSettled});
    final data = response.data as Map<String, dynamic>;
    return (data['debts'] as List).map((e) => DebtModel.fromServerJson(e as Map<String, dynamic>)).toList();
  }

  Future<DebtModel> settle(int debtId) async {
    final response = await _dio.put('/debts/$debtId/settle');
    return DebtModel.fromServerJson(response.data as Map<String, dynamic>);
  }
}