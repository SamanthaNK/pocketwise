import 'package:sqflite/sqflite.dart';
import '../../../core/database/app_database.dart';
import '../models/category_model.dart';

class CategoryLocalRepository {
  CategoryLocalRepository(this._appDatabase);
  final AppDatabase _appDatabase;

  Future<void> upsertAll(List<CategoryModel> categories) async {
    final db = await _appDatabase.instance;
    final batch = db.batch();
    for (final c in categories) {
      batch.insert('categories', c.toLocalMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<CategoryModel>> getAll({bool includeArchived = false}) async {
    final db = await _appDatabase.instance;
    final where = includeArchived ? 'is_deleted = 0' : 'is_deleted = 0 AND is_archived = 0';
    final rows = await db.query('categories', where: where, orderBy: 'type, name');
    return rows.map(CategoryModel.fromLocalMap).toList();
  }

  Future<CategoryModel?> getByClientId(String id) async {
    final db = await _appDatabase.instance;
    final rows = await db.query('categories', where: 'client_generated_id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return CategoryModel.fromLocalMap(rows.first);
  }
}