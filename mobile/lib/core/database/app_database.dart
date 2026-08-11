import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static Database? _db;

  Future<Database> get instance async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'pocketwise.db');
    _db = await openDatabase(path, version: 1, onCreate: _onCreate);
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        client_generated_id TEXT PRIMARY KEY,
        server_id INTEGER,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon TEXT NOT NULL,
        budget_group TEXT,
        is_default INTEGER NOT NULL DEFAULT 0,
        is_archived INTEGER NOT NULL DEFAULT 0,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        synced INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE payment_methods (
        client_generated_id TEXT PRIMARY KEY,
        server_id INTEGER,
        type TEXT NOT NULL,
        provider TEXT,
        label TEXT NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0,
        is_archived INTEGER NOT NULL DEFAULT 0,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        synced INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        client_generated_id TEXT PRIMARY KEY,
        server_id INTEGER,
        category_id TEXT NOT NULL,
        payment_method_id TEXT,
        type TEXT NOT NULL,
        amount INTEGER NOT NULL,
        description TEXT,
        transaction_date TEXT NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        synced INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_transactions_date ON transactions(transaction_date)');
    await db.execute('CREATE INDEX idx_transactions_category ON transactions(category_id)');

    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY,
        rule_type TEXT NOT NULL,
        period_type TEXT NOT NULL,
        category_id TEXT,
        budget_group TEXT,
        limit_amount INTEGER NOT NULL,
        declared_income INTEGER,
        spent INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        synced INTEGER NOT NULL DEFAULT 1,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE savings_goals (
        client_generated_id TEXT PRIMARY KEY,
        server_id INTEGER,
        name TEXT NOT NULL,
        target_amount INTEGER NOT NULL,
        target_date TEXT,
        saved_amount INTEGER NOT NULL DEFAULT 0,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        synced INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE savings_contributions (
        client_generated_id TEXT PRIMARY KEY,
        server_id INTEGER,
        goal_id TEXT NOT NULL,
        amount INTEGER NOT NULL,
        contribution_type TEXT NOT NULL,
        contribution_date TEXT NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        synced INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE debts (
        client_generated_id TEXT PRIMARY KEY,
        server_id INTEGER,
        person_name TEXT NOT NULL,
        amount INTEGER NOT NULL,
        direction TEXT NOT NULL,
        due_date TEXT,
        note TEXT,
        is_settled INTEGER NOT NULL DEFAULT 0,
        settled_at TEXT,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        synced INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> clearAllData() async {
    final db = await instance;
    final batch = db.batch();
    for (final table in [
      'categories', 'payment_methods', 'transactions',
      'budgets', 'savings_goals', 'savings_contributions', 'debts',
    ]) {
      batch.delete(table);
    }
    await batch.commit(noResult: true);
  }
}