import 'package:flutter/material.dart';

import 'screens/price_list_screen.dart';

class DWApp extends StatelessWidget {
  const DWApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DW ECOUNT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blueGrey,
      ),
      home: const PriceListScreen(),
    );
  }
}
