import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class PurchaseNoGenerator {
  static const _fileName = 'purchase_no_state.json';

  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  /// ✅ 다음 발주번호 생성
  static Future<String> next() async {
    final today = DateFormat('yyyyMMdd').format(DateTime.now());
    int seq = 1;

    final file = await _file();
    if (await file.exists()) {
      final json = jsonDecode(await file.readAsString());
      if (json['date'] == today) {
        seq = (json['seq'] as int) + 1;
      }
    }

    await file.writeAsString(jsonEncode({
      'date': today,
      'seq': seq,
    }));

    return 'DW-$today-${seq.toString().padLeft(3, '0')}';
  }
}
