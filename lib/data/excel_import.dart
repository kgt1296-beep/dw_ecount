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
      // 1) 헤더 검증 (템플릿 기준)
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
      // 2) 시작 행 결정 (안내/예시 행 스킵)
      // -------------------------------
      int startRow = 1;

      if (sheet.rows.length > 1) {
        final firstDataRow = sheet.rows[1];
        final c0 = firstDataRow.isNotEmpty
            ? firstDataRow[0]?.value?.toString().trim() ?? ''
            : '';

        // "예: 2025-10-30 또는 20241030"
        if (c0.startsWith('예')) {
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

        /// 문자열 안전 추출
        String _s(int idx) {
          if (idx >= row.length) return '';
          final v = row[idx]?.value;
          return v?.toString().trim() ?? '';
        }

        /// 숫자 안전 파싱 (excel 구버전 대응)
        int _i(int idx, {int def = 0}) {
          if (idx >= row.length) return def;

          final data = row[idx];
          if (data == null) return def;

          final raw = data.value; // dynamic

          if (raw is num) {
            return (raw as num).round();
          }

          final s = raw
              .toString()
              .replaceAll(',', '')
              .replaceAll('원', '')
              .replaceAll('₩', '')
              .trim();

          return int.tryParse(s) ?? def;
        }

        // ===============================
        // 🔥 컬럼 매핑 (새 엑셀 구조 기준)
        // ===============================
        final dealDateRaw = _s(0); // 거래일자
        final client = _s(1);      // 거래처
        final category = _s(2);    // 구분
        final name = _s(3);        // 제품명
        final manufacturer = _s(4); // 제조사
        int quantity = _i(5, def: 1); // 수량
        final unit = _s(6);        // 단위
        int totalPrice = _i(7, def: 0); // 총금액
        final note = _s(8);        // 비고

        // -------------------------------
        // 안내/예시 행 2차 방어
        // -------------------------------
        if (dealDateRaw.startsWith('예') ||
            name == '필수' ||
            name == '선택' ||
            name.isEmpty) {
          _notify(onProgress, processed, totalRows);
          continue;
        }

        // -------------------------------
        // 수량/금액 뒤바뀐 경우 자동 복구
        // -------------------------------
        if (quantity > 10000 && totalPrice <= 10) {
          totalPrice = quantity;
          quantity = 1;
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
          'spec': null,        // ❌ 더 이상 사용 안 함
          'unit': unit,        // ✅ 단위 저장
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
