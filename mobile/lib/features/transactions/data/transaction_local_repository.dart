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

  Future<void> create(TransactionModel transaction) async {
    final db = await _appDatabase.instance;
    await db.insert('transactions', transaction.toLocalMap());
  }

  Future<void> update(TransactionModel transaction) async {
    final db = await _appDatabase.instance;
    await db.update('transactions', transaction.toLocalMap(),
        where: 'client_generated_id = ?', whereArgs: [transaction.clientGeneratedId]);
  }

  Future<void> softDelete(String clientGeneratedId) async {
    final db = await _appDatabase.instance;
    await db.update('transactions', {'is_deleted': 1},
        where: 'client_generated_id = ?', whereArgs: [clientGeneratedId]);
  }

  Future<void> markSynced(String clientGeneratedId, {required int? serverId, required DateTime updatedAt}) async {
    final db = await _appDatabase.instance;
    await db.update(
      'transactions',
      {'synced': 1, 'server_id': serverId, 'updated_at': updatedAt.toIso8601String()},
      where: 'client_generated_id = ?',
      whereArgs: [clientGeneratedId],
    );
  }

  Future<TransactionModel?> getByClientId(String id) async {
    final db = await _appDatabase.instance;
    final rows = await db.query('transactions', where: 'client_generated_id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return TransactionModel.fromLocalMap(rows.first);
  }

  Future<List<TransactionModel>> getAll({String? searchQuery}) async {
    final db = await _appDatabase.instance;
    var where = 'is_deleted = 0';
    final whereArgs = <Object?>[];
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      where += ' AND description LIKE ?';
      whereArgs.add('%${searchQuery.trim()}%');
    }
    final rows = await db.query('transactions',
        where: where, whereArgs: whereArgs, orderBy: 'transaction_date DESC, updated_at DESC');
    return rows.map(TransactionModel.fromLocalMap).toList();
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

  Future<List<TransactionModel>> getUnsynced() async {
    final db = await _appDatabase.instance;
    final rows = await db.query('transactions', where: 'synced = 0 AND is_deleted = 0');
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