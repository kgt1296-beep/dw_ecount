import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app.dart';
import 'core/app_state.dart';
import 'data/db_replace.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 1️⃣ DB 교체 예약 처리 (반드시 DB 열기 전에!)
  await DBReplaceService.applyPendingReplaceIfNeeded();

  // 🔥 2️⃣ Windows SQLite FFI 초기화
  if (Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // 🔥 3️⃣ 앱 실행 (단 한 번만!)
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: const DWApp(),
    ),
  );
}
