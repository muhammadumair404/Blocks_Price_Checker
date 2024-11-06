import 'package:blocks_guide/helpers/connection_provider.dart';
import 'package:blocks_guide/screen/scan_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.delayed(const Duration(seconds: 2)); // Set delay duration
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectionProvider()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(1280, 752),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (ctx, child) {
          ScreenUtil.init(ctx);
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: ScanScreen(),
          );
        },
      ),
    ),
  );
}
