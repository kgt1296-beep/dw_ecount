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
    final sheet = excel['견적요청서'];

    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    // ======================================================
    //  🎨 스타일 및 테두리 정의
    // ======================================================
    final ExcelColor blackColor = ExcelColor.fromHexString('FF000000');
    final ExcelColor grayBg = ExcelColor.fromHexString('FFEFEFEF');

    // 테두리 객체 미리 생성
    final Border borderThin = Border(borderStyle: BorderStyle.Thin, borderColorHex: blackColor);
    final Border borderMedium = Border(borderStyle: BorderStyle.Medium, borderColorHex: blackColor);
    final Border borderNone = Border(borderStyle: BorderStyle.None);

    // 1. 제목 스타일
    final CellStyle titleStyle = CellStyle(
      bold: true,
      fontSize: 24,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      bottomBorder: borderMedium,
    );

    // 2. 우측 상단 정보 스타일
    final CellStyle infoLabelStyle = CellStyle(
      fontSize: 10,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: grayBg,
      leftBorder: borderThin,
      rightBorder: borderThin,
      topBorder: borderThin,
      bottomBorder: borderThin,
    );

    final CellStyle infoValueStyle = CellStyle(
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: borderThin,
      rightBorder: borderMedium,
      topBorder: borderThin,
      bottomBorder: borderThin,
    );

    // 3. 테이블 헤더 스타일
    final CellStyle tableHeaderStyle = CellStyle(
      bold: true,
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: grayBg,
      leftBorder: borderThin,
      rightBorder: borderThin,
      topBorder: borderMedium,
      bottomBorder: borderMedium,
    );

    // 4. 비고 헤더 (A열)
    final CellStyle memoHeaderStyle = CellStyle(
      bold: true,
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: grayBg,
      topBorder: borderMedium,
      leftBorder: borderMedium,
      rightBorder: borderThin,
      bottomBorder: borderMedium,
    );

    // 🔥 [수정] 스타일 생성 헬퍼 함수 (기존 스타일 읽지 않고 새로 생성)
    CellStyle makeDataStyle({
      required HorizontalAlign align,
      Border? left,
      Border? right,
      Border? top,
      Border? bottom,
      bool wrap = false,
    }) {
      return CellStyle(
        fontSize: 11,
        verticalAlign: VerticalAlign.Center,
        horizontalAlign: align,
        textWrapping: wrap ? TextWrapping.WrapText : TextWrapping.Clip, // NoWrap 대신 Clip 사용
        leftBorder: left ?? borderThin,
        rightBorder: right ?? borderThin,
        topBorder: top ?? borderThin,
        bottomBorder: bottom ?? borderThin,
      );
    }

    // ======================================================
    //  📏 컬럼/행 설정
    // ======================================================
    sheet.setColumnWidth(0, 15);
    sheet.setColumnWidth(1, 45);
    sheet.setColumnWidth(2, 10);
    sheet.setColumnWidth(3, 10);
    sheet.setColumnWidth(4, 15);
    sheet.setColumnWidth(5, 15);

    sheet.setRowHeight(0, 30);
    sheet.setRowHeight(1, 30);
    sheet.setRowHeight(2, 30);

    // ======================================================
    //  1. 상단 제목
    // ======================================================
    sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('D3'), customValue: TextCellValue('대욱이엔씨 견적요청서'));
    sheet.cell(CellIndex.indexByString('A1')).cellStyle = titleStyle;

    // ======================================================
    //  2. 우측 상단 정보
    // ======================================================
    void drawInfoRow(int rowIndex, String label, String value) {
      _fillCell(sheet, 4, rowIndex, label, infoLabelStyle);
      _fillCell(sheet, 5, rowIndex, value, infoValueStyle);
    }
    drawInfoRow(0, '발주 번호', purchaseNo);
    drawInfoRow(1, '거래처', vendor);
    drawInfoRow(2, '담당자', manager);

    // ======================================================
    //  3. 테이블 헤더
    // ======================================================
    final int headerRowIndex = 3;
    final headers = ['분류', '제품명', '수량', '단위', '단가', '금액'];
    sheet.setRowHeight(headerRowIndex, 25);
    for (int i = 0; i < headers.length; i++) {
      _fillCell(sheet, i, headerRowIndex, headers[i], tableHeaderStyle);
    }

    // ======================================================
    //  4. 품목 데이터 입력
    // ======================================================
    int currentRow = headerRowIndex + 1;
    const int minRows = 18;
    int totalRowsToDraw = (items.length > minRows) ? items.length : minRows;
    int marginIndex = items.length; // 이하여백이 들어갈 상대 위치

    for (int i = 0; i < totalRowsToDraw + 1; i++) {
      sheet.setRowHeight(currentRow, 22);

      if (i < items.length) {
        // 데이터 있음
        final item = items[i];
        _fillCell(sheet, 0, currentRow, item.category, makeDataStyle(align: HorizontalAlign.Center));
        _fillCell(sheet, 1, currentRow, item.productName, makeDataStyle(align: HorizontalAlign.Left));
        _fillCell(sheet, 2, currentRow, item.quantity, makeDataStyle(align: HorizontalAlign.Center), isNumber: true);
        _fillCell(sheet, 3, currentRow, item.unit, makeDataStyle(align: HorizontalAlign.Center));
        _fillCell(sheet, 4, currentRow, '', makeDataStyle(align: HorizontalAlign.Right));
        _fillCell(sheet, 5, currentRow, '', makeDataStyle(align: HorizontalAlign.Right));
      } else if (i == marginIndex) {
        // [이하 여백] 행 - 텍스트만 넣고 병합 (테두리는 마지막에)
        sheet.merge(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
          CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow),
          customValue: TextCellValue('----------  이  하  여  백  ----------'),
        );
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).cellStyle = makeDataStyle(align: HorizontalAlign.Center);
      } else {
        // 빈 줄
        for (int col = 0; col < 6; col++) {
          HorizontalAlign align = (col == 1) ? HorizontalAlign.Left : HorizontalAlign.Center;
          _fillCell(sheet, col, currentRow, '', makeDataStyle(align: align));
        }
      }
      currentRow++;
    }

    // ======================================================
    //  5. 비고란 (일단 값 넣고 병합)
    // ======================================================
    final int memoRow = currentRow; // 비고란의 행 위치 저장
    sheet.setRowHeight(memoRow, 60);

    // A열 헤더
    _fillCell(sheet, 0, memoRow, '비고', memoHeaderStyle);

    // B~F열 내용 병합
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: memoRow),
      CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: memoRow),
      customValue: TextCellValue(memo),
    );
    // 기본 텍스트 스타일 적용
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: memoRow)).cellStyle = CellStyle(
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Top,
      textWrapping: TextWrapping.WrapText,
    );


    // ====================================================================
    //  🔥 6. [최종 해결책] 테두리 강제 그리기 (직접 스타일 생성)
    // ====================================================================

    // (1) "이하 여백" 행의 테두리 보정
    int marginRowAbsolute = headerRowIndex + 1 + marginIndex;

    for (int col = 0; col <= 5; col++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: marginRowAbsolute));

      // 기존 스타일을 읽지 않고, 우리가 원하는 스타일(Center, 얇은 테두리)로 새로 만듭니다.
      cell.cellStyle = CellStyle(
        fontSize: 11,
        verticalAlign: VerticalAlign.Center,
        horizontalAlign: HorizontalAlign.Center, // 이하 여백은 항상 가운데 정렬
        topBorder: borderThin,
        bottomBorder: borderThin,
        leftBorder: borderThin,   // 내부 셀도 Thin을 줘서 끊김 방지
        rightBorder: borderThin,
      );
    }

    // (2) "비고" 내용란 (B~F열) 테두리 보정
    for (int col = 1; col <= 5; col++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: memoRow));

      // 테두리 결정
      Border left = (col == 1) ? borderThin : borderNone;
      Border right = (col == 5) ? borderMedium : borderNone;

      cell.cellStyle = CellStyle(
        fontSize: 11,
        horizontalAlign: HorizontalAlign.Left, // 비고 내용은 항상 왼쪽 정렬
        verticalAlign: VerticalAlign.Top,      // 위쪽 정렬
        textWrapping: TextWrapping.WrapText,
        topBorder: borderMedium,    // 위쪽 진하게
        bottomBorder: borderMedium, // 아래쪽 진하게
        leftBorder: left,
        rightBorder: right,
      );
    }

    // ======================================================
    //  파일 저장
    // ======================================================
    final String fileName = '${purchaseNo.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')}.xlsx';

    final path = await FilePicker.platform.saveFile(
      dialogTitle: '견적요청서 엑셀 저장',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (path == null) return;

    final bytes = excel.encode();
    if (bytes == null) return;

    await File(path).writeAsBytes(bytes, flush: true);
  }

  // 헬퍼 함수
  static void _fillCell(
      Sheet sheet,
      int col,
      int row,
      dynamic value,
      CellStyle style, {
        bool isNumber = false,
      }) {
    var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));

    if (value == null) {
      cell.value = TextCellValue('');
    } else if (isNumber && value is num) {
      cell.value = DoubleCellValue(value.toDouble());
    } else {
      cell.value = TextCellValue(value.toString());
    }
    cell.cellStyle = style;
  }
}