import 'dart:developer';

import 'package:connect_to_sql_server_directly/connect_to_sql_server_directly.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConnectionHelper {
  Future<void> checkInitialConnection() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isConnected = false;

    if (prefs.containsKey('serverIp') &&
        prefs.containsKey('database') &&
        prefs.containsKey('userName') &&
        prefs.containsKey('password')) {
      final serverIp = prefs.getString('serverIp')!;
      final database = prefs.getString('database')!;
      final username = prefs.getString('userName')!;
      final password = prefs.getString('password')!;

      // try {
      //   final connectToSqlServerDirectlyPlugin = ConnectToSqlServerDirectly();
      //   isConnected = await connectToSqlServerDirectlyPlugin.initializeConnection(
      //       serverIp, database, username, password);

      //   log('checkInitialConnection isConnected >>> $isConnected');
      //   final checkConnectivityStatus = await checkConnectivity();
      //   if (isConnected && checkConnectivityStatus) {
      //     final testResponse = await connectToSqlServerDirectlyPlugin
      //         .getRowsOfQueryResult("SELECT TOP 1 * FROM Product");
      //     isConnected = testResponse != null && testResponse is List;
      //     // log('Test Response $testResponse');
      //   } else {
      //     isConnected = false;
      //   }
      // } catch (e) {
      //   isConnected = false;
      //   log('Failed to connect at startup: $e');
      // }12341
      try {
        final connectToSqlServerDirectlyPlugin = ConnectToSqlServerDirectly();
        isConnected = await connectToSqlServerDirectlyPlugin.initializeConnection(
            serverIp, database, username, password);

        // log('checkInitialConnection isConnected after initialize >>> $isConnected');
        final checkConnectivityStatus = await checkConnectivity();

        if (isConnected && checkConnectivityStatus) {
          try {
            final testResponse =
                await connectToSqlServerDirectlyPlugin.getRowsOfQueryResult("SELECT 1");
            isConnected = testResponse != null && testResponse is List;
            log('Query Validation Passed: $isConnected');
          } catch (queryError) {
            log('Query Validation Failed: $queryError');
            isConnected = false;
          }
        }
      } catch (e) {
        isConnected = false;
        log('Failed to connect at startup: $e');
      } finally {
        log('Final connection status before updating prefs: $isConnected');
        // prefs.setBool('isConnected', isConnected);
        // log('Connection status updated: $isConnected');
      }
    }
    prefs.setBool('isConnected', isConnected);
    log('Connection status updated: $isConnected');
  }

  //check internet connectivity
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
