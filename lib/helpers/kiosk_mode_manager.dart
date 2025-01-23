// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:connect_to_sql_server_directly/connect_to_sql_server_directly.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'connection_provider.dart';

class KioskModeManager {
  // static const platform = MethodChannel('com.eratech.blocks_price_check/kiosk_mode');
  static Timer? _popupTimer;
  static bool testSuccess = false; // Flag for successful test connection

  static const MethodChannel platform = MethodChannel('com.eratech.blocks_price_check/kiosk_mode');

  // Function to start Kiosk Mode
  static Future<void> startKioskMode() async {
    try {
      var result = await platform.invokeMethod('startKioskMode');
      log("Kiosk Mode started: $result");
    } on PlatformException catch (e) {
      log("Failed to start Kiosk Mode: '${e.message}'.");
    }
  }

  // Function to stop Kiosk Mode
  static Future<void> stopKioskMode() async {
    try {
      var result = await platform.invokeMethod('stopKioskMode');
      log("Kiosk Mode stopped: $result");
    } on PlatformException catch (e) {
      log("Failed to stop Kiosk Mode: '${e.message}'.");
    }
  }

  // // Call this to start Kiosk Mode
  // static Future<void> startKioskMode() async {
  //   try {
  //     await platform.invokeMethod('startKioskMode');
  //   } on PlatformException catch (e) {
  //     print("Failed to start Kiosk Mode: '${e.message}'.");
  //   }
  // }

  // // Call this to stop Kiosk Mode
  // static Future<void> stopKioskMode() async {
  //   try {
  //     await platform.invokeMethod('stopKioskMode');
  //   } on PlatformException catch (e) {
  //     print("Failed to stop Kiosk Mode: '${e.message}'.");
  //   }
  // }

  // Show password dialog and handle Kiosk Mode exit
  Future<void> showPasswordDialog(BuildContext context) async {
    TextEditingController passwordController = TextEditingController();
    FocusNode passwordFocusNode = FocusNode();

    // Automatically close after 10 seconds of inactivity
    startPopupTimeout(context, duration: const Duration(seconds: 10));

    showGeneralDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal by tapping outside the dialog
      barrierColor: Colors.black.withOpacity(0.5), // Background color
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: AlertDialog(
            title: const Text('Enter Password'),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.3, // Adjust width
              child: TextField(
                focusNode: passwordFocusNode,
                autofocus: true,
                controller: passwordController,
                obscureText: true, // Hide password
                decoration: const InputDecoration(
                  hintText: 'Enter password',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                ),
                onChanged: (value) {
                  resetPopupTimeout(context,
                      duration: const Duration(seconds: 10)); // Reset timer on typing
                },
                onSubmitted: (value) async {
                  if (passwordController.text == '1234') {
                    Navigator.of(context).pop(); // Close the password dialog
                    showDatabasePopup(context); // Show the new popup
                  } else {
                    passwordController.clear(); // Clear the password field
                    passwordFocusNode.requestFocus(); // Request focus again
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Incorrect Password')),
                    );
                  }
                },
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
              ),
              TextButton(
                child: const Text('OK'),
                onPressed: () async {
                  if (passwordController.text == '1234') {
                    Navigator.of(context).pop(); // Close the password dialog
                    showDatabasePopup(context); // Show the new popup
                  } else {
                    passwordController.clear(); // Clear the password field
                    passwordFocusNode.requestFocus(); // Request focus again
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Incorrect Password')),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );

    // Make sure the text field is focused initially
    passwordFocusNode.requestFocus();
  }

  Future<void> showDatabasePopup(BuildContext context) async {
    final connectToSqlServerDirectlyPlugin = ConnectToSqlServerDirectly();
    bool connect = false;

    TextEditingController serverController = TextEditingController();
    TextEditingController databaseController = TextEditingController();
    TextEditingController usernameController = TextEditingController();
    TextEditingController passwordController = TextEditingController();

    // final connectionProvider = context.read<ConnectionProvider>();

    // Load saved preferences and display them in the text fields
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    serverController.text = prefs.getString('serverIp') ?? '';
    databaseController.text = prefs.getString('database') ?? '';
    usernameController.text = prefs.getString('userName') ?? '';
    passwordController.text = prefs.getString('password') ?? '';

    // Function to test connection
    Future<bool> testConnection(BuildContext context, Function setState) async {
      bool isConnected = false; // Variable to hold connection status

      try {
        connect = await connectToSqlServerDirectlyPlugin.initializeConnection(
          serverController.text,
          databaseController.text,
          usernameController.text,
          passwordController.text,
          instance: '',
        );
      } catch (e) {
        print('Failed to connect to the database: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please Check Your Credentials'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false; // Return false if connection fails
      }

      final response = await connectToSqlServerDirectlyPlugin
          .getRowsOfQueryResult("SELECT TOP 1 * FROM Product;");
      isConnected = !response.toString().contains('java');

      if (context.mounted) {
        if (isConnected) {
          setState(() {}); // Update the state to enable the Update button
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully connected to the server'),
              backgroundColor: Colors.green,
            ),
          );
          // debugNetworkInterfaces();
          // getDeviceIPAddress();
        } else {
          setState(() {}); // Update the state to keep the Update button disabled
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to connect to the server'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      return isConnected; // Return the connection status
    }

    // Function to show warning when canceling after a successful connection
    Future<bool> showCancelWarning(BuildContext context) async {
      return await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Warning'),
                content: const Text(
                    'You have successfully connected to the server. If you cancel, the connection will be lost. Do you want to proceed?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('No'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Yes'),
                  ),
                ],
              );
            },
          ) ??
          false;
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Database Server'),
                content: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () async {
                              await stopKioskMode();
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Kiosk Mode Disabled.')),
                              );
                            },
                            child: const Text('Exit to OS'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildTextField(context,
                            autofocus: true, controller: serverController, labelText: 'Server *'),
                        const SizedBox(height: 10),
                        _buildTextField(context,
                            controller: databaseController, labelText: 'Database *'),
                        const SizedBox(height: 10),
                        _buildTextField(context,
                            controller: usernameController, labelText: 'Username *'),
                        const SizedBox(height: 10),
                        _buildTextField(context,
                            controller: passwordController,
                            labelText: 'Password *',
                            obscureText: true),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    child: const Text('Test Connection'),
                    onPressed: () async {
                      bool status = await testConnection(context, setState);
                      print('testConnection: $status');
                      Provider.of<ConnectionProvider>(context)
                          .updateConnectionStatus(status);
                    },
                  ),
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () async {
                      if (connect) {
                        // Show warning if connected successfully
                        bool proceed = await showCancelWarning(context);
                        if (proceed) {
                          Navigator.of(context).pop(); // Close the dialog
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.clear(); // Clear the preferences on cancel
                          testConnection(context, setState);
                          // connectionProvider.updateConnectionStatus(
                          //     false, context); // Update the connection status to false
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Connection lost'), backgroundColor: Colors.red),
                          );
                        }
                      } else {
                        Navigator.of(context).pop(); // Close the dialog without warning
                      }
                    },
                  ),
                  ElevatedButton(
                    onPressed: connect
                        ? () async {
                            // Save connection data and update settings
                            await _handleUpdate(context, serverController, databaseController,
                                usernameController, passwordController);
                          }
                        : null, // Disable if not connected
                    child: const Text('Update'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // Future<bool> realTimeTestConnection() async {
  //   // Instantiate the plugin
  //   final connectToSqlServerDirectlyPlugin = ConnectToSqlServerDirectly();

  //   // Initialize the connection status
  //   bool connect = false;

  //   // Create text editing controllers
  //   final TextEditingController serverController = TextEditingController();
  //   final TextEditingController databaseController = TextEditingController();
  //   final TextEditingController usernameController = TextEditingController();
  //   final TextEditingController passwordController = TextEditingController();

  //   // Load saved preferences
  //   final SharedPreferences prefs = await SharedPreferences.getInstance();
  //   serverController.text = prefs.getString('serverIp') ?? '';
  //   databaseController.text = prefs.getString('database') ?? '';
  //   usernameController.text = prefs.getString('userName') ?? '';
  //   passwordController.text = prefs.getString('password') ?? '';

  //   try {
  //     // Initialize connection using the plugin
  //     connect = await connectToSqlServerDirectlyPlugin.initializeConnection(
  //       serverController.text,
  //       databaseController.text,
  //       usernameController.text,
  //       passwordController.text,
  //       instance: '',
  //     );

  //     if (connect) {
  //       // Run a query to verify the connection
  //       final response = await connectToSqlServerDirectlyPlugin
  //           .getRowsOfQueryResult("SELECT TOP 1 * FROM Product;");

  //       // Check the response validity
  //       connect = !response.toString().contains('java');
  //     }

  //     // Log connection status
  //     if (connect) {
  //       log('Successfully connected to the server');
  //     } else {
  //       log('Failed to connect to the server');
  //     }
  //   } catch (e) {
  //     // Handle exceptions
  //     connect = false;
  //     log('Failed to connect to the database: $e');
  //     log('Please check your credentials');
  //   } finally {
  //     // Dispose of the text editing controllers
  //     serverController.dispose();
  //     databaseController.dispose();
  //     usernameController.dispose();
  //     passwordController.dispose();
  //   }

  //   return connect;
  // }
  // connectivity(BuildContext context) {
  //   Connectivity().onConnectivityChanged.listen((ConnectivityResult result) async {
  //     bool connectivity = await ConnectionHelper().checkConnectivity();
  //     log('connectivity $connectivity');
  //     // Got a new connectivity status!
  //     if (connectivity) {
  //       Future.delayed(const Duration(milliseconds: 200)).then((value) {
  //         Provider.of<ConnectionProvider>(context, listen: false)
  //             .updateConnectionStatus(true, context);
  //       });
  //     } else {
  //       Future.delayed(const Duration(milliseconds: 200)).then((value) {
  //         Provider.of<ConnectionProvider>(context, listen: false)
  //             .updateConnectionStatus(false, context);
  //       });
  //     }
  //   });
  // }

  // Future<void> debugNetworkInterfaces() async {
  //   try {
  //     final interfaces = await NetworkInterface.list();
  //     for (var interface in interfaces) {
  //       print('Interface: ${interface.name}');
  //       for (var addr in interface.addresses) {
  //         print('  Address: ${addr.address}, Type: ${addr.type}');
  //       }
  //     }
  //   } catch (e) {
  //     print('Error fetching interfaces: $e');
  //   }
  // }

  // Future<String> getDeviceIPAddress() async {
  //   final info = NetworkInfo();
  //   try {
  //     final wifiIP = await info.getWifiIP(); // Get device IP when connected to WiFi
  //     print('Device IP Address: $wifiIP');
  //     return wifiIP ?? '';
  //   } catch (e) {
  //     log('Error fetching device IP address: $e');
  //     return '';
  //   }
  // }

  // Future<bool> realTimeTestConnection() async {
  //   // Instantiate the plugin
  //   final connectToSqlServerDirectlyPlugin = ConnectToSqlServerDirectly();

  //   // Initialize the connection status
  //   bool connect = false;

  //   // Create text editing controllers
  //   final TextEditingController serverController = TextEditingController();
  //   final TextEditingController databaseController = TextEditingController();
  //   final TextEditingController usernameController = TextEditingController();
  //   final TextEditingController passwordController = TextEditingController();

  //   // Load saved preferences
  //   final SharedPreferences prefs = await SharedPreferences.getInstance();
  //   serverController.text = prefs.getString('serverIp') ?? '';
  //   databaseController.text = prefs.getString('database') ?? '';
  //   usernameController.text = prefs.getString('userName') ?? '';
  //   passwordController.text = prefs.getString('password') ?? '';

  //   // Fetch the device's current IP address
  //   final String currentDeviceIP = await getDeviceIPAddress();
  //   print('Current device IP Address: $currentDeviceIP');
  //   log('match ${serverController.text} currentDeviceIP $currentDeviceIP');
  //   if (serverController.text != currentDeviceIP) {
  //     log('Given IP does not match the device IP. Connection will remain false.');
  //     return false;
  //   }

  //   try {
  //     // Initialize connection using the plugin
  //     connect = await connectToSqlServerDirectlyPlugin.initializeConnection(
  //       serverController.text,
  //       databaseController.text,
  //       usernameController.text,
  //       passwordController.text,
  //       instance: '',
  //     );
  //     log('connectToSqlServerDirectlyPlugin $connect');
  //     if (connect) {
  //       // Run a query to verify the connection
  //       final response = await connectToSqlServerDirectlyPlugin
  //           .getRowsOfQueryResult("SELECT TOP 1 * FROM Product;");
  //       log('response ${connect.toString()}');
  //       // Check the response validity
  //       connect = !response.toString().contains('java');
  //     }

  //     // Log connection status
  //     if (connect) {
  //       log('Successfully connected to the server');
  //     } else {
  //       log('Failed to connect to the server');
  //     }
  //   } catch (e) {
  //     // Handle exceptions
  //     connect = false;
  //     log('Failed to connect to the database: $e');
  //     log('Please check your credentials');
  //   } finally {
  //     // Dispose of the text editing controllers
  //     serverController.dispose();
  //     databaseController.dispose();
  //     usernameController.dispose();
  //     passwordController.dispose();
  //   }

  //   return connect;
  // }

  static Widget _buildTextField(BuildContext context,
      {required TextEditingController controller,
      required String labelText,
      bool obscureText = false,
      bool autofocus = false}) {
    return TextField(
      autofocus: autofocus,
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      ),
    );
  }

  static Future<void> _handleUpdate(
      BuildContext context,
      TextEditingController serverController,
      TextEditingController databaseController,
      TextEditingController usernameController,
      TextEditingController passwordController) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (serverController.text.isNotEmpty &&
        databaseController.text.isNotEmpty &&
        usernameController.text.isNotEmpty &&
        passwordController.text.isNotEmpty) {
      // Store connection data
      prefs.setString('serverIp', serverController.text);
      prefs.setString('database', databaseController.text);
      prefs.setString('userName', usernameController.text);
      prefs.setString('password', passwordController.text);
      Navigator.of(context).pop(); // Close the dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings Updated')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required')),
      );
    }
  }

// Timer to automatically close popups after a specified duration
  static void startPopupTimeout(BuildContext context, {required Duration duration}) {
    _popupTimer?.cancel(); // Cancel any existing timer

    _popupTimer = Timer(duration, () {
      // Check if context is still mounted to avoid calling Navigator on disposed context
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // Automatically close the popup
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Popup closed due to inactivity')),
        );
      }
    });
  }

  // Reset the popup timeout
  static void resetPopupTimeout(BuildContext context, {required Duration duration}) {
    _popupTimer?.cancel(); // Cancel the current timer
    startPopupTimeout(context, duration: duration); // Restart the timer with the same duration
  }
}
