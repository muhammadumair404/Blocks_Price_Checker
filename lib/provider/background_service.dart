// import 'dart:async';
// import 'dart:developer';
// import 'dart:ui';

// import 'package:blocks_guide/helpers/connection_helper.dart';
// import 'package:blocks_guide/helpers/kiosk_mode_manager.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// void startBackgroundService() {
//   final service = FlutterBackgroundService();
//   service.startService();
// }

// void stopBackgroundService() {
//   final service = FlutterBackgroundService();
//   service.invoke("stop");
// }

// bool isServiceRunning = false;
// Future<void> initializeService() async {
//   // startIsolateService();
//   final service = FlutterBackgroundService();

//   await service.configure(
//     iosConfiguration: IosConfiguration(
//       autoStart: true,
//       onForeground: onStart,
//       onBackground: onIosBackground,
//     ),
//     androidConfiguration: AndroidConfiguration(
//       autoStart: true,
//       onStart: onStart,
//       isForegroundMode: true,
//       autoStartOnBoot: true,
//     ),
//   );
// }

// @pragma('vm:entry-point')
// Future<bool> onIosBackground(ServiceInstance service) async {
//   WidgetsFlutterBinding.ensureInitialized();
//   DartPluginRegistrant.ensureInitialized();

//   return true;
// }

// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) async {
//   WidgetsFlutterBinding.ensureInitialized(); // Add this line
//   DartPluginRegistrant.ensureInitialized(); // Also ensure plugin registration
//   isServiceRunning = true;

//   service.on("start").listen((event) {
//     log("service start event listen $event");
//   });
//   log("service is successfully running first ${DateTime.now().second}");
//   final SharedPreferences prefs = await SharedPreferences.getInstance();
//   await startTask(prefs);
//   Timer.periodic(const Duration(seconds: 5), (timer) async {
//     log("service is successfully running timer ${DateTime.now().second}");

//     bool isServer = await KioskModeManager().realTimeTestConnection();
//     String currentDate = DateTime.now().toIso8601String();

//     service.invoke(
//       'update',
//       {
//         "current_date": currentDate,
//         "isServer": isServer,
//       },
//     );

//     print('isServer $isServer currentDate $currentDate');
//     await startTask(prefs);

//     print("Background service is running");
//     if (!isServiceRunning) {
//       timer.cancel();
//     } else {
//       print("Background service is running");
//     }
//   });

//   service.on("stop").listen((event) {
//     service.stopSelf();
//     isServiceRunning = false;
//     log("background process is now stopped");
//   });
// }

// startTask(SharedPreferences prefs) async {
//   // await prefs.reload();
//   // bool isConnected = prefs.getBool('isConnected') ?? false;

//   // log('Bg service isConnected: $isConnected');
//   // ConnectionHelper().checkInitialConnection();
// }
