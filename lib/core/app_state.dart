import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  bool isAdmin = false;

  void enableAdmin() {
    isAdmin = true;
    notifyListeners();
  }

  void disableAdmin() {
    isAdmin = false;
    notifyListeners();
  }
}
