import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DB {
  static Database? _db;

  // ===============================
  // DB instance
  // ===============================
  static Future<Database> get instance async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  // ===============================
  // DB open + seed.sql 실행
  // ===============================
  static Future<Database> _open() async {
    final dir = await getApplicationSupportDirectory();
    final dbPath = join(dir.path, 'dw_ecount.db');

    final exists = await File(dbPath).exists();

    final db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await _runSeed(db);
      },
    );

    // 기존 DB인데 테이블/컬럼 누락 대비
    await _ensureColumns(db);

    return db;
  }

  // ===============================
  // seed.sql 실행
  // ===============================
  static Future<void> _runSeed(Database db) async {
    final sql = await rootBundle.loadString('assets/seed.sql');
    final statements = sql.split(';');

    for (final stmt in statements) {
      final s = stmt.trim();
      if (s.isNotEmpty) {
        await db.execute(s);
      }
    }
  }

  // ===============================
  // 컬럼 보정 (기존 DB 대응)
  // ===============================
  static Future<void> _ensureColumns(Database db) async {
    final result = await db.rawQuery("PRAGMA table_info(products)");
    final columns = result.map((e) => e['name'] as String).toSet();

    Future<void> add(String sql) async => await db.execute(sql);

    if (!columns.contains('deal_date')) {
      await add("ALTER TABLE products ADD COLUMN deal_date TEXT");
    }
    if (!columns.contains('client')) {
      await add("ALTER TABLE products ADD COLUMN client TEXT");
    }
    if (!columns.contains('category')) {
      await add("ALTER TABLE products ADD COLUMN category TEXT");
    }
    if (!columns.contains('manufacturer')) {
      await add("ALTER TABLE products ADD COLUMN manufacturer TEXT");
    }
    if (!columns.contains('spec')) {
      await add("ALTER TABLE products ADD COLUMN spec TEXT");
    }
    if (!columns.contains('unit')) {
      await add("ALTER TABLE products ADD COLUMN unit TEXT");
    }
    if (!columns.contains('quantity')) {
      await add(
        "ALTER TABLE products ADD COLUMN quantity INTEGER NOT NULL DEFAULT 1",
      );
    }
    if (!columns.contains('total_price')) {
      await add(
        "ALTER TABLE products ADD COLUMN total_price INTEGER NOT NULL DEFAULT 0",
      );
    }
    if (!columns.contains('note')) {
      await add("ALTER TABLE products ADD COLUMN note TEXT");
    }
  }

  // ===============================
  // CRUD - Products
  // ===============================

  static Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await instance;
    return db.query(
      'products',
      orderBy: 'deal_date, client, category, name',
    );
  }

  static Future<int> insertProduct(Map<String, dynamic> data) async {
    final db = await instance;
    return db.insert('products', data);
  }

  static Future<int> updateProduct(
      int id,
      Map<String, dynamic> data,
      ) async {
    final db = await instance;
    return db.update(
      'products',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> deleteProduct(int id) async {
    final db = await instance;
    return db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
