import 'package:sqflite/sqflite.dart';
import '../../../core/database/app_database.dart';
import '../models/budget_model.dart';

class BudgetLocalRepository {
  BudgetLocalRepository(this._appDatabase);
  final AppDatabase _appDatabase;

  Future<void> upsertAll(List<BudgetModel> budgets) async {
    final db = await _appDatabase.instance;
    final batch = db.batch();
    for (final b in budgets) {
      batch.insert('budgets', b.toLocalMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<BudgetModel>> getActive() async {
    final db = await _appDatabase.instance;
    final rows = await db.query('budgets', where: 'is_deleted = 0 AND is_active = 1');
    return rows.map(BudgetModel.fromLocalMap).toList();
  }
}