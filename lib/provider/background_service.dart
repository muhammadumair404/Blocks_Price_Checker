import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

void startBackgroundService() {
  final service = FlutterBackgroundService();
  service.startService();
}

void stopBackgroundService() {
  final service = FlutterBackgroundService();
  service.invoke("stop");
}

Future<void> initializeService() async {
  // startIsolateService();
  final service = FlutterBackgroundService();

  await service.configure(
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
    androidConfiguration: AndroidConfiguration(
      autoStart: true,
      onStart: onStart,
      isForegroundMode: true,
      autoStartOnBoot: true,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized(); // Add this line
  DartPluginRegistrant.ensureInitialized(); // Also ensure plugin registration
  service.on("stop").listen((event) {
    service.stopSelf();
    log("background process is now stopped");
  });

  service.on("start").listen((event) {});
  log("service is successfully running first ${DateTime.now().second}");

  Timer.periodic(const Duration(seconds: 20), (timer) async {
    log("service is successfully running timer ${DateTime.now().second}");
    await fetchData();
  });
}

Future<void> fetchData() async {
  // Fetch data from the server
}
