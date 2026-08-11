import 'package:dio/dio.dart';
import '../models/savings_contribution_model.dart';
import '../models/savings_goal_model.dart';

class SavingsGoalApi {
  SavingsGoalApi(this._dio);
  final Dio _dio;

  Future<List<SavingsGoalModel>> fetchAll() async {
    final response = await _dio.get('/goals');
    final list = response.data as List;
    return list.map((e) => SavingsGoalModel.fromServerJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<SavingsContributionModel>> fetchContributions(int goalServerId) async {
    final response = await _dio.get('/goals/$goalServerId/contributions');
    final list = response.data as List;
    return list.map((e) => SavingsContributionModel.fromServerJson(e as Map<String, dynamic>)).toList();
  }
}