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

  Future<List<DebtModel>> getAll() async {
    final db = await _appDatabase.instance;
    final rows = await db.query('debts', where: 'is_deleted = 0', orderBy: 'due_date IS NULL, due_date ASC');
    return rows.map(DebtModel.fromLocalMap).toList();
  }
}