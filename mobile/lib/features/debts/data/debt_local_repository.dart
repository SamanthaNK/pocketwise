import 'package:sqflite/sqflite.dart';
import '../../../core/database/app_database.dart';
import '../models/debt_model.dart';

class DebtLocalRepository {
  DebtLocalRepository(this._appDatabase);
  final AppDatabase _appDatabase;

  Future<void> upsertAll(List<DebtModel> debts) async {
    final db = await _appDatabase.instance;
    final batch = db.batch();
    for (final d in debts) {
      batch.insert('debts', d.toLocalMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> create(DebtModel debt) async {
    final db = await _appDatabase.instance;
    await db.insert('debts', debt.toLocalMap());
  }

  Future<void> update(DebtModel debt) async {
    final db = await _appDatabase.instance;
    await db.update('debts', debt.toLocalMap(), where: 'client_generated_id = ?', whereArgs: [debt.clientGeneratedId]);
  }

  Future<void> softDelete(String clientGeneratedId) async {
    final db = await _appDatabase.instance;
    await db.update('debts', {'is_deleted': 1}, where: 'client_generated_id = ?', whereArgs: [clientGeneratedId]);
  }

  Future<void> markSynced(String clientGeneratedId, {required int? serverId, required DateTime updatedAt}) async {
    final db = await _appDatabase.instance;
    await db.update('debts', {'synced': 1, 'server_id': serverId, 'updated_at': updatedAt.toIso8601String()},
        where: 'client_generated_id = ?', whereArgs: [clientGeneratedId]);
  }

  Future<void> replaceWithServerCopy(DebtModel serverDebt) async {
    final db = await _appDatabase.instance;
    await db.update('debts', serverDebt.toLocalMap(), where: 'client_generated_id = ?', whereArgs: [serverDebt.clientGeneratedId]);
  }

  Future<List<DebtModel>> getAll() async {
    final db = await _appDatabase.instance;
    final rows = await db.query('debts', where: 'is_deleted = 0', orderBy: 'due_date IS NULL, due_date ASC');
    return rows.map(DebtModel.fromLocalMap).toList();
  }

  Future<List<DebtModel>> getUnsynced() async {
    final db = await _appDatabase.instance;
    final rows = await db.query('debts', where: 'synced = 0 AND is_deleted = 0');
    return rows.map(DebtModel.fromLocalMap).toList();
  }
}