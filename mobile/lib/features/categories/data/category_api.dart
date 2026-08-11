import 'package:dio/dio.dart';
import '../models/category_model.dart';

class CategoryApi {
  CategoryApi(this._dio);
  final Dio _dio;

  Future<List<CategoryModel>> fetchAll() async {
    final response = await _dio.get('/categories', queryParameters: {'include_archived': true});
    final list = response.data as List;
    return list.map((e) => CategoryModel.fromServerJson(e as Map<String, dynamic>)).toList();
  }
}