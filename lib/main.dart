import 'package:blocks_guide/screen/scan_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kiosk_mode/kiosk_mode.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await startKioskMode();

  runApp(ScreenUtilInit(
      designSize: const Size(1280, 752),
      minTextAdapt: true,
      splitScreenMode: true,
      // Use builder only if you need to use library outside ScreenUtilInit context
      builder: (ctx, child) {
        ScreenUtil.init(ctx);
        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: ScanScreen(),
        );
      }));
}
