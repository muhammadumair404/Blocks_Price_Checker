import 'package:flutter/material.dart';

class ConnectionProvider with ChangeNotifier {
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  void updateConnectionStatus(bool status) {
    _isConnected = status;
    notifyListeners();
  }
}
