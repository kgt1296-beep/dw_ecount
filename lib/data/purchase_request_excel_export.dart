import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

import '../models/purchase_request_item.dart';

class PurchaseRequestExcelExport {
  static Future<void> export({
    required String purchaseNo,
    required String vendor,
    required String manager,
    required String memo,
    required List<PurchaseRequestItem> items,
  }) async {
    final excel = Excel.createExcel();

    // ===============================
    // 시트 생성
    // ===============================
    final sheet = excel['견적요청서'];

    // 기본 Sheet1 제거
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    // ===============================
    // 헤더 정보
    // ===============================
    sheet.appendRow([
      TextCellValue('발주번호'),
      TextCellValue(purchaseNo),
    ]);
    sheet.appendRow([
      TextCellValue('거래처'),
      TextCellValue(vendor),
    ]);
    sheet.appendRow([
      TextCellValue('담당자'),
      TextCellValue(manager),
    ]);
    sheet.appendRow([
      TextCellValue('비고'),
      TextCellValue(memo),
    ]);

    sheet.appendRow([]); // 빈 줄

    // ===============================
    // 테이블 헤더
    // ===============================
    sheet.appendRow([
      TextCellValue('분류'),
      TextCellValue('제품명'),
      TextCellValue('수량'),
      TextCellValue('단위'),
      TextCellValue('비고'),
      TextCellValue('단가'), // 🔥 회신용
      TextCellValue('금액'), // 🔥 회신용
    ]);

    // ===============================
    // 품목 데이터
    // ===============================
    for (final it in items) {
      sheet.appendRow([
        TextCellValue(it.category),
        TextCellValue(it.productName),
        DoubleCellValue(it.quantity),
        TextCellValue(it.unit),
        TextCellValue(it.note),
        TextCellValue(''), // 단가 (업체 입력)
        TextCellValue(''), // 금액 (업체 입력)
      ]);
    }

    // ===============================
    // 저장
    // ===============================
    final path = await FilePicker.platform.saveFile(
      dialogTitle: '견적요청서 저장',
      fileName: '$purchaseNo.xlsx',
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (path == null) return;

    final bytes = excel.encode();
    if (bytes == null) return;

    await File(path).writeAsBytes(bytes, flush: true);
  }
}
