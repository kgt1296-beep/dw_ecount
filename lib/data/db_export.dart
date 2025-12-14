import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class DBExportService {
  static const dbFileName = 'dw_ecount.db';

  static Future<void> exportDatabase() async {
    // 현재 DB 위치
    final dir = await getApplicationSupportDirectory();
    final source = File('${dir.path}/$dbFileName');

    if (!source.existsSync()) {
      throw Exception('DB 파일을 찾을 수 없습니다');
    }

    // 저장 위치 선택
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'DB 백업 저장',
      fileName:
      'dw_ecount_backup_${DateTime.now().toIso8601String().substring(0, 10)}.db',
      type: FileType.custom,
      allowedExtensions: ['db'],
    );

    if (path == null) return;

    await source.copy(path);
  }
}
