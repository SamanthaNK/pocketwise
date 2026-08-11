import 'package:dio/dio.dart';
import '../models/budget_model.dart';

class BudgetApi {
  BudgetApi(this._dio);
  final Dio _dio;

  Future<List<BudgetModel>> fetchActive() async {
    final response = await _dio.get('/budgets');
    final list = response.data as List;
    return list.map((e) => BudgetModel.fromServerJson(e as Map<String, dynamic>)).toList();
  }
}