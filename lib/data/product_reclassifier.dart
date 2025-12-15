import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'db.dart';
import 'category_rule_dao.dart';
import 'category_auto_classifier.dart';

class ProductReclassifier {
  static Future<void> reclassifyAll() async {
    final Database db = await DB.instance;
    final rules = await CategoryRuleDao().fetchActiveRules();

    final rows = await db.query('products');
    final batch = db.batch();

    for (final row in rows) {
      final source =
          '${row['name'] ?? ''} ${row['spec'] ?? ''} ${row['note'] ?? ''}';

      final category = CategoryAutoClassifier.classify(
        sourceText: source,
        rules: rules,
      );

// 🔥 null이면 빈값으로라도 업데이트
      batch.update(
        'products',
        {
          'category': category ?? '',
        },
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }

    await batch.commit(noResult: true);
  }
}
