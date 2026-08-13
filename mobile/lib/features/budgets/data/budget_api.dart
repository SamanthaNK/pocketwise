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

  Future<List<BudgetModel>> create(Map<String, dynamic> body) async {
    final response = await _dio.post('/budgets', data: body);
    final list = response.data as List;
    return list.map((e) => BudgetModel.fromServerJson(e as Map<String, dynamic>)).toList();
  }

  Future<BudgetModel> update(int budgetId, Map<String, dynamic> body) async {
    final response = await _dio.put('/budgets/$budgetId', data: body);
    return BudgetModel.fromServerJson(response.data as Map<String, dynamic>);
  }
}