import 'package:sqflite/sqflite.dart';
import '../../../core/database/app_database.dart';
import '../models/savings_contribution_model.dart';

class SavingsContributionLocalRepository {
  SavingsContributionLocalRepository(this._appDatabase);
  final AppDatabase _appDatabase;

  Future<void> upsertAll(List<SavingsContributionModel> contributions) async {
    final db = await _appDatabase.instance;
    final batch = db.batch();
    for (final c in contributions) {
      batch.insert('savings_contributions', c.toLocalMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> create(SavingsContributionModel contribution) async {
    final db = await _appDatabase.instance;
    await db.insert('savings_contributions', contribution.toLocalMap());
  }

  Future<void> softDelete(String clientGeneratedId) async {
    final db = await _appDatabase.instance;
    await db.update('savings_contributions', {'is_deleted': 1}, where: 'client_generated_id = ?', whereArgs: [clientGeneratedId]);
  }

  Future<void> markSynced(String clientGeneratedId, {required int? serverId}) async {
    final db = await _appDatabase.instance;
    await db.update('savings_contributions', {'synced': 1, 'server_id': serverId},
        where: 'client_generated_id = ?', whereArgs: [clientGeneratedId]);
  }

  Future<List<SavingsContributionModel>> getForGoal(String goalId) async {
    final db = await _appDatabase.instance;
    final rows = await db.query('savings_contributions',
        where: 'goal_id = ? AND is_deleted = 0', whereArgs: [goalId], orderBy: 'contribution_date DESC');
    return rows.map(SavingsContributionModel.fromLocalMap).toList();
  }

  Future<List<SavingsContributionModel>> getUnsynced() async {
    final db = await _appDatabase.instance;
    final rows = await db.query('savings_contributions', where: 'synced = 0 AND is_deleted = 0');
    return rows.map(SavingsContributionModel.fromLocalMap).toList();
  }

  Future<int> sumForGoal(String goalId) async {
    final db = await _appDatabase.instance;
    final deposits = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM savings_contributions WHERE goal_id = ? AND is_deleted = 0 AND contribution_type = 'deposit'",
      [goalId],
    );
    final withdrawals = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM savings_contributions WHERE goal_id = ? AND is_deleted = 0 AND contribution_type = 'withdrawal'",
      [goalId],
    );
    return (deposits.first['total'] as int) - (withdrawals.first['total'] as int);
  }
}