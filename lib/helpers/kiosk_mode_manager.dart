import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KioskModeManager {
  static const platform = MethodChannel('com.example.blocks_guide/kiosk_mode');

  // Call this to start Kiosk Mode
  static Future<void> startKioskMode() async {
    try {
      await platform.invokeMethod('startKioskMode');
    } on PlatformException catch (e) {
      print("Failed to start Kiosk Mode: '${e.message}'.");
    }
  }

  // Call this to stop Kiosk Mode
  static Future<void> stopKioskMode() async {
    try {
      await platform.invokeMethod('stopKioskMode');
    } on PlatformException catch (e) {
      print("Failed to stop Kiosk Mode: '${e.message}'.");
    }
  }

  // Show password dialog and handle Kiosk Mode exit
  static Future<void> showPasswordDialog(BuildContext context) async {
    TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Password'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Enter password'),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () async {
                if (passwordController.text == '1234') {
                  // Replace with actual password logic
                  await stopKioskMode(); // Stop Kiosk Mode
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kiosk Mode Disabled')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Incorrect Password')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
