import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import '../models/purchase_request_item.dart';

class PurchaseRequestDraftStorage {
  static const _fileName = 'purchase_request_draft.json';

  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  static Future<void> save({
    required String purchaseNo,
    required String vendor,
    required String manager,
    required String memo,
    required List<PurchaseRequestItem> items,
  }) async {
    final file = await _file();

    final data = {
      'purchaseNo': purchaseNo,
      'vendor': vendor,
      'manager': manager,
      'memo': memo,
      'items': items.map((e) => e.toJson()).toList(),
    };

    await file.writeAsString(jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> load() async {
    final file = await _file();
    if (!await file.exists()) return null;

    return jsonDecode(await file.readAsString());
  }

  static Future<void> clear() async {
    final file = await _file();
    if (await file.exists()) {
      await file.delete();
    }
  }
}
