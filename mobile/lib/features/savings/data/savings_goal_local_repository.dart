import 'package:sqflite/sqflite.dart';
import '../../../core/database/app_database.dart';
import '../models/savings_goal_model.dart';

class SavingsGoalLocalRepository {
  SavingsGoalLocalRepository(this._appDatabase);
  final AppDatabase _appDatabase;

  Future<void> upsertAll(List<SavingsGoalModel> goals) async {
    final db = await _appDatabase.instance;
    final batch = db.batch();
    for (final g in goals) {
      batch.insert('savings_goals', g.toLocalMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> create(SavingsGoalModel goal) async {
    final db = await _appDatabase.instance;
    await db.insert('savings_goals', goal.toLocalMap());
  }

  Future<void> update(SavingsGoalModel goal) async {
    final db = await _appDatabase.instance;
    await db.update('savings_goals', goal.toLocalMap(), where: 'client_generated_id = ?', whereArgs: [goal.clientGeneratedId]);
  }

  Future<void> softDelete(String clientGeneratedId) async {
    final db = await _appDatabase.instance;
    await db.update('savings_goals', {'is_deleted': 1}, where: 'client_generated_id = ?', whereArgs: [clientGeneratedId]);
  }

  Future<void> markSynced(String clientGeneratedId, {required int? serverId, required DateTime updatedAt}) async {
    final db = await _appDatabase.instance;
    await db.update('savings_goals', {'synced': 1, 'server_id': serverId, 'updated_at': updatedAt.toIso8601String()},
        where: 'client_generated_id = ?', whereArgs: [clientGeneratedId]);
  }

  Future<SavingsGoalModel?> getByClientId(String id) async {
    final db = await _appDatabase.instance;
    final rows = await db.query('savings_goals', where: 'client_generated_id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return SavingsGoalModel.fromLocalMap(rows.first);
  }

  Future<List<SavingsGoalModel>> getAll() async {
    final db = await _appDatabase.instance;
    final rows = await db.query('savings_goals', where: 'is_deleted = 0', orderBy: 'target_date IS NULL, target_date ASC');
    return rows.map(SavingsGoalModel.fromLocalMap).toList();
  }

  Future<List<SavingsGoalModel>> getUnsynced() async {
    final db = await _appDatabase.instance;
    final rows = await db.query('savings_goals', where: 'synced = 0 AND is_deleted = 0');
    return rows.map(SavingsGoalModel.fromLocalMap).toList();
  }

  Future<void> recomputeSavedAmount(String goalClientId, int savedAmount) async {
    final db = await _appDatabase.instance;
    await db.update('savings_goals', {'saved_amount': savedAmount}, where: 'client_generated_id = ?', whereArgs: [goalClientId]);
  }
}