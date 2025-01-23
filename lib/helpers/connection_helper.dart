// ignore_for_file: use_build_context_synchronously

import 'dart:developer';

import 'package:blocks_guide/helpers/connection_provider.dart';
import 'package:connect_to_sql_server_directly/connect_to_sql_server_directly.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
class ConnectionHelper {
  Future<void> checkInitialConnection(
      ConnectionProvider connectionProvider) async {
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
        isConnected = await connectToSqlServerDirectlyPlugin.initializeConnection(
            serverIp, database, username, password);

        log('Database connection initialized: $isConnected');

        if (isConnected) {
          log('Connected to the database');
          try {
            final testResponse = await connectToSqlServerDirectlyPlugin
                .getRowsOfQueryResult("SELECT TOP 1 * FROM Product");
           // isConnected = testResponse != null && testResponse is List;

            if (testResponse != null) {
              log('Query Validation Passed');
              connectionProvider.updateConnectionStatus(true);
            } else {
              log('Query Validation Failed');
            }
          } catch (queryError) {
            log('Query Execution Error: $queryError');
          }
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

    log('Final connection status: ${connectionProvider.isConnected}');
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
