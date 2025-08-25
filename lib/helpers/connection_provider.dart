import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConnectionProvider with ChangeNotifier {
  bool _isConnected = false;
  // Getter for connection status
  bool get isConnected => _isConnected;

  // Update the connection status and notify listeners
  Future<void> updateConnectionStatus(bool status) async {
    if (_isConnected != status) {
      await _storeConnection(status);
      log('Connection status changed: $_isConnected -> $status');
      _isConnected = status;
      notifyListeners();
    }
  }

  // Store the connection status in SharedPreferences
  Future<void> _storeConnection(bool isConnected) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isConnected', isConnected);
    log('storeConnection - Stored status: $isConnected');
  }

  // Load the connection status from SharedPreferences
  Future<void> loadConnectionStatus() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _isConnected = prefs.getBool('isConnected') ?? false;
    log('loadConnectionStatus - Loaded status: $_isConnected');
    notifyListeners();
  }
}