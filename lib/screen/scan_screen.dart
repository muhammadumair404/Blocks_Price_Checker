// import 'dart:async';

// import 'package:connect_to_sql_server_directly/connect_to_sql_server_directly.dart';
// import 'package:flutter/material.dart';

// class ScanScreen extends StatefulWidget {
//   const ScanScreen({super.key});

//   @override
//   State<ScanScreen> createState() => _ScanScreenState();
// }

// class ProductModel {
//   final String keycode;
//   final String sku;
//   final String name;
//   final double price;

//   ProductModel({
//     required this.keycode,
//     required this.sku,
//     required this.name,
//     required this.price,
//   });
// }

// class _ScanScreenState extends State<ScanScreen> with TickerProviderStateMixin {
//   List<ProductModel> productList = [];
//   bool isLoading = false;
//   final FocusNode _focusNode = FocusNode();
//   TextEditingController controller = TextEditingController();
//   final _connectToSqlServerDirectlyPlugin = ConnectToSqlServerDirectly();

//   List<Color> colorList = [
//     const Color(0xff171B70),
//     const Color(0xff410D75),
//     const Color(0xff032340),
//     const Color(0xff050340),
//     const Color(0xff2C0340),
//   ];
//   List<Alignment> alignmentList = [Alignment.topCenter, Alignment.bottomCenter];
//   int index = 0;
//   Color bottomColor = const Color(0xff092646);
//   Color topColor = const Color(0xff410D75);
//   late AnimationController _controller;
//   late Animation<double> _animation;
//   // Alignment begin = Alignment.bottomCenter;
//   // Alignment end = Alignment.topCenter;
//   // @override
//   @override
//   void initState() {
//     super.initState();
//     // Automatically request focus when the widget builds
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       FocusScope.of(context).requestFocus(_focusNode);
//     });
//     Timer(
//       const Duration(microseconds: 0),
//       () {
//         setState(
//           () {
//             bottomColor = const Color(0xff33267C);
//           },
//         );
//       },
//     );
//     // Set up the AnimationController
//     _controller = AnimationController(
//       duration: const Duration(seconds: 3),
//       vsync: this,
//     );

//     // Define the animation for top to bottom movement
//     _animation = Tween<double>(begin: -100, end: 600).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
//     );

//     // Repeat the animation forever
//     _controller.repeat(reverse: false);
//   }

//   @override
//   void dispose() {
//     _focusNode.dispose();
//     controller.dispose();
//     super.dispose();
//   }

//   Future<void> getProductsTableData(String text) async {
//     setState(() {
//       isLoading = true;
//     });
//     productList.clear();
//     bool connect = false;
//     try {
//       connect = await _connectToSqlServerDirectlyPlugin.initializeConnection(
//         '192.168.100.181', // serverIp
//         'TestDB_prosper', // databaseName
//         'Blocks360-Administrator', // username
//         'Ali@00786', // password
//         instance: '',
//       );
//     } catch (e) {}

//     if (connect) {
//       try {
//         final response =
//             await _connectToSqlServerDirectlyPlugin.getRowsOfQueryResult(
//           "SELECT Id, product_name, retail_price, product_type, tax, ebt_eligible_checkbox, weight_item_checkbox, loyality_point FROM Product WHERE plu_id =  '$text' OR Barcode =  '$text';",
//         );
//         if (response.runtimeType == String) {
//           onError(response.toString());
//         } else {
//           List<Map<String, dynamic>> tempResult =
//               response.cast<Map<String, dynamic>>();
//           for (var element in tempResult) {
//             _addProduct(element);
//           }
//         }

//         if (productList.isEmpty) {
//           final response2 =
//               await _connectToSqlServerDirectlyPlugin.getRowsOfQueryResult(
//             "SELECT Product.Id, product_name, retail_price, product_type, tax, ebt_eligible_checkbox, weight_item_checkbox, loyality_point FROM Product, ProductSKUs WHERE ProductSKUs.SKU = '$text' AND Product.Id = ProductSKUs.Product_Id",
//           );
//           if (response2.runtimeType == String) {
//             onError(response2.toString());
//           } else {
//             List<Map<String, dynamic>> tempResult =
//                 response2.cast<Map<String, dynamic>>();
//             for (var element in tempResult) {
//               _addProduct(element);
//             }
//           }
//         }
//       } catch (error) {
//         onError(error.toString());
//       }
//     } else {
//       onError('Failed to Connect!');
//     }

//     setState(() {
//       isLoading = false;
//       controller.text = '';
//     });
//   }

//   void _addProduct(Map<String, dynamic> element) {
//     productList.add(
//       ProductModel(
//         keycode: element['id'].toString(),
//         sku: element['sku'].toString(),
//         name: element['product_name'],
//         price: double.tryParse(element['retail_price'].toString()) ?? 0.0,
//       ),
//     );
//   }

//   void onError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         backgroundColor: Colors.red,
//         duration: const Duration(seconds: 6),
//         padding: const EdgeInsets.all(8.0),
//         content: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Expanded(
//               child: Text(
//                 message,
//                 style: const TextStyle(
//                     color: Colors.white, fontWeight: FontWeight.bold),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       resizeToAvoidBottomInset: false,
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         flexibleSpace: AnimatedContainer(
//           duration: const Duration(seconds: 2),
//           onEnd: () {
//             setState(
//               () {
//                 index = index + 1;
//                 bottomColor = colorList[index % colorList.length];
//                 topColor = colorList[(index + 100) % colorList.length];
//               },
//             );
//           },
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [bottomColor, topColor],
//             ),
//           ),
//         ),
//         elevation: 0,
//         title: const Text(
//           'Scan Product For Price',
//           style: TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//             fontSize: 24,
//           ),
//         ),
//         centerTitle: true,
//         backgroundColor: Colors.white,
//         iconTheme: const IconThemeData(color: Colors.black),
//       ),
//       body: AnimatedContainer(
//         duration: const Duration(seconds: 2),
//         onEnd: () {
//           setState(
//             () {
//               index = index + 1;
//               bottomColor = colorList[index % colorList.length];
//               topColor = colorList[(index + 100) % colorList.length];
//             },
//           );
//         },
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [bottomColor, topColor],
//           ),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Expanded(
//             child: Column(
//               children: [
//                 // Text Field for Barcode Input with autofocus
//                 SizedBox(
//                   width: MediaQuery.of(context).size.width / 2.5,
//                   child: TextFormField(
//                     readOnly: true,
//                     style: const TextStyle(color: Colors.white),
//                     autofocus: true, // Auto focus when the page loads
//                     controller: controller,
//                     focusNode: _focusNode,
//                     onFieldSubmitted: (s) {
//                       getProductsTableData(s);
//                     },
//                     decoration: InputDecoration(
//                       labelText: 'Scan Your Product',
//                       labelStyle: TextStyle(
//                         color: _focusNode.hasFocus ? Colors.white : Colors.grey,
//                       ),
//                       focusedBorder: const OutlineInputBorder(
//                         borderSide: BorderSide(
//                           color: Colors.amberAccent,
//                           width: 1.0,
//                         ),
//                       ),
//                       enabledBorder: const OutlineInputBorder(
//                         borderSide: BorderSide(
//                           color: Colors.grey,
//                           width: 1.0,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 // Product Display Section
//                 Container(
//                   padding: const EdgeInsets.all(10),
//                   decoration: BoxDecoration(
//                     color: Colors.grey[200],
//                     borderRadius: BorderRadius.circular(20),
//                     boxShadow: const [
//                       BoxShadow(
//                         color: Colors.black12,
//                         blurRadius: 5,
//                         spreadRadius: 5,
//                       ),
//                     ],
//                   ),
//                   child: isLoading
//                       ? const Center(
//                           child: CircularProgressIndicator(
//                             color: Colors.black,
//                           ),
//                         )
//                       : productList.isNotEmpty
//                           ? Row(
//                               children: [
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.center,
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: [
//                                       Container(
//                                         // width: 150,
//                                         // height: 150,
//                                         decoration: BoxDecoration(
//                                           color: Colors.grey[300],
//                                           borderRadius:
//                                               BorderRadius.circular(15),
//                                         ),
//                                         child: const Icon(
//                                           Icons.shopping_bag_outlined,
//                                           color: Colors.grey,
//                                           size: 380,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 Container(
//                                     height: 370,
//                                     width: 3,
//                                     color: Colors.grey.withOpacity(0.5)),
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.center,
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: productList.map((item) {
//                                       return Column(
//                                         children: [
//                                           Container(
//                                             height: 250,
//                                             width: 300,
//                                             decoration: BoxDecoration(
//                                                 color: Colors.white,
//                                                 borderRadius:
//                                                     BorderRadius.circular(20)),
//                                             child: Column(
//                                               crossAxisAlignment:
//                                                   CrossAxisAlignment.center,
//                                               mainAxisAlignment:
//                                                   MainAxisAlignment.center,
//                                               children: [
//                                                 Text(
//                                                   item.name,
//                                                   style: const TextStyle(
//                                                     fontSize: 35,
//                                                     fontWeight: FontWeight.bold,
//                                                   ),
//                                                 ),
//                                                 // const SizedBox(height: 40),
//                                                 // Text(
//                                                 //   'SKU: ${item.sku}',
//                                                 //   style: const TextStyle(
//                                                 //     fontSize: 25,
//                                                 //     color: Colors.grey,
//                                                 //   ),
//                                                 // ),
//                                                 const SizedBox(height: 10),
//                                                 Text(
//                                                   '\$${item.price.toStringAsFixed(2)}',
//                                                   style: const TextStyle(
//                                                     fontSize: 80,
//                                                     fontWeight: FontWeight.bold,
//                                                     color: Colors.green,
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                           ),
//                                         ],
//                                       );
//                                     }).toList(),
//                                   ),
//                                 ),
//                               ],
//                             )
//                           : const Center(
//                               child: Text(
//                                 'No Product Found!',
//                                 style: TextStyle(fontSize: 16),
//                               ),
//                             ),
//                 ),

//                 Container(
//                   child: AnimatedBuilder(
//                     animation: _animation,
//                     builder: (context, child) {
//                       return Stack(
//                         children: [
//                           // QRCode Image Animated from top to bottom
//                           Positioned(
//                             top: _animation.value,
//                             left: MediaQuery.of(context).size.width * 0.25,
//                             right: MediaQuery.of(context).size.width * 0.25,
//                             child: Column(
//                               children: [
//                                 // QRCode Image
//                                 Container(
//                                   width: 150,
//                                   height: 150,
//                                   decoration: BoxDecoration(
//                                     border: Border.all(
//                                         color: Colors.black, width: 2),
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                   child: Image.network(
//                                     'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5b/QRCode.png/120px-QRCode.png', // Sample QR Code image
//                                     fit: BoxFit.cover,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 20),
//                                 // Text "Scan your product's QRCode or Barcode here"
//                                 const Text(
//                                   "Scan your product's QRCode or Barcode here",
//                                   textAlign: TextAlign.center,
//                                   style: TextStyle(
//                                     fontSize: 18,
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.black,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'dart:async';
import 'dart:developer';
import 'package:connect_to_sql_server_directly/connect_to_sql_server_directly.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class ProductModel {
  final String keycode;
  final String sku;
  final String name;
  final double price;

  ProductModel({
    required this.keycode,
    required this.sku,
    required this.name,
    required this.price,
  });
}

class _ScanScreenState extends State<ScanScreen> with TickerProviderStateMixin {
  final MethodChannel platform = const MethodChannel('your_channel_name');
  //
  List<ProductModel> productList = [];
  bool isLoading = false;
  final FocusNode _focusNode = FocusNode();
  TextEditingController controller = TextEditingController();
  final _connectToSqlServerDirectlyPlugin = ConnectToSqlServerDirectly();
  String imageUrl = '';

  // List of colors to cycle through for the background animation
  List<Color> colorList = [
    const Color(0xff2A33B5), // Brighter Blue
    const Color(0xff5A1C88), // Brighter Purple
    const Color(0xff054A72), // Brighter Deep Blue
    const Color(0xff0A0848), // Brighter Dark Blue
    const Color(0xff4B024D), // Brighter Dark Purple
  ];

  int index = 0;
  Color bottomColor = const Color(0xff092646);
  Color topColor = const Color(0xff410D75);
  late AnimationController _controller;
  late Animation<double> _animation;
  late Timer _timer; // Timer to change the colors

  Future<void> _launchAppOnBoot() async {
    try {
      var result = await platform.invokeMethod('startKioskMode');
      log(result.toString());
    } on PlatformException catch (e) {
      print("Failed to invoke method: '${e.message}'.");
    }
  }

  @override
  void initState() {
    super.initState();
    _launchAppOnBoot();
    // Automatically request focus when the widget builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });

    // Set up the AnimationController
    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    // Define the animation for top to bottom movement
    _animation = Tween<double>(begin: -20, end: 10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Repeat the animation forever
    _controller.repeat(reverse: true);

    // Start a timer to change the colors periodically
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      setState(() {
        index = (index + 1) % colorList.length;
        bottomColor = colorList[index];
        topColor = colorList[(index + 1) % colorList.length];
      });

      _focusNode.addListener(() {
        if (_focusNode.hasFocus) {
          SystemChannels.textInput.invokeMethod('TextInput.hide');
        }
      });
      // // Block keyboard from showing up
      // SystemChannels.textInput.invokeMethod('TextInput.hide');
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    controller.dispose();
    _controller
        .dispose(); // Dispose of the controller when the widget is disposed.
    _timer.cancel(); // Cancel the timer when the widget is disposed.
    super.dispose();
  }

  Future<void> getProductsTableData(String text) async {
    setState(() {
      isLoading = true;
      controller.text = text;
    });
    productList.clear();
    bool connect = false;

    // Attempt to connect to the SQL server
    try {
      connect = await _connectToSqlServerDirectlyPlugin.initializeConnection(
        '192.168.100.26', // serverIp
        'TestDB', // databaseName
        'SuperAdmin', // username
        'Ali@00786', // password
        instance: '',
      );
    } catch (e) {
      print('Failed to connect to database:');
    }

    // Check if connection was successful
    if (!connect) {
      // Connection failed
      showBottomSnackBar('Couldn\'t connect to the server');
      setState(() {
        isLoading = false;
        controller.text = '';
      });
      return;
    }

    try {
      // First query: Search by plu_id or Barcode
      final response =
          await _connectToSqlServerDirectlyPlugin.getRowsOfQueryResult(
        "SELECT Id, product_name, retail_price, product_type, tax, ebt_eligible_checkbox, weight_item_checkbox, loyality_point FROM Product WHERE plu_id =  '$text' OR Barcode =  '$text';",
      );

      if (response.runtimeType == String) {
        showBottomSnackBar(response.toString());
      } else {
        List<Map<String, dynamic>> tempResult =
            response.cast<Map<String, dynamic>>();
        for (var element in tempResult) {
          _addProduct(element);
        }
      }

      // If no product found from the first query, perform a second query
      if (productList.isEmpty) {
        final response2 =
            await _connectToSqlServerDirectlyPlugin.getRowsOfQueryResult(
          "SELECT Product.Id, product_name, retail_price, product_type, tax, ebt_eligible_checkbox, weight_item_checkbox, loyality_point FROM Product, ProductSKUs WHERE ProductSKUs.SKU = '$text' AND Product.Id = ProductSKUs.Product_Id",
        );
        if (response2.runtimeType == String) {
          showBottomSnackBar(response2.toString());
        } else {
          List<Map<String, dynamic>> tempResult =
              response2.cast<Map<String, dynamic>>();
          for (var element in tempResult) {
            _addProduct(element);
          }
        }
      }

      // Check if any product was found after both queries
      if (productList.isEmpty) {
        showBottomSnackBar('No product found');
      } else {
        // Query for product image URL if a product was found
        final response3 =
            await _connectToSqlServerDirectlyPlugin.getRowsOfQueryResult(
          "SELECT image_url FROM Product WHERE Barcode = '$text'",
        );

        if (response3 is String) {
          showBottomSnackBar(response3.toString());
        } else {
          List<Map<String, dynamic>> tempResult =
              List<Map<String, dynamic>>.from(response3);
          if (tempResult.isNotEmpty) {
            imageUrl = tempResult.first["image_url"];
          } else {
            imageUrl = '';
          }
        }
      }
    } catch (error) {
      // If there's an issue with fetching product data
      showBottomSnackBar('No product found');
    }

    setState(() {
      isLoading = false;
      controller.text = '';
    });
  }

  void _addProduct(Map<String, dynamic> element) {
    productList.add(
      ProductModel(
        keycode: element['id'].toString(),
        sku: element['sku'].toString(),
        name: element['product_name'],
        price: double.tryParse(element['retail_price'].toString()) ?? 0.0,
      ),
    );
  }

  void showBottomSnackBar(String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: MediaQuery.of(context).size.height *
            0.1, // Adjust height to be slightly above bottom
        left: MediaQuery.of(context).size.width * 0.1, // Horizontal position
        width: MediaQuery.of(context).size.width * 0.8, // Adjust the width
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.7), // Background color
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

    // Remove the overlay after a short duration
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var heigh = MediaQuery.of(context).size.height;

    log('Width >> $width Height >> $heigh');
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
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
            fontSize: 7.sp,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          // Gradient background animation
          Padding(
            padding: const EdgeInsets.only(bottom: 11.0).r,
            child: AnimatedContainer(
              duration: const Duration(seconds: 1),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [bottomColor, topColor],
                ),
              ),
            ),
          ),

          // Main content with product list and form
          Padding(
            padding: const EdgeInsets.all(16.0).r,
            child: Column(
              children: [
                // Text Field for Barcode Input with autofocus
                // SizedBox(
                //   width: MediaQuery.of(context).size.width / 0.5.w,
                //   height: 60.h,
                //   child: TextFormField(
                //     // obscureText: true,
                //     // readOnly: true, // Prevent the keyboard from opening
                //     enableInteractiveSelection:
                //         true, // Disable any selection that could trigger keyboard
                //     showCursor:
                //         true, // Show the cursor even though it's read-only
                //     style: const TextStyle(color: Colors.white),
                //     autofocus: true, // Auto focus when the page loads
                //     controller: controller,
                //     focusNode: _focusNode,
                //     onFieldSubmitted: (s) {
                //       log('Print S >>> $s');
                //       getProductsTableData(s);
                //       _focusNode.requestFocus();

                //       // Request focus again to keep the focus on the TextField
                //       FocusScope.of(context).requestFocus(_focusNode);
                //       // SystemChannels.textInput.invokeMethod('TextInput.hide');
                //     },
                //     decoration: InputDecoration(
                //       labelText: 'Scan Your Product',
                //       labelStyle: TextStyle(
                //         fontSize: 5.sp,
                //         color: _focusNode.hasFocus ? Colors.white : Colors.grey,
                //       ),
                //       focusedBorder: OutlineInputBorder(
                //         borderSide: BorderSide(
                //           color: Colors.amberAccent,
                //           width: 1.0.w,
                //         ),
                //       ),
                //       enabledBorder: OutlineInputBorder(
                //         borderSide: BorderSide(
                //           color: Colors.grey,
                //           width: 1.0.w,
                //         ),
                //       ),
                //     ),
                //   ),
                // ),

                SizedBox(
                  width: MediaQuery.of(context).size.width / 0.5.w,
                  height: 60.h,
                  child: TextFormField(
                    // readOnly: true,
                    style: const TextStyle(color: Colors.white),
                    autofocus: true, // Auto focus when the page loads
                    controller: controller,
                    focusNode: _focusNode,
                    onFieldSubmitted: (s) {
                      log('Print S >>> $s');
                      getProductsTableData(s);

                      // Request focus again to keep the focus on the TextField
                      _focusNode.requestFocus();
                    },
                    decoration: InputDecoration(
                      labelText: 'Scan Your Product',
                      labelStyle: TextStyle(
                        fontSize: 5.sp,
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

                SizedBox(height: 20.h),

                // Product Display Section
                Container(
                  padding: const EdgeInsets.all(10).r,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 5,
                        spreadRadius: 5,
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
                                      // width: 200,
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
                                      // child: imageUrl.isNotEmpty
                                      //     ? Image(
                                      //         width: 570,
                                      //         image: NetworkImage(imageUrl),
                                      //         filterQuality:
                                      //             FilterQuality.high,
                                      //         fit: BoxFit.cover,
                                      //       )
                                      //     : Icon(
                                      //         Icons.shopping_bag_outlined,
                                      //         color: Colors.grey,
                                      //         size: 200.r,
                                      //       ),
                                    ),
                                  ),
                                ),
                                Container(
                                    height: 320.h,
                                    width: 1.w,
                                    color: Colors.grey.withOpacity(0.5)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: productList.map((item) {
                                      return Column(
                                        children: [
                                          Container(
                                            height: 350.h,
                                            width: 100.w,
                                            decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(30)
                                                        .r),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  item.name,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 13.sp,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(height: 10.h),
                                                Text(
                                                  '\$${item.price.toStringAsFixed(2)}',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 22.sp,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
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
                SizedBox(height: 20.h),
                // QR Code Animation Section
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _animation.value),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 90.w,
                            height: 90.h,
                            child: const Image(
                              image:
                                  //  NetworkImage(imageUrl),
                                  AssetImage('assets/images/qr_code.png'),
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
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
