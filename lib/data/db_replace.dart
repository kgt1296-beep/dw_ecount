import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DBReplaceService {
  static const _pendingKey = 'pending_db_replace';
  static const _dbFileName = 'dw_ecount.db';
  static const _pendingFileName = 'pending_replace.db';

  /// 실행 중 교체 ❌ → 교체 예약(파일 복사 + 플래그 저장)
  static Future<void> requestReplace() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'DB 파일 선택',
      type: FileType.custom,
      allowedExtensions: ['db'],
    );

    if (result == null) return;

    final source = File(result.files.single.path!);

    final dir = await getApplicationSupportDirectory();
    final pendingFile = File('${dir.path}/$_pendingFileName');

    await source.copy(pendingFile.path);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pendingKey, true);
  }

  /// 앱 시작 직후(= DB 열기 전)에만 호출해야 함
  static Future<void> applyPendingReplaceIfNeeded() async {
    print('🔍 DB replace check start');

    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getBool(_pendingKey) ?? false;

    print('pending flag: $pending');

    if (!pending) return;

    final dir = await getApplicationSupportDirectory();
    print('DB dir: ${dir.path}');

    final target = File('${dir.path}/$_dbFileName');
    final pendingFile = File('${dir.path}/$_pendingFileName');

    print('target exists: ${target.existsSync()}');
    print('pending exists: ${pendingFile.existsSync()}');

    if (target.existsSync()) {
      await target.delete();
    }

    await pendingFile.rename(target.path);
    await prefs.remove(_pendingKey);

    print('✅ DB replaced');
  }

}
