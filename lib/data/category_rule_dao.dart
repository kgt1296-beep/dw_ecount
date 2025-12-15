import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/category_rule.dart';
import 'db.dart';

/// =======================================================
/// CategoryRuleDao
/// - 자동 분류 규칙 DB 접근 전담
/// =======================================================
class CategoryRuleDao {
  /// ✅ 네 DB 구조에 맞는 접근
  Future<Database> get _db async => await DB.instance;

  /// 활성 규칙 조회
  Future<List<CategoryRule>> fetchActiveRules() async {
    final db = await _db;

    final rows = await db.query(
      'category_rules',
      where: 'is_active = 1',
      orderBy: 'priority ASC',
    );

    return rows.map(CategoryRule.fromMap).toList();
  }

  /// 전체 규칙 조회
  Future<List<CategoryRule>> fetchAllRules() async {
    final db = await _db;

    final rows = await db.query(
      'category_rules',
      orderBy: 'priority ASC',
    );

    return rows.map(CategoryRule.fromMap).toList();
  }

  /// 규칙 추가
  Future<int> insertRule(CategoryRule rule) async {
    final db = await _db;

    return db.insert(
      'category_rules',
      rule.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 규칙 수정
  Future<void> updateRule(CategoryRule rule) async {
    if (rule.id == null) {
      throw Exception('CategoryRule id is null');
    }

    final db = await _db;

    await db.update(
      'category_rules',
      rule.toMap(),
      where: 'id = ?',
      whereArgs: [rule.id],
    );
  }

  /// 비활성화
  Future<void> deactivateRule(int id) async {
    final db = await _db;

    await db.update(
      'category_rules',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 활성화
  Future<void> activateRule(int id) async {
    final db = await _db;

    await db.update(
      'category_rules',
      {'is_active': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 우선순위 재정렬
  Future<void> updatePriorities(List<CategoryRule> rules) async {
    final db = await _db;
    final batch = db.batch();

    for (int i = 0; i < rules.length; i++) {
      final rule = rules[i];
      if (rule.id == null) continue;

      batch.update(
        'category_rules',
        {'priority': i + 1},
        where: 'id = ?',
        whereArgs: [rule.id],
      );
    }

    await batch.commit(noResult: true);
  }
}
