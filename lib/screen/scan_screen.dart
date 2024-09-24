// import 'dart:async';
// import 'dart:developer';
// import 'package:blocks_guide/helpers/connection_provider.dart';
// import 'package:blocks_guide/helpers/kiosk_mode_manager.dart';
// import 'package:connect_to_sql_server_directly/connect_to_sql_server_directly.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:flutter/services.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:provider/provider.dart';

// class ScanScreen extends StatefulWidget {
//   const ScanScreen({super.key});

//   @override
//   State<ScanScreen> createState() => _ScanScreenState();
// }

// class ProductModel {
//   final String keycode;
//   final String sku;
//   final String name;
//   double retailPrice; // For regular price
//   double?
//       specialPrice; // Nullable special price (can be null if no special price is available)

//   ProductModel({
//     required this.keycode,
//     required this.sku,
//     required this.name,
//     required this.retailPrice,
//     this.specialPrice, // Optional field
//   });

//   @override
//   String toString() =>
//       'ProductModel{keycode: $keycode, sku: $sku, name: $name, retailPrice: $retailPrice, specialPrice: $specialPrice}';
// }

// class _ScanScreenState extends State<ScanScreen> with TickerProviderStateMixin {
//   final MethodChannel platform =
//       const MethodChannel('com.example.blocks_guide/kiosk_mode');
//   List<ProductModel> productList = [];
//   bool isLoading = false;
//   final FocusNode _focusNode = FocusNode();
//   TextEditingController controller = TextEditingController();
//   final _connectToSqlServerDirectlyPlugin = ConnectToSqlServerDirectly();
//   String imageUrl = '';

//   List<Color> colorList = [
//     const Color(0xff2A33B5),
//     const Color(0xff5A1C88),
//     const Color(0xff054A72),
//     const Color(0xff0A0848),
//     const Color(0xff4B024D),
//   ];

//   int index = 0;
//   Color bottomColor = const Color(0xff092646);
//   Color topColor = const Color(0xff410D75);
//   late AnimationController _controller;
//   late Animation<double> _animation;
//   late Timer _timer;
//   late AnimationController _colorController;
//   late Animation<Color?> _colorAnimation;
//   List<Color> specialPriceColors = [
//     Colors.green,
//     Colors.red,
//     Colors.orange,
//     Colors.blue,
//   ];
//   Timer? _clearProductTimer; // Timer for clearing the product

//   Future<void> _launchAppOnBoot() async {
//     try {
//       var result = await platform.invokeMethod('startKioskMode');
//       log(result.toString());
//     } on PlatformException catch (e) {
//       print("Failed to invoke method: '${e.message}'.");
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     // Check if already connected to the server
//     _checkInitialConnection();
//     _launchAppOnBoot();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       FocusScope.of(context).requestFocus(_focusNode);
//     });

//     _controller = AnimationController(
//       duration: const Duration(milliseconds: 700),
//       vsync: this,
//     );

//     _animation = Tween<double>(begin: -10, end: 10).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
//     );

//     _controller.repeat(reverse: true);

//     _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
//       setState(() {
//         index = (index + 1) % colorList.length;
//         bottomColor = colorList[index];
//         topColor = colorList[(index + 1) % colorList.length];
//       });
//     });

//     _focusNode.addListener(() {
//       if (_focusNode.hasFocus) {
//         SystemChannels.textInput.invokeMethod('TextInput.hide');
//       }
//     });

//     // Initialize the color animation controller
//     _colorController = AnimationController(
//       duration: const Duration(seconds: 2),
//       vsync: this,
//     )..repeat(reverse: true);

//     // Define the color tween for continuous color change
//     _colorAnimation = ColorTween(
//       begin: Colors.green,
//       end: Colors.red,
//     ).animate(_colorController);
//   }

//   Future<void> _checkInitialConnection() async {
//     final SharedPreferences prefs = await SharedPreferences.getInstance();
//     final isConnected = prefs.getBool('connection') ?? false;

//     if (isConnected) {
//       // Update the provider with the current connection status
//       Provider.of<ConnectionProvider>(context, listen: false)
//           .updateConnectionStatus(true);
//     } else {
//       Provider.of<ConnectionProvider>(context, listen: false)
//           .updateConnectionStatus(false);
//     }
//   }

//   @override
//   void dispose() {
//     _focusNode.dispose();
//     controller.dispose();
//     _controller.dispose();
//     _colorController.dispose(); // Dispose the controller
//     _clearProductTimer
//         ?.cancel(); // Cancel the timer when the screen is disposed
//     _timer.cancel();
//     super.dispose();
//   }

//   void _startClearProductTimer() {
//     // Cancel any existing timer before starting a new one
//     _clearProductTimer?.cancel();

//     _clearProductTimer = Timer(const Duration(seconds: 15), () {
//       setState(() {
//         productList.clear(); // Clear the product list
//         imageUrl = ''; // Clear the image URL
//       });

//       // Optionally, you can show a SnackBar message or simply rely on the UI update
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Product data cleared.'),
//         ),
//       );
//     });
//   }

//   // Assuming this function is called whenever the product data is loaded
//   void _loadProductData() {
//     // Clear previous timer if any
//     _startClearProductTimer();

//     // Load your product data logic here and update the productList
//     setState(() {
//       // Your logic to populate productList
//       // After loading the products, start the clear timer
//       _startClearProductTimer(); // Start the 15-second clear timer
//     });
//   }

//   Future<void> getProductsTableData(String text) async {
//     setState(() {
//       isLoading = true;
//       controller.text = text;
//     });
//     productList.clear();

//     var connectivityResult = await (Connectivity().checkConnectivity());
//     if (connectivityResult == ConnectivityResult.none) {
//       showBottomSnackBar(
//           'Couldn\'t connect to the server. Please check your connection.');
//       setState(() {
//         isLoading = false;
//         controller.text = '';
//       });
//       return;
//     }

//     bool connect = false;

//     try {
//       final SharedPreferences prefs = await SharedPreferences.getInstance();
//       connect = await _connectToSqlServerDirectlyPlugin.initializeConnection(
//         prefs.getString('serverIp')!,
//         prefs.getString('database')!,
//         prefs.getString('userName')!,
//         prefs.getString('password')!,
//         instance: '',
//       );
//     } catch (e) {
//       print('Failed to connect to the database: $e');
//       showBottomSnackBar(
//           'Network Error: Device is not connected or SQL server is unreachable');
//       setState(() {
//         isLoading = false;
//         controller.text = '';
//       });
//       return;
//     }

//     if (!connect) {
//       showBottomSnackBar(
//           'Couldn\'t connect to the server. Please check your connection.');
//       setState(() {
//         isLoading = false;
//         controller.text = '';
//       });
//       return;
//     }

//     try {
//       final today = DateTime.now();
//       // First query: Search by plu_id or Barcode
//       final response =
//           await _connectToSqlServerDirectlyPlugin.getRowsOfQueryResult(
//         // "SELECT Id, product_name, retail_price, product_type, tax, ebt_eligible_checkbox, weight_item_checkbox, loyality_point FROM Product WHERE on_special = 1 AND ('2024-09-15' between on_special_datetime1 AND on_special_datetime2) AND (plu_id =  '$text' OR Barcode =  '$text');"

//         "SELECT Id, Barcode, product_name, retail_price, product_type, tax, ebt_eligible_checkbox, weight_item_checkbox, loyality_point FROM Product WHERE plu_id =  '$text' OR Barcode =  '$text';",
//       );
//       if (response.runtimeType == String) {
//         showBottomSnackBar(response.toString());
//       } else {
//         List<Map<String, dynamic>> tempResult =
//             response.cast<Map<String, dynamic>>();
//         for (var element in tempResult) {
//           _addProduct(element);
//         }
//       }

//       final specialPrice = await _connectToSqlServerDirectlyPlugin
//           .getRowsOfQueryResult("""SELECT Id, special_price
//               FROM Product
//               WHERE (plu_id = '$text' OR Barcode = '$text')
//               AND '$today' BETWEEN CONVERT(DATE, on_special_datetime1) AND CONVERT(DATE, on_special_datetime2)
//               AND on_special = 1;
//           """);

//       // try {
//       //   final response =
//       //       await _connectToSqlServerDirectlyPlugin.getRowsOfQueryResult(
//       //     "SELECT Id, product_name, retail_price, product_type, tax, ebt_eligible_checkbox, weight_item_checkbox, loyality_point FROM Product WHERE plu_id =  '$text' OR Barcode =  '$text';",
//       //   );

//       // for (var product in productList) {
//       //   List<Map<String, dynamic>> tempResult =
//       //       specialPrice.cast<Map<String, dynamic>>();
//       //   for (var e in tempResult) {
//       //     if (product.keycode == e['Id'].toString()) {
//       //       var sprice = double.tryParse(e["special_price"].toString()) ?? 0.0;
//       //       product.retailPrice = sprice;
//       //     }
//       //   }
//       // }
//       for (var product in productList) {
//         List<Map<String, dynamic>> tempResult =
//             specialPrice.cast<Map<String, dynamic>>();
//         for (var e in tempResult) {
//           if (product.keycode == e['Id'].toString()) {
//             product.specialPrice =
//                 double.tryParse(e["special_price"].toString()) ?? 0.0;
//           }
//         }
//       }

//       if (productList.isEmpty) {
//         final response2 =
//             await _connectToSqlServerDirectlyPlugin.getRowsOfQueryResult(
//           "SELECT Product.Id, product_name, retail_price, product_type, tax, ebt_eligible_checkbox, weight_item_checkbox, loyality_point FROM Product, ProductSKUs WHERE ProductSKUs.SKU = '$text' AND Product.Id = ProductSKUs.Product_Id",
//         );
//         if (response2.runtimeType == String) {
//           showBottomSnackBar(response2.toString());
//         } else {
//           List<Map<String, dynamic>> tempResult =
//               response2.cast<Map<String, dynamic>>();
//           for (var element in tempResult) {
//             _addProduct(element);
//           }
//         }
//       }

//       if (productList.isEmpty) {
//         showBottomSnackBar('No product found');
//       } else {
//         final response3 =
//             await _connectToSqlServerDirectlyPlugin.getRowsOfQueryResult(
//           "SELECT image_url FROM Product WHERE Barcode = '$text'",
//         );

//         if (response3 is String) {
//           showBottomSnackBar(response3.toString());
//         } else {
//           List<Map<String, dynamic>> tempResult =
//               List<Map<String, dynamic>>.from(response3);
//           if (tempResult.isNotEmpty) {
//             imageUrl = tempResult.first["image_url"];
//           } else {
//             imageUrl = '';
//           }
//         }
//       }
//     } catch (error) {
//       print('Error occurred while querying data: $error');
//       showBottomSnackBar('An error occurred while fetching data.');
//     }

//     setState(() {
//       isLoading = false;
//       controller.text = '';
//     });
//   }

//   void _addProduct(Map<String, dynamic> element) {
//     productList.add(ProductModel(
//         keycode: element['Id'].toString(),
//         sku: element['Barcode'].toString(),
//         name: element['product_name'],
//         retailPrice: double.tryParse(element['retail_price'].toString()) ?? 0.0,
//         specialPrice:
//             double.tryParse(element['special_price'].toString()) ?? 0.0));
//   }

//   void showBottomSnackBar(String message) {
//     final overlay = Overlay.of(context);
//     final overlayEntry = OverlayEntry(
//       builder: (context) => Positioned(
//         bottom: MediaQuery.of(context).size.height * 0.1,
//         left: MediaQuery.of(context).size.width * 0.1,
//         width: MediaQuery.of(context).size.width * 0.8,
//         child: Material(
//           color: Colors.transparent,
//           child: Center(
//             child: Container(
//               padding: const EdgeInsets.all(12.0),
//               decoration: BoxDecoration(
//                 color: Colors.green.withOpacity(0.7),
//                 borderRadius: BorderRadius.circular(8.0),
//               ),
//               child: Text(
//                 message,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );

//     overlay.insert(overlayEntry);

//     Future.delayed(const Duration(seconds: 3), () {
//       overlayEntry.remove();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final connection = Provider.of<ConnectionProvider>(context).isConnected;

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         flexibleSpace: AnimatedContainer(
//           duration: const Duration(seconds: 2),
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [bottomColor, topColor],
//             ),
//           ),
//         ),
//         elevation: 0,
//         title: Text(
//           'Scan Product For Price',
//           style: TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//             fontSize: 7.sp,
//           ),
//         ),
//         centerTitle: true,
//         backgroundColor: Colors.white,
//         iconTheme: const IconThemeData(color: Colors.white),

//         // Add settings icon with dynamic color based on connection status
//         actions: [
//           IconButton(
//             icon: Icon(
//               Icons.settings,
//               color: connection ? Colors.green : Colors.red,
//             ),
//             onPressed: () {
//               KioskModeManager.showPasswordDialog(context);
//             },
//           ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           AnimatedContainer(
//             duration: const Duration(seconds: 1),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//                 colors: [bottomColor, topColor],
//               ),
//             ),
//           ),
//           Padding(
//             padding:
//                 const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0).r,
//             child: SingleChildScrollView(
//               // Add SingleChildScrollView here
//               child: Column(
//                 children: [
//                   SizedBox(
//                     width: MediaQuery.of(context).size.width / 0.5.w,
//                     height: 60.h,
//                     child: TextFormField(
//                       style: const TextStyle(color: Colors.white),
//                       autofocus: true,
//                       controller: controller,
//                       focusNode: _focusNode,
//                       onFieldSubmitted: (s) {
//                         log('Print S >>> $s');
//                         getProductsTableData(s);
//                         _focusNode.requestFocus();
//                       },
//                       decoration: InputDecoration(
//                         labelText: 'Scan Your Product',
//                         labelStyle: TextStyle(
//                           fontSize: 5.sp,
//                           color:
//                               _focusNode.hasFocus ? Colors.white : Colors.grey,
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderSide: BorderSide(
//                             color: Colors.amberAccent,
//                             width: 1.0.w,
//                           ),
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderSide: BorderSide(
//                             color: Colors.grey,
//                             width: 1.0.w,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),

//                   SizedBox(height: 20.h),

//                   // Product Display Section
//                   Container(
//                     padding: const EdgeInsets.all(10).r,
//                     decoration: BoxDecoration(
//                       color: Colors.grey[200],
//                       borderRadius: BorderRadius.circular(20.r),
//                       boxShadow: const [
//                         BoxShadow(
//                           color: Colors.black12,
//                           blurRadius: 5,
//                           spreadRadius: 5,
//                         ),
//                       ],
//                     ),
//                     child: isLoading
//                         ? const Center(
//                             child: CircularProgressIndicator(
//                               color: Colors.black,
//                             ),
//                           )
//                         : productList.isNotEmpty
//                             ? Row(
//                                 children: [
//                                   Expanded(
//                                     child: Padding(
//                                       padding:
//                                           const EdgeInsets.only(right: 8.0).r,
//                                       child: Container(
//                                         height: 320.h,
//                                         decoration: BoxDecoration(
//                                           image: imageUrl.isNotEmpty
//                                               ? DecorationImage(
//                                                   image: NetworkImage(imageUrl),
//                                                   filterQuality:
//                                                       FilterQuality.high,
//                                                   fit: BoxFit.fill,
//                                                 )
//                                               : const DecorationImage(
//                                                   image: AssetImage(
//                                                       'assets/images/sho.png'),
//                                                   filterQuality:
//                                                       FilterQuality.high,
//                                                   fit: BoxFit.fill,
//                                                 ),
//                                           color: Colors.transparent,
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                   Container(
//                                       height: 320.h,
//                                       width: 1.w,
//                                       color: Colors.grey.withOpacity(0.5)),
//                                   Expanded(
//                                     child: SingleChildScrollView(
//                                       child: Column(
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.center,
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.center,
//                                         children: productList.map((item) {
//                                           return Column(
//                                             children: [
//                                               Container(
//                                                 height: 390.h,
//                                                 width: 140.w,
//                                                 decoration: BoxDecoration(
//                                                     color: Colors.white,
//                                                     borderRadius:
//                                                         BorderRadius.circular(
//                                                             30.r)),
//                                                 child: Column(
//                                                   crossAxisAlignment:
//                                                       CrossAxisAlignment.center,
//                                                   mainAxisAlignment:
//                                                       MainAxisAlignment.center,
//                                                   children: [
//                                                     Text(
//                                                       item.name,
//                                                       textAlign:
//                                                           TextAlign.center,
//                                                       style: TextStyle(
//                                                         fontSize: 13.sp,
//                                                         fontWeight:
//                                                             FontWeight.w700,
//                                                       ),
//                                                     ),
//                                                     SizedBox(height: 10.h),
//                                                     Padding(
//                                                       padding: const EdgeInsets
//                                                           .symmetric(
//                                                           horizontal: 8.0),
//                                                       child: Row(
//                                                         mainAxisAlignment:
//                                                             MainAxisAlignment
//                                                                 .center,
//                                                         children: [
//                                                           Expanded(
//                                                             child: Text(
//                                                               'Retail Price: ',
//                                                               style: TextStyle(
//                                                                 fontSize: 9.sp,
//                                                                 fontWeight:
//                                                                     FontWeight
//                                                                         .bold,
//                                                                 color: Colors
//                                                                     .black,
//                                                               ),
//                                                             ),
//                                                           ),
//                                                           Text(
//                                                             '\$',
//                                                             style: TextStyle(
//                                                               fontSize: 12.sp,
//                                                               fontWeight:
//                                                                   FontWeight
//                                                                       .bold,
//                                                               color:
//                                                                   Colors.green,
//                                                             ),
//                                                           ),
//                                                           Expanded(
//                                                             child: FittedBox(
//                                                               child: Text(
//                                                                 item.retailPrice
//                                                                     .toStringAsFixed(
//                                                                         2),
//                                                                 style:
//                                                                     TextStyle(
//                                                                   fontSize:
//                                                                       20.sp,
//                                                                   fontWeight:
//                                                                       FontWeight
//                                                                           .bold,
//                                                                   color: Colors
//                                                                       .green,
//                                                                 ),
//                                                               ),
//                                                             ),
//                                                           ),
//                                                         ],
//                                                       ),
//                                                     ),
//                                                     if (item.specialPrice !=
//                                                         0.00) ...[
//                                                       Padding(
//                                                         padding:
//                                                             const EdgeInsets
//                                                                 .symmetric(
//                                                                 horizontal:
//                                                                     8.0),
//                                                         child: Container(
//                                                           height: 1.h,
//                                                           color: Colors.grey,
//                                                         ),
//                                                       ),
//                                                       Padding(
//                                                         padding:
//                                                             const EdgeInsets
//                                                                 .symmetric(
//                                                                 horizontal:
//                                                                     8.0),
//                                                         child: Container(
//                                                           height: 1.h,
//                                                           color: Colors.grey,
//                                                         ),
//                                                       ),
//                                                       Padding(
//                                                         padding:
//                                                             const EdgeInsets
//                                                                 .symmetric(
//                                                                 horizontal:
//                                                                     8.0),
//                                                         child: Row(
//                                                           mainAxisAlignment:
//                                                               MainAxisAlignment
//                                                                   .center,
//                                                           children: [
//                                                             Expanded(
//                                                               child: Text(
//                                                                 'Sale Price: ',
//                                                                 style:
//                                                                     TextStyle(
//                                                                   fontSize:
//                                                                       9.sp,
//                                                                   fontWeight:
//                                                                       FontWeight
//                                                                           .bold,
//                                                                   color: Colors
//                                                                       .black,
//                                                                 ),
//                                                               ),
//                                                             ),
//                                                             Text(
//                                                               '\$',
//                                                               style: TextStyle(
//                                                                 fontSize: 12.sp,
//                                                                 fontWeight:
//                                                                     FontWeight
//                                                                         .bold,
//                                                                 color: Colors
//                                                                     .green,
//                                                               ),
//                                                             ),
//                                                             Expanded(
//                                                               child: FittedBox(
//                                                                 child:
//                                                                     AnimatedBuilder(
//                                                                   animation:
//                                                                       _colorAnimation,
//                                                                   builder:
//                                                                       (context,
//                                                                           child) {
//                                                                     return Text(
//                                                                       item.specialPrice!
//                                                                           .toStringAsFixed(
//                                                                               2),
//                                                                       style:
//                                                                           TextStyle(
//                                                                         fontSize:
//                                                                             20.sp,
//                                                                         fontWeight:
//                                                                             FontWeight.bold,
//                                                                         color: _colorAnimation
//                                                                             .value, // Apply the color animation
//                                                                       ),
//                                                                     );
//                                                                   },
//                                                                 ),
//                                                               ),
//                                                             ),
//                                                           ],
//                                                         ),
//                                                       ),
//                                                     ],
//                                                   ],
//                                                 ),
//                                               ),
//                                             ],
//                                           );
//                                         }).toList(),
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               )
//                             : Center(
//                                 child: Text(
//                                   'No Product Found!',
//                                   style: TextStyle(fontSize: 7.sp),
//                                 ),
//                               ),
//                   ),
//                   SizedBox(height: 10.h),
//                   AnimatedBuilder(
//                     animation: _animation,
//                     builder: (context, child) {
//                       return Transform.translate(
//                         offset: Offset(0, _animation.value),
//                         child: Column(
//                           children: [
//                             SizedBox(
//                               width: 90.w,
//                               height: 90.h,
//                               child: const Image(
//                                 image: AssetImage('assets/images/qr_code.png'),
//                                 fit: BoxFit.contain,
//                               ),
//                             ),
//                             Text(
//                               "Scan your product's QRCode or Barcode here",
//                               textAlign: TextAlign.center,
//                               style: TextStyle(
//                                 fontSize: 5.sp,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.white,
//                               ),
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }

// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:developer';
import 'package:blocks_guide/helpers/connection_provider.dart';
import 'package:blocks_guide/helpers/kiosk_mode_manager.dart';
import 'package:connect_to_sql_server_directly/connect_to_sql_server_directly.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class ProductModel {
  final String keycode;
  final String sku;
  final String name;
  double retailPrice;
  double? specialPrice; // Nullable special price
  String? mixAndMatch;

  ProductModel({
    required this.keycode,
    required this.sku,
    required this.name,
    required this.retailPrice,
    this.specialPrice,
    this.mixAndMatch,
  });

  @override
  String toString() =>
      'ProductModel{keycode: $keycode, sku: $sku, name: $name, retailPrice: $retailPrice, specialPrice: $specialPrice, mixAndMatch: $mixAndMatch}';
}

class _ScanScreenState extends State<ScanScreen> with TickerProviderStateMixin {
  final MethodChannel platform =
      const MethodChannel('com.example.blocks_guide/kiosk_mode');
  List<ProductModel> productList = [];
  bool isLoading = false;
  final FocusNode _focusNode = FocusNode();
  TextEditingController controller = TextEditingController();
  final _connectToSqlServerDirectlyPlugin = ConnectToSqlServerDirectly();
  String imageUrl = '';

  List<Color> colorList = [
    const Color(0xff2A33B5),
    const Color(0xff5A1C88),
    const Color(0xff054A72),
    const Color(0xff0A0848),
    const Color(0xff4B024D),
  ];

  int index = 0;
  Color bottomColor = const Color(0xff092646);
  Color topColor = const Color(0xff410D75);
  late AnimationController _controller;
  late Animation<double> _animation;
  late Timer _timer;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _colorController;
  late Animation<Color?> _colorAnimation;
  Timer? _clearProductTimer; // Timer for clearing the product
  Future<void> _launchAppOnBoot() async {
    await KioskModeManager.startKioskMode();
    try {
      var result = await platform.invokeMethod('startKioskMode');
      log(result.toString());
    } on PlatformException catch (e) {
      print("Failed to invoke method: '${e.message}'.");
    }
  }

  bool isWithinDateRange(
      DateTime startDate, DateTime endDate, DateTime currentDate) {
    return startDate.isBefore(currentDate) && endDate.isAfter(currentDate);
  }

  bool isWithinTimeRange(
      String startTime, String endTime, DateTime currentTime) {
    final format = DateFormat.Hms();
    final start = format.parse(startTime);
    final end = format.parse(endTime);
    return currentTime.isAfter(start) && currentTime.isBefore(end);
  }

  Future<String> getMixAndMatchData(String productId) async {
    String mixMatchText = '';
    final today = DateTime.now();

    // Get the current weekday as a name (Monday, Tuesday, etc.)
    List<String> weekdays = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    String currentDayName = weekdays[today.weekday %
        7]; // Weekday starts from 1 (Monday), so adjust for Sunday.
    String weekdayCheck = "${currentDayName}_Check"; // e.g., "[Monday_Check]"

    log('Crurrent Day :>>> $weekdayCheck');
    var data = [];

    try {
      // Query to get mix and match details for the product
      final response = await _connectToSqlServerDirectlyPlugin
          .getRowsOfQueryResult("""SELECT 
    MAM.* 
FROM 
    Mix_And_Match MAM
JOIN 
    Mix_And_Match_Products MAMP
    ON MAM.Id = MAMP.Mix_And_Match_Id
WHERE 
    MAMP.Product_Id = '$productId'
    AND MAM.Is_Active = '1'
    AND (
        (MAM.Is_Limited_Date = '1' AND GETDATE() BETWEEN MAM.Limited_Start_Date AND MAM.Limited_End_Date)
        OR MAM.Is_Limited_Date = '0'
    )
    AND (
        (MAM.Is_Time_Restricted = '1' AND GETDATE() BETWEEN MAM.Restricted_Time_Start_Date AND MAM.Restricted_Time_End_Date)
        OR MAM.Is_Time_Restricted = '0'
    ); """);

      //       ("""
      //   SELECT Mix_And_Match.Id, Mix_And_Match.Discount, Mix_And_Match.Type, Mix_And_Match.Quantity, Mix_And_Match.Is_Limited_Date,
      //          Mix_And_Match.Limited_Start_Date, Mix_And_Match.Limited_End_Date, Mix_And_Match.Is_Time_Restricted,
      //          Mix_And_Match.Restricted_Time_Start_Date, Mix_And_Match.Restricted_Time_End_Date, $weekdayCheck
      //   FROM Mix_And_Match, Mix_And_Match_Products
      //   WHERE Mix_And_Match.Id = Mix_And_Match_Products.Mix_And_Match_Id
      //   AND Mix_And_Match_Products.Product_Id = '$productId'
      //   AND Mix_And_Match.Is_Active = '1';
      // """);
      log('getMixAndMatchData response >>> $response');
      if (response != null && response is List && response.isNotEmpty) {
        for (var row in response) {
          // DateTime startDate = DateTime.parse(row['Limited_Start_Date']);
          // DateTime endDate = DateTime.parse(row['Limited_End_Date']);

          // if (row['Is_Limited_Date']) {
          //   if (!isWithinDateRange(startDate, endDate, today)) {
          //     return '';
          //   }
          //   if (!row[weekdayCheck]) return '';
          // }

          // // Check time restriction
          // if (row['Is_Time_Restricted']) {
          //   if (!isWithinTimeRange(row['Restricted_Time_Start_Date'],
          //       row['Restricted_Time_End_Date'], today)) {
          //     return '';
          //   }
          // }

          // Check if the mix-and-match is valid for today's weekday
          bool isDayValid = row[weekdayCheck] == true || row[weekdayCheck] == 1;

          // Log the weekday check result
          log('Weekday check for $currentDayName: $isDayValid');

          // Only proceed if the product is valid for today
          if (!isDayValid) {
            log('Mix and Match not valid for today\'s weekday');
            return ''; // Return empty if not valid for today
          }
          setState(() {
            mixMatchText = '';
            mixMatchText = row['Name'];
          });
          //
          data.clear();
          data.add(row);
          log('data:   >>>  $data >>> rowName : ${row['Name']}');
          // log('data mix and match : ${row['Name']}');
        }
      } else {
        setState(() {
          mixMatchText = '';
        });
      }
    } catch (e) {
      print('Error fetching Mix and Match data: $e');
    }

    return mixMatchText;
  }

  @override
  void initState() {
    super.initState();
    // Check if already connected to the server
    _checkInitialConnection();
    _launchAppOnBoot();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });

    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _animation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      setState(() {
        index = (index + 1) % colorList.length;
        bottomColor = colorList[index];
        topColor = colorList[(index + 1) % colorList.length];
      });
    });

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      }
    });

    // Zoom In/Out Animation
    _scaleController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation =
        Tween<double>(begin: 1.0, end: 0.5).animate(_scaleController);

    // Color Transition Animation
    _colorController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _colorAnimation = ColorTween(
      begin: Colors.green,
      end: Colors.red,
    ).animate(_colorController);
  }

  Future<void> _checkInitialConnection() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final isConnected = prefs.getBool('connection') ?? false;

    if (isConnected) {
      // Update the provider with the current connection status
      Provider.of<ConnectionProvider>(context, listen: false)
          .updateConnectionStatus(true);
    } else {
      Provider.of<ConnectionProvider>(context, listen: false)
          .updateConnectionStatus(false);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    controller.dispose();
    _controller.dispose();
    _scaleController.dispose();
    _colorController.dispose(); // Dispose the controller
    _timer.cancel();
    _clearProductTimer
        ?.cancel(); // Cancel the timer when the screen is disposed
    _timer.cancel();
    super.dispose();
  }

  void _startClearProductTimer() {
    // Cancel any existing timer before starting a new one
    _clearProductTimer?.cancel();

    _clearProductTimer = Timer(const Duration(seconds: 15), () {
      setState(() {
        productList.clear(); // Clear the product list
        imageUrl = ''; // Clear the image URL
      });

      // Show a message or simply rely on the UI update
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Check if the widget is still in the tree
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product data cleared.'),
            ),
          );
        }
      });
    });
  }

  // void _startClearProductTimer() {
  //   // Cancel any existing timer before starting a new one
  //   _clearProductTimer?.cancel();

  //   _clearProductTimer = Timer(const Duration(seconds: 15), () {
  //     setState(() {
  //       productList.clear(); // Clear the product list
  //       imageUrl = ''; // Clear the image URL
  //     });

  //     // Show a message or simply rely on the UI update
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Product data cleared.'),
  //       ),
  //     );
  //   });
  // }

  Future<void> getProductsTableData(String text) async {
    setState(() {
      isLoading = true;
      controller.text = text;
    });
    productList.clear();
    log('Product list >>::>> ${productList.isEmpty}');

    // Check if there is internet connectivity
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      showBottomSnackBar(
          'Couldn\'t connect to the server. Please check your connection.');
      setState(() {
        isLoading = false;
        controller.text = '';
      });
      return;
    }

    bool connect = false;

    try {
      // Establish SQL Server connection using saved credentials
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      connect = await _connectToSqlServerDirectlyPlugin.initializeConnection(
        prefs.getString('serverIp')!,
        prefs.getString('database')!,
        prefs.getString('userName')!,
        prefs.getString('password')!,
        instance: '',
      );
    } catch (e) {
      print('Failed to connect to the database: $e');
      showBottomSnackBar(
          'Network Error: Device is not connected or SQL server is unreachable');
      setState(() {
        isLoading = false;
        controller.text = '';
      });
      return;
    }

    if (!connect) {
      showBottomSnackBar(
          'Couldn\'t connect to the server. Please check your connection.');
      setState(() {
        isLoading = false;
        controller.text = '';
      });
      return;
    }

    try {
      final today = DateTime.now();

      // Query to get the basic product data based on barcode or plu_id
      final productResponse =
          await _connectToSqlServerDirectlyPlugin.getRowsOfQueryResult(
        "SELECT Id, Barcode, product_name, retail_price, product_type, tax, ebt_eligible_checkbox, weight_item_checkbox, loyality_point FROM Product WHERE plu_id =  '$text' OR Barcode =  '$text' ;",
      );

      if (productResponse.runtimeType == String) {
        showBottomSnackBar(productResponse.toString());
      } else {
        List<Map<String, dynamic>> tempResult =
            productResponse.cast<Map<String, dynamic>>();

        for (var element in tempResult) {
          String mixMatch = await getMixAndMatchData(element['Id'].toString());
          _addProduct(element, mixMatch: mixMatch);
          log('product id ${element['Id'].toString()}');
          // Now we fetch and apply mix and match logic
        }
      }

      // Now we fetch any special price that applies
      final specialPriceResponse =
          await _connectToSqlServerDirectlyPlugin.getRowsOfQueryResult("""
        SELECT Id, special_price 
        FROM Product
        WHERE (plu_id = '$text' OR Barcode = '$text')
        AND '$today' BETWEEN CONVERT(DATE, on_special_datetime1) AND CONVERT(DATE, on_special_datetime2)
        AND on_special = 1;
      """);

      if (specialPriceResponse is List) {
        for (var product in productList) {
          List<Map<String, dynamic>> tempResult =
              specialPriceResponse.cast<Map<String, dynamic>>();
          for (var e in tempResult) {
            if (product.keycode == e['Id'].toString()) {
              product.specialPrice =
                  double.tryParse(e["special_price"].toString()) ?? 0.0;
            }
          }
        }
      }

      // If no product was found, check using SKU
      if (productList.isEmpty) {
        final skuResponse =
            await _connectToSqlServerDirectlyPlugin.getRowsOfQueryResult(
          "SELECT Product.Id, product_name, retail_price, product_type, tax, ebt_eligible_checkbox, weight_item_checkbox, loyality_point FROM Product, ProductSKUs WHERE ProductSKUs.SKU = '$text' AND Product.Id = ProductSKUs.Product_Id",
        );
        if (skuResponse.runtimeType == String) {
          showBottomSnackBar(skuResponse.toString());
        } else {
          List<Map<String, dynamic>> tempResult =
              skuResponse.cast<Map<String, dynamic>>();
          for (var element in tempResult) {
            _addProduct(element);
          }
        }
      }

      // Check if no product was found in both cases
      if (productList.isEmpty) {
        showBottomSnackBar('No product found');
      } else {
        // Fetch product image if found
        final imageResponse =
            await _connectToSqlServerDirectlyPlugin.getRowsOfQueryResult(
          "SELECT image_url FROM Product WHERE Barcode = '$text'",
        );

        if (imageResponse is List && imageResponse.isNotEmpty) {
          imageUrl = imageResponse.first["image_url"] ?? '';
        } else {
          imageUrl = '';
        }
      }
    } catch (error) {
      print('Error occurred while querying data: $error');
      showBottomSnackBar('An error occurred while fetching data.');
    }

    setState(() {
      isLoading = false;
      controller.text = '';
      _startClearProductTimer(); // Start the timer to clear product data
    });
  }

  // void _addProduct(Map<String, dynamic> element) {
  //   productList.add(
  //     ProductModel(
  //         keycode: element['Id'].toString(),
  //         sku: element['Barcode'].toString(),
  //         name: element['product_name'],
  //         mixAndMatch: element['Name'],
  //         retailPrice:
  //             double.tryParse(element['retail_price'].toString()) ?? 0.0,
  //         specialPrice:
  //             double.tryParse(element['special_price'].toString()) ?? 0.0),
  //   );
  // }

  void _addProduct(Map<String, dynamic> element, {String mixMatch = ''}) {
    final keycode = element['Id']?.toString() ?? '';
    final sku = element['Barcode']?.toString() ?? '';
    final name = element['product_name'] ?? 'Unknown Product';
    final retailPrice =
        double.tryParse(element['retail_price']?.toString() ?? '0.0') ?? 0.0;
    final specialPrice =
        double.tryParse(element['special_price']?.toString() ?? '0.0') ?? 0.0;
    // final mixMatch = element['Name']?.toString() ?? '';

    log('Product list : ${productList.isEmpty}');

    if (keycode.isNotEmpty && sku.isNotEmpty) {
      // Ensure the essential data is present
      productList.add(
        ProductModel(
          keycode: keycode,
          sku: sku,
          name: name,
          retailPrice: retailPrice,
          specialPrice: specialPrice,
          mixAndMatch: mixMatch,
        ),
      );
    }
  }

  void showBottomSnackBar(String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: MediaQuery.of(context).size.height * 0.1,
        left: MediaQuery.of(context).size.width * 0.1,
        width: MediaQuery.of(context).size.width * 0.8,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    final connection = Provider.of<ConnectionProvider>(context).isConnected;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        flexibleSpace: AnimatedContainer(
          duration: const Duration(seconds: 2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [bottomColor, topColor],
            ),
          ),
        ),
        elevation: 0,
        title: Text(
          'Scan Product For Price',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 10.sp,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),

        // Add settings icon with dynamic color based on connection status
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings,
              color: connection ? Colors.green : Colors.red,
            ),
            onPressed: () {
              FocusScope.of(context).unfocus();
              KioskModeManager.showPasswordDialog(context);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(seconds: 1),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [bottomColor, topColor],
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0).r,
            child: Column(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width / 0.5.w,
                  height: 60.h,
                  child: TextFormField(
                    style: const TextStyle(color: Colors.white),
                    autofocus: true,
                    controller: controller,
                    focusNode: _focusNode,
                    onFieldSubmitted: (s) {
                      log('Print S >>> $s');
                      getProductsTableData(s);
                      _focusNode.requestFocus();
                    },
                    decoration: InputDecoration(
                      labelText: 'Scan Your Product',
                      labelStyle: TextStyle(
                        fontSize: 7.sp,
                        color: _focusNode.hasFocus ? Colors.white : Colors.grey,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.amberAccent,
                          width: 1.0.w,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.grey,
                          width: 1.0.w,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 10.h),

                // Product Display Section
                Expanded(
                  flex: 8,
                  child: Container(
                    padding: const EdgeInsets.all(10).r,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 5,
                          spreadRadius: 15,
                        ),
                      ],
                    ),
                    child: isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.black,
                            ),
                          )
                        : productList.isNotEmpty
                            ? Row(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(right: 8.0).r,
                                      child: Container(
                                        height: 320.h,
                                        decoration: BoxDecoration(
                                          image: imageUrl.isNotEmpty
                                              ? DecorationImage(
                                                  image: NetworkImage(imageUrl),
                                                  filterQuality:
                                                      FilterQuality.high,
                                                  fit: BoxFit.fill,
                                                )
                                              : const DecorationImage(
                                                  image: AssetImage(
                                                      'assets/images/sho.png'),
                                                  filterQuality:
                                                      FilterQuality.high,
                                                  fit: BoxFit.fill,
                                                ),
                                          color: Colors.transparent,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                      height: 350.h,
                                      width: 1.w,
                                      color: Colors.grey.withOpacity(0.5)),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: productList.map((item) {
                                          log('item mixmatch : ${item.mixAndMatch}');
                                          return Column(
                                            children: [
                                              Container(
                                                height: 400.h,
                                                width: 160.w,
                                                decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            30.r)),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      item.name,
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        fontSize: 13.sp,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                    SizedBox(height: 20.h),
                                                    Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8.0),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              'Retail Price: ',
                                                              style: TextStyle(
                                                                fontSize: 7.sp,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .black,
                                                              ),
                                                            ),
                                                          ),
                                                          Text(
                                                            '\$',
                                                            style: TextStyle(
                                                              fontSize: 12.sp,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  Colors.green,
                                                            ),
                                                          ),
                                                          Expanded(
                                                            flex: 2,
                                                            child: FittedBox(
                                                              child: Text(
                                                                item.retailPrice
                                                                    .toStringAsFixed(
                                                                        2),
                                                                style:
                                                                    TextStyle(
                                                                  fontSize:
                                                                      20.sp,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .green,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(height: 20.h),
                                                    if (item.mixAndMatch!
                                                        .isNotEmpty)
                                                      FittedBox(
                                                        child: AnimatedBuilder(
                                                          animation:
                                                              _scaleAnimation,
                                                          builder:
                                                              (context, child) {
                                                            return Transform
                                                                .scale(
                                                              scale: _scaleAnimation
                                                                  .value, // Apply zoom animation
                                                              child:
                                                                  AnimatedBuilder(
                                                                animation:
                                                                    _colorAnimation,
                                                                builder:
                                                                    (context,
                                                                        child) {
                                                                  return Text(
                                                                    item.mixAndMatch!,
                                                                    style:
                                                                        TextStyle(
                                                                      fontSize:
                                                                          20.sp,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: _colorAnimation
                                                                          .value, // Apply color animation
                                                                    ),
                                                                  );
                                                                },
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                    if (item.specialPrice !=
                                                            null &&
                                                        item.specialPrice !=
                                                            0.00) ...[
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal:
                                                                    8.0),
                                                        child: Container(
                                                          height: 1.h,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal:
                                                                    8.0),
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                'Sale Price: ',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize:
                                                                      7.sp,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .black,
                                                                ),
                                                              ),
                                                            ),
                                                            Text(
                                                              '\$',
                                                              style: TextStyle(
                                                                fontSize: 12.sp,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .green,
                                                              ),
                                                            ),
                                                            Expanded(
                                                              child: FittedBox(
                                                                child:
                                                                    AnimatedBuilder(
                                                                  animation:
                                                                      _scaleAnimation,
                                                                  builder:
                                                                      (context,
                                                                          child) {
                                                                    return Transform
                                                                        .scale(
                                                                      scale: _scaleAnimation
                                                                          .value, // Apply zoom animation
                                                                      child:
                                                                          AnimatedBuilder(
                                                                        animation:
                                                                            _colorAnimation,
                                                                        builder:
                                                                            (context,
                                                                                child) {
                                                                          return Text(
                                                                            item.specialPrice!.toStringAsFixed(2),
                                                                            style:
                                                                                TextStyle(
                                                                              fontSize: 20.sp,
                                                                              fontWeight: FontWeight.bold,
                                                                              color: _colorAnimation.value, // Apply color animation
                                                                            ),
                                                                          );
                                                                        },
                                                                      ),
                                                                    );
                                                                  },
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Center(
                                child: Text(
                                  'No Product Found!',
                                  style: TextStyle(fontSize: 7.sp),
                                ),
                              ),
                  ),
                ),
                SizedBox(height: 10.h),
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Expanded(
                      flex: 2,
                      child: Transform.translate(
                        offset: Offset(0, _animation.value),
                        child: Column(
                          children: [
                            SizedBox(
                              width: 75.w,
                              height: 75.h,
                              child: const Image(
                                image: AssetImage('assets/images/qr_code.png'),
                                fit: BoxFit.contain,
                              ),
                            ),
                            Text(
                              "Scan your product's QRCode or Barcode here",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 5.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
