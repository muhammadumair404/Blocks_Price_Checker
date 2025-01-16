import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConnectionProvider with ChangeNotifier {
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  void updateConnectionStatus(bool status) {
    storeConnection(status);
    log('updateConnectionStatus - status: $status');
    _isConnected = status;
    notifyListeners();
  }

  storeConnection(bool isConnected) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isConnected', isConnected);
    log('storeConnection - status: ${prefs.getBool('isConnected')}');
  }
}
