// ignore_for_file: use_build_context_synchronously

import 'dart:developer';

import 'package:blocks_guide/helpers/connection_provider.dart';
import 'package:connect_to_sql_server_directly/connect_to_sql_server_directly.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConnectionHelper {
  Future<void> checkInitialConnection(ConnectionProvider connectionProvider) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    log('checkInitialConnection started');
    bool isConnected = false;

    if (prefs.containsKey('serverIp') &&
        prefs.containsKey('database') &&
        prefs.containsKey('userName') &&
        prefs.containsKey('password')) {
      final serverIp = prefs.getString('serverIp')!;
      final database = prefs.getString('database')!;
      final username = prefs.getString('userName')!;
      final password = prefs.getString('password')!;

      try {
        final connectToSqlServerDirectlyPlugin = ConnectToSqlServerDirectly();
        final response = await connectToSqlServerDirectlyPlugin
            .getRowsOfQueryResult("SELECT TOP 1 * FROM Products;");
        isConnected = !response.toString().contains('java');

        log('Database connection initialized: $isConnected');

        if (isConnected) {
          log('successfully connect to the database');

          connectionProvider.updateConnectionStatus(true);
        } else {
          log('Failed to connect to the database');
          connectionProvider.updateConnectionStatus(false);
        }
      } catch (e) {
        log('Database connection error: $e');
        connectionProvider.updateConnectionStatus(false);
      }
    } else {
      log('Missing database credentials in SharedPreferences');
      connectionProvider.updateConnectionStatus(false);
    }

    log('Final connection status: $isConnected');
  }

  // check internet connectivity
  Future<bool> checkConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.ethernet) {
      return true;
    } else {
      return false;
    }
  }
}
