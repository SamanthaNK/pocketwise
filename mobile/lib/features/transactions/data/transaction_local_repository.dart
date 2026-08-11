import 'package:sqflite/sqflite.dart';
import '../../../core/database/app_database.dart';
import '../models/transaction_model.dart';

class TransactionLocalRepository {
  TransactionLocalRepository(this._appDatabase);
  final AppDatabase _appDatabase;

  Future<void> upsertAll(List<TransactionModel> transactions) async {
    final db = await _appDatabase.instance;
    final batch = db.batch();
    for (final t in transactions) {
      batch.insert('transactions', t.toLocalMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<TransactionModel>> getRecent({int limit = 10}) async {
    final db = await _appDatabase.instance;
    final rows = await db.query(
      'transactions',
      where: 'is_deleted = 0',
      orderBy: 'transaction_date DESC, updated_at DESC',
      limit: limit,
    );
    return rows.map(TransactionModel.fromLocalMap).toList();
  }

  Future<({int income, int expense})> getTotalsForRange(DateTime start, DateTime end) async {
    final db = await _appDatabase.instance;
    final startStr = start.toIso8601String().split('T').first;
    final endStr = end.toIso8601String().split('T').first;

    final incomeRows = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM transactions "
      "WHERE is_deleted = 0 AND type = 'income' AND transaction_date BETWEEN ? AND ?",
      [startStr, endStr],
    );
    final expenseRows = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM transactions "
      "WHERE is_deleted = 0 AND type = 'expense' AND transaction_date BETWEEN ? AND ?",
      [startStr, endStr],
    );

    return (income: incomeRows.first['total'] as int, expense: expenseRows.first['total'] as int);
  }

  Future<int> getAllTimeBalance() async {
    final db = await _appDatabase.instance;
    final incomeRows = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE is_deleted = 0 AND type = 'income'",
    );
    final expenseRows = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE is_deleted = 0 AND type = 'expense'",
    );
    return (incomeRows.first['total'] as int) - (expenseRows.first['total'] as int);
  }
}