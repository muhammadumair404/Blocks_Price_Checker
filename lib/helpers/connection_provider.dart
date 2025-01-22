import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConnectionProvider with ChangeNotifier {
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  Future<void> updateConnectionStatus(context, bool status) async {
    storeConnection(status);
    log('updateConnectionStatus - status: $status');
    _isConnected = status;
    log('to know connected status: $_isConnected');

    notifyListeners();
  }

  storeConnection(bool isConnected) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isConnected', isConnected);
    log('storeConnection - status: ${prefs.getBool('isConnected')}');
  }
}
