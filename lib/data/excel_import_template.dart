import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

class ExcelImportTemplate {
  /// 🔥 엑셀 헤더 (네가 원하는 구조와 1:1 일치)
  static const headers = [
    '거래일자',
    '거래처',
    '구분',
    '제품명',
    '제조사',
    '수량',
    '단위',
    '총금액',
    '비고',
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
    // 안내 행 (🔥 Import에서 스킵됨)
    // ===============================
    sheet.appendRow([
      TextCellValue('예: 2025-10-30 또는 20241030'), // 거래일자
      TextCellValue('필수'),                       // 거래처
      TextCellValue('선택'),                       // 구분
      TextCellValue('필수'),                       // 제품명
      TextCellValue('선택'),                       // 제조사
      TextCellValue('숫자 (기본 1)'),               // 수량
      TextCellValue('예: EA, BOX, SET'),            // 단위
      TextCellValue('숫자'),                       // 총금액
      TextCellValue('선택'),                       // 비고
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
