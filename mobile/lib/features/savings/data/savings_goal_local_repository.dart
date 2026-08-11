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

  Future<List<SavingsGoalModel>> getAll() async {
    final db = await _appDatabase.instance;
    final rows = await db.query('savings_goals', where: 'is_deleted = 0', orderBy: 'target_date IS NULL, target_date ASC');
    return rows.map(SavingsGoalModel.fromLocalMap).toList();
  }
}