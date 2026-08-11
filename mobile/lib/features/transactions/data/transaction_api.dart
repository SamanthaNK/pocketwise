import 'package:dio/dio.dart';
import '../models/transaction_model.dart';

class TransactionApi {
  TransactionApi(this._dio);
  final Dio _dio;

  Future<List<TransactionModel>> fetchAll() async {
    final all = <TransactionModel>[];
    var offset = 0;
    const limit = 500;

    while (true) {
      final response = await _dio.get('/transactions', queryParameters: {
        'limit': limit,
        'offset': offset,
        'sort_by': 'date',
        'sort_order': 'desc',
      });
      final data = response.data as Map<String, dynamic>;
      final list = (data['transactions'] as List)
          .map((e) => TransactionModel.fromServerJson(e as Map<String, dynamic>))
          .toList();
      all.addAll(list);
      if (list.length < limit) break;
      offset += limit;
    }
    return all;
  }
}