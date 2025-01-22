// ignore_for_file: use_build_context_synchronously

import 'dart:developer';

import 'package:blocks_guide/helpers/connection_provider.dart';
import 'package:connect_to_sql_server_directly/connect_to_sql_server_directly.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConnectionHelper {
  Future<void> checkInitialConnection(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    print('checkInitialConnection');
    bool isConnected = false;

    print('isConnected:checkInitialConnection: $isConnected');

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

        log('checkInitialConnection isConnected after initialize >>> $isConnected');
        final checkConnectivityStatus = await checkConnectivity();

        if (isConnected) {
          print('connected to the database');

          try {
            final testResponse = await connectToSqlServerDirectlyPlugin
                .getRowsOfQueryResult("SELECT TOP 1 * FROM Product");
            isConnected = testResponse != null && testResponse is List;
            log('Query Validation Passed: $isConnected');
          } catch (queryError) {
            Provider.of<ConnectionProvider>(context)
                .updateConnectionStatus(context, isConnected = false);
            log('Query Validation Failed: $queryError');
            isConnected = false;
          }
        } else {
          print('Failed to connect to the database');
          // showDatabasePopup(context);
          // Provider.of<ConnectionProvider>(context)
          //     .updateConnectionStatus(context, isConnected = false);
          // try {
          //   await connectToSqlServerDirectlyPlugin.initializeConnection(
          //     serverIp,
          //     database,
          //     username,
          //     password,
          //     instance: '',
          //   );
          // } catch (e) {
          //   print('Failed to connect to the database: $e');
          //   if (context.mounted) {
          //     ScaffoldMessenger.of(context).showSnackBar(
          //       const SnackBar(
          //         content: Text('Please Check Your Credentials'),
          //         backgroundColor: Colors.red,
          //       ),
          //     );
          //   }
          // }
        }
      } catch (e) {
        isConnected = false;
        log('Failed to connect at startup: $e');
      }
    }
    // prefs.setBool('isConnected', isConnected);
    await Provider.of<ConnectionProvider>(context, listen: false)
        .updateConnectionStatus(context, isConnected!);

    log('Connection status updated: $isConnected');
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
