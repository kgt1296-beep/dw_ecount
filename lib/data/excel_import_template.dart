import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

class ExcelImportTemplate {
  /// 🔥 엑셀 헤더 (순서 엄격)
  static const headers = [
    '거래일자',   // A
    '거래처',     // B
    '분류',       // C
    '제조사',     // D
    '제품명',     // E
    '수량',       // G
    '총금액',     // H
    '비고',       // J
  ];

  static Future<void> downloadTemplate() async {
    final excel = Excel.createExcel();

    // ===============================
    // 가격표 시트 생성
    // ===============================
    final sheet = excel['가격표'];
    excel.setDefaultSheet('가격표');

    // 기본 Sheet1 제거
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    // ===============================
    // 헤더 행
    // ===============================
    sheet.appendRow(
      headers.map((e) => TextCellValue(e)).toList(),
    );

    // ===============================
    // 안내 행
    // ===============================
    sheet.appendRow([
      TextCellValue('예: 2025-10-30 또는 20241030'),
      TextCellValue('필수'),
      TextCellValue('선택'),
      TextCellValue('선택'),
      TextCellValue('필수'),
      TextCellValue('숫자 (기본 1)'),
      TextCellValue('숫자'),
      TextCellValue('선택'),
    ]);

    // ===============================
    // 저장
    // ===============================
    final path = await FilePicker.platform.saveFile(
      dialogTitle: '엑셀 Import 템플릿 저장',
      fileName: '가격표_import_template.xlsx',
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (path == null) return;

    final bytes = excel.encode();
    if (bytes == null) return;

    await File(path).writeAsBytes(bytes, flush: true);
  }
}
