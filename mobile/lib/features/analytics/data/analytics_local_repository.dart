import '../../../core/database/app_database.dart';

class CategoryBreakdownRow {
  CategoryBreakdownRow({required this.categoryId, required this.name, required this.icon, required this.amount});
  final String categoryId;
  final String name;
  final String icon;
  final int amount;
}

class TrendRow {
  TrendRow({required this.label, required this.income, required this.expense});
  final String label;
  final int income;
  final int expense;
}

class AnalyticsLocalRepository {
  AnalyticsLocalRepository(this._appDatabase);
  final AppDatabase _appDatabase;

  Future<({int income, int expense})> totalsForRange(DateTime start, DateTime end) async {
    final db = await _appDatabase.instance;
    final startStr = start.toIso8601String().split('T').first;
    final endStr = end.toIso8601String().split('T').first;
    final incomeRows = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE is_deleted = 0 AND type = 'income' AND transaction_date BETWEEN ? AND ?",
      [startStr, endStr],
    );
    final expenseRows = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE is_deleted = 0 AND type = 'expense' AND transaction_date BETWEEN ? AND ?",
      [startStr, endStr],
    );
    return (income: incomeRows.first['total'] as int, expense: expenseRows.first['total'] as int);
  }

  Future<List<CategoryBreakdownRow>> expenseBreakdownByCategory(DateTime start, DateTime end) async {
    final db = await _appDatabase.instance;
    final startStr = start.toIso8601String().split('T').first;
    final endStr = end.toIso8601String().split('T').first;
    final rows = await db.rawQuery('''
      SELECT c.client_generated_id as category_id, c.name as name, c.icon as icon, SUM(t.amount) as total
      FROM transactions t
      JOIN categories c ON c.client_generated_id = t.category_id
      WHERE t.is_deleted = 0 AND t.type = 'expense' AND t.transaction_date BETWEEN ? AND ?
      GROUP BY c.client_generated_id, c.name, c.icon
      ORDER BY total DESC
    ''', [startStr, endStr]);
    return rows
        .map((r) => CategoryBreakdownRow(categoryId: r['category_id'] as String, name: r['name'] as String, icon: r['icon'] as String, amount: r['total'] as int))
        .toList();
  }

  Future<List<TrendRow>> monthlyTrend(int periods) async {
    final db = await _appDatabase.instance;
    final now = DateTime.now();
    final result = <TrendRow>[];
    for (var i = periods - 1; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final start = DateTime(monthDate.year, monthDate.month, 1);
      final end = DateTime(monthDate.year, monthDate.month + 1, 0);
      final startStr = start.toIso8601String().split('T').first;
      final endStr = end.toIso8601String().split('T').first;

      final incomeRows = await db.rawQuery(
        "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE is_deleted = 0 AND type = 'income' AND transaction_date BETWEEN ? AND ?",
        [startStr, endStr],
      );
      final expenseRows = await db.rawQuery(
        "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE is_deleted = 0 AND type = 'expense' AND transaction_date BETWEEN ? AND ?",
        [startStr, endStr],
      );

      result.add(TrendRow(label: _monthLabel(start.month), income: incomeRows.first['total'] as int, expense: expenseRows.first['total'] as int));
    }
    return result;
  }

  String _monthLabel(int month) {
    const labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return labels[month - 1];
  }
}