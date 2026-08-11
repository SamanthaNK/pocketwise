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

  Future<List<SavingsContributionModel>> getForGoal(String goalId) async {
    final db = await _appDatabase.instance;
    final rows = await db.query(
      'savings_contributions',
      where: 'goal_id = ? AND is_deleted = 0',
      whereArgs: [goalId],
      orderBy: 'contribution_date DESC',
    );
    return rows.map(SavingsContributionModel.fromLocalMap).toList();
  }
}