import 'package:sqflite/sqflite.dart';
import '../../../core/database/app_database.dart';
import '../models/payment_method_model.dart';

class PaymentMethodLocalRepository {
  PaymentMethodLocalRepository(this._appDatabase);
  final AppDatabase _appDatabase;

  Future<void> upsertAll(List<PaymentMethodModel> methods) async {
    final db = await _appDatabase.instance;
    final batch = db.batch();
    for (final m in methods) {
      batch.insert('payment_methods', m.toLocalMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<PaymentMethodModel>> getAll({bool includeArchived = false}) async {
    final db = await _appDatabase.instance;
    final where = includeArchived ? 'is_deleted = 0' : 'is_deleted = 0 AND is_archived = 0';
    final rows = await db.query('payment_methods', where: where, orderBy: 'type, label');
    return rows.map(PaymentMethodModel.fromLocalMap).toList();
  }
}