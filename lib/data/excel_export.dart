import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

import '../utils/date_utils.dart';
import '../models/product.dart';

class ExcelExport {
  static Future<void> exportProducts(List<Product> products) async {
    final excel = Excel.createExcel();

    // ===============================
    // 연도별 그룹핑
    // ===============================
    final Map<String, List<Product>> byYear = {};

    for (final p in products) {
      final year = _extractYear(p.dealDate) ?? '미분류';
      byYear.putIfAbsent(year, () => []);
      byYear[year]!.add(p);
    }

    bool defaultSheetSet = false;

    // ===============================
    // 시트 생성 (연도별)
    // ===============================
    for (final entry in byYear.entries) {
      final year = entry.key;
      final list = entry.value;

      final sheet = excel[year];

      // 🔥 첫 연도 시트를 default sheet로 지정
      if (!defaultSheetSet) {
        excel.setDefaultSheet(year);
        defaultSheetSet = true;
      }

      // ---- 헤더 ----
      sheet.appendRow([
        TextCellValue('거래일자'),
        TextCellValue('거래처'),
        TextCellValue('구분'),
        TextCellValue('제품명'),
        TextCellValue('제조사'),
        TextCellValue('수량'),
        TextCellValue('단위'),
        TextCellValue('총금액'),
        TextCellValue('개당단가'),
        TextCellValue('비고'),
      ]);

      // ---- 데이터 ----
      for (final p in list) {
        sheet.appendRow([
          TextCellValue(formatDealDate(p.dealDate)),
          TextCellValue(p.client ?? ''),
          TextCellValue(p.category ?? ''),
          TextCellValue(p.name),
          TextCellValue(p.manufacturer ?? ''),
          IntCellValue(p.quantity),
          TextCellValue(p.unit ?? ''),
          IntCellValue(p.totalPrice),
          IntCellValue(p.unitPrice),
          TextCellValue(p.note ?? ''),
        ]);
      }
    }

    // ===============================
    // 🔥 Sheet1 완전 제거 (마지막에!)
    // ===============================
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    // ===============================
    // 저장
    // ===============================
    final result = await FilePicker.platform.saveFile(
      dialogTitle: '엑셀 저장',
      fileName: 'dw_price_list.xlsx',
      allowedExtensions: ['xlsx'],
      type: FileType.custom,
    );

    if (result == null) return;

    final bytes = excel.encode();
    if (bytes == null) return;

    final file = File(result);
    await file.writeAsBytes(bytes, flush: true);
  }

  static String? _extractYear(String? date) {
    if (date == null || date.length < 4) return null;
    return date.substring(0, 4);
  }
}
