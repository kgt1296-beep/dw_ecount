import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

import '../utils/date_utils.dart';
import 'db.dart';
import 'excel_import_template.dart';

class ExcelImport {
  /// onProgress:
  ///   current: 현재 처리한 row 수
  ///   total: 전체 row 수
  static Future<void> importFromTemplate({
    required bool clearBeforeInsert,
    void Function(int current, int total)? onProgress,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: '엑셀 가져오기 (연도별 시트 포함)',
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result == null) return;

    final path = result.files.single.path;
    if (path == null) return;

    final file = File(path);
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);

    if (excel.tables.isEmpty) {
      throw Exception('엑셀 시트가 없습니다');
    }

    // ✅ 덮어쓰기면 전체 삭제는 한 번만
    if (clearBeforeInsert) {
      final db = await DB.instance;
      await db.delete('products');
    }

    // -------------------------------
    // 전체 row 수 계산 (진행률용)
    // -------------------------------
    int totalRows = 0;
    for (final sheet in excel.tables.values) {
      if (sheet.rows.length <= 1) continue;
      totalRows += sheet.rows.length;
    }

    int processed = 0;

    // -------------------------------
    // 모든 시트 순회
    // -------------------------------
    for (final entry in excel.tables.entries) {
      final sheetName = entry.key;
      final sheet = entry.value;

      if (sheet.rows.isEmpty) continue;

      // -------------------------------
      // 1) 헤더 검증
      // -------------------------------
      final header = sheet.rows.first
          .map((c) => c?.value?.toString().trim() ?? '')
          .toList();

      if (header.length < ExcelImportTemplate.headers.length) {
        continue;
      }

      bool headerOk = true;
      for (int i = 0; i < ExcelImportTemplate.headers.length; i++) {
        if (header[i] != ExcelImportTemplate.headers[i]) {
          headerOk = false;
          break;
        }
      }
      if (!headerOk) continue;

      // -------------------------------
      // 2) 시작 행 결정
      // -------------------------------
      int startRow = 1;
      if (sheet.rows.length > 1) {
        final r1c0 = sheet.rows[1].isNotEmpty
            ? (sheet.rows[1][0]?.value?.toString().trim() ?? '')
            : '';
        if (r1c0 == '필수' || r1c0 == '선택') {
          startRow = 2;
        }
      }

      // -------------------------------
      // 3) 데이터 삽입
      // -------------------------------
      for (int r = startRow; r < sheet.rows.length; r++) {
        final row = sheet.rows[r];
        processed++;

        if (row.isEmpty) {
          _notify(onProgress, processed, totalRows);
          continue;
        }

        String _s(int idx) =>
            (idx < row.length ? row[idx]?.value?.toString() : null)
                ?.trim() ??
                '';

        int _i(int idx, {int def = 0}) {
          final v = _s(idx).replaceAll(',', '');
          return int.tryParse(v) ?? def;
        }

        final dealDateRaw = _s(0);
        final client = _s(1);
        final category = _s(2);
        final manufacturer = _s(3);
        final name = _s(4);
        final spec = _s(5);
        final quantity = _i(6, def: 1);
        final totalPrice = _i(7, def: 0);
        final note = _s(9);

        if (name.isEmpty) {
          _notify(onProgress, processed, totalRows);
          continue;
        }

        final dealDate = normalizeDealDate(
          dealDateRaw,
          fallbackYear: sheetName,
        );

        await DB.insertProduct({
          'deal_date': dealDate,
          'client': client,
          'category': category,
          'manufacturer': manufacturer,
          'name': name,
          'spec': spec,
          'unit': '',
          'quantity': quantity <= 0 ? 1 : quantity,
          'total_price': totalPrice,
          'note': note,
        });

        // ✅ 20건마다 UI 숨통
        if (processed % 20 == 0) {
          _notify(onProgress, processed, totalRows);
          await Future.delayed(Duration.zero);
        }
      }
    }

    // 마지막 진행률 알림
    _notify(onProgress, totalRows, totalRows);
  }

  static void _notify(
      void Function(int current, int total)? onProgress,
      int current,
      int total,
      ) {
    if (onProgress != null) {
      onProgress(current, total);
    }
  }
}
