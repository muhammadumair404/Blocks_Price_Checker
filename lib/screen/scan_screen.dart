// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:developer';

import 'package:blocks_guide/helpers/connection_helper.dart';
import 'package:blocks_guide/helpers/connection_provider.dart';
import 'package:blocks_guide/helpers/kiosk_mode_manager.dart';
import 'package:connect_to_sql_server_directly/connect_to_sql_server_directly.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class _ScanScreenState extends State<ScanScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  final MethodChannel platform = const MethodChannel('com.eratech.blocks_price_check/kiosk_mode');
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
  late AnimationController _animationController;
  late Animation<double> _animation;
  late Timer _timer;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _colorController;
  late Animation<Color?> _colorAnimation;
  Timer? _clearProductTimer; // Timer for clearing the product

  /// Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Start kiosk mode when app resumes from minimize
      _launchAppOnBoot();
    }
  }

  /// Start kiosk mode
  Future<void> _launchAppOnBoot() async {
    await KioskModeManager.startKioskMode();
    try {
      var result = await platform.invokeMethod('startKioskMode');
      log(result.toString());
    } on PlatformException catch (e) {
      log("Failed to invoke kiosk mode: '${e.message}'.");
    }
  }

  /// Check if current date is within date range
  bool isWithinDateRange(DateTime startDate, DateTime endDate, DateTime currentDate) {
    return startDate.isBefore(currentDate) && endDate.isAfter(currentDate);
  }

  /// Check if current time is within time range
  bool isWithinTimeRange(String startTime, String endTime, DateTime currentTime) {
    final format = DateFormat.Hms();
    final start = format.parse(startTime);
    final end = format.parse(endTime);
    return currentTime.isAfter(start) && currentTime.isBefore(end);
  }

  Future<String> getMixAndMatchData(String productId) async {
    String mixMatchText = '';
    final today = DateTime.now();

    // Get the current weekday as a name (Monday, Tuesday, etc.)
    List<String> weekdays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    String currentDayName = weekdays[today.weekday % 7]; // Weekday starts from 1 (Monday), so adjust for Sunday.
    String weekdayCheck = "${currentDayName}_Check"; // e.g., "[Monday_Check]"

    log('Crurrent Day :>>> $weekdayCheck');
    var data = [];
    try {
      log('Before query execution');

      // Query to get mix and match details for the product
      final response = await _connectToSqlServerDirectlyPlugin.getRowsOfQueryResult("""
        SELECT MAM.Name 
        FROM MixMatch MAM
        INNER JOIN MixMatchProduct MAMP ON MAM.keycode = MAMP.MixMatchkeycode
        WHERE MAMP.Productkeycode = '$productId' 
          AND MAM.IsActiveRecord = '1'
          AND ((MAM.IsLimitedDates = '1' AND GETDATE() BETWEEN MAM.StartDate AND MAM.EndDate) OR MAM.IsLimitedDates = '0')
          AND ((MAM.IsTimeRestricted = '1' AND GETDATE() BETWEEN MAM.StartTime AND MAM.EndTime) OR MAM.IsTimeRestricted = '0');
      """);

/*
// SELECT
//     MAM.*
// FROM
//     Mix_And_Match MAM
// JOIN
//     Mix_And_Match_Products MAMP
//     ON MAM.Id = MAMP.Mix_And_Match_Id
// WHERE
//     MAMP.Product_Id = '$productId'
//     AND MAM.Is_Active = '1'
//     AND (
//         (MAM.Is_Limited_Date = '1' AND GETDATE() BETWEEN MAM.Limited_Start_Date AND MAM.Limited_End_Date)
//         OR MAM.Is_Limited_Date = '0'
//         OR MAM.Is_Limited_Date IS NULL
//     )
//     AND (
//         (MAM.Is_Time_Restricted = '1' AND GETDATE() BETWEEN MAM.Restricted_Time_Start_Date AND MAM.Restricted_Time_End_Date)
//         OR MAM.Is_Time_Restricted = '0'
//         OR MAM.Is_Time_Restricted IS NULL
//     );
*/

      log('getMixAndMatchData response >>> $response');
      if (response != null && response is List && response.isNotEmpty) {
        for (var row in response) {
          // Check if the mix-and-match is valid for today's weekday
          bool isDayValid = row[weekdayCheck] == true || row[weekdayCheck] == 1;

          bool isDateRes = row['Is_Limited_Date'] == true ? true : false;

          // Log the weekday check result
          log('Weekday check for $currentDayName: $isDayValid');

          // Only proceed if the product is valid for today
          if (isDateRes && !isDayValid) {
            log('Mix and Match not valid for today\'s weekday');
            return ''; // Return empty if not valid for today
          }
          setState(() {
            mixMatchText = row['Name'];
          });

          data.clear();
          data.add(row);
          log('Mix and match data: $data >>> Name: ${row['Name']}');
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
    fetchData();
  }

  /// Initialize app data and animations
  fetchData() async {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _animation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.repeat(reverse: true);

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

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.5).animate(_scaleController);

    // Color Transition Animation
    _colorController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _colorAnimation = ColorTween(
      begin: Colors.green,
      end: Colors.red,
    ).animate(_colorController);

    // Check database connection every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      final connectionProvider = Provider.of<ConnectionProvider>(context, listen: false);
      ConnectionProvider().loadConnectionStatus();
      await ConnectionHelper().checkInitialConnection(connectionProvider);
    });

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    controller.dispose();
    _animationController.dispose();
    _scaleController.dispose();
    _colorController.dispose();
    _timer.cancel();
    _clearProductTimer?.cancel();
    super.dispose();
  }

  /// Start timer to automatically clear product data after 15 seconds
  void _startClearProductTimer() {
    _clearProductTimer?.cancel();

    _clearProductTimer = Timer(const Duration(seconds: 15), () {
      setState(() {
        productList.clear();
        imageUrl = '';
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product data cleared.'),
            ),
          );
        }
      });
    });
  }

  Future<void> getProductsTableData(String text) async {
    setState(() {
      isLoading = true;
      // controller.text = '';
      controller.text = text;
    });
    productList.clear();
    log('Product list empty: ${productList.isEmpty}');
    log('Scanned text: $text');

    // Check if there is internet connectivity
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      showBottomSnackBar('Couldn\'t connect to the server. Please check your connection.');
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
      if (prefs.getString('serverIp') != null &&
          prefs.getString('database') != null &&
          prefs.getString('userName') != null &&
          prefs.getString('password') != null) {
        final tables = await _connectToSqlServerDirectlyPlugin.getRowsOfQueryResult('SELECT * FROM INFORMATION_SCHEMA.TABLES');

        log('Tables>>> $tables');

        if (tables.runtimeType == List) {
          List<Map<String, dynamic>> tablesList = tables.cast<Map<String, dynamic>>();
          log('Tables List>>> $tablesList');

          connect = tablesList.isNotEmpty;
        }

        print("Connected to $connect");
      }
    } catch (e) {
      print('Failed to connect to the database: $e');

      // Handle the host unreachable error by displaying a custom message
      if (e.toString().contains('Host unreachable')) {
        // Show custom error message for host unreachable
        showBottomSnackBar('Please connect to the same network as the server.');
      } else {
        // Generic error message for any other exception
        showBottomSnackBar('Network Error: Device is not connected or SQL server is unreachable.');
      }

      setState(() {
        isLoading = false;
        controller.text = '';
      });
      return;
    }

    print('tetestses $connect');
    if (!connect) {
      print("fdasfdas");
      showBottomSnackBar('Couldn\'t connect to the server. Please check your internet connection.');
      setState(() {
        isLoading = false;
        controller.text = '';
      });
      return;
    }

    try {
      final today = DateTime.now();
      log('Today Date: $today');

      // Query to get basic product data
      final productResponse = await _connectToSqlServerDirectlyPlugin.getRowsOfQueryResult("""
        SELECT keycode, ProductName, RetailPrice, ProductNature, TaxNonTax, EBTEligible, WeightItem, LoyaltyPoint 
        FROM Products 
        WHERE keycode IN (SELECT Productkeycode FROM ProductSKUs WHERE ProductSKU = '$text');
        """);
      log('Query text: $text');
      log('Product response: $productResponse');

      if (productResponse.runtimeType == String) {
        showBottomSnackBar(productResponse.toString());
      } else {
        List<Map<String, dynamic>> tempResult = productResponse.cast<Map<String, dynamic>>();
        log('Temp Result>>>:  $tempResult');

        for (var element in tempResult) {
          log('Before query execution');

          String mixMatch = await getMixAndMatchData(element['Id'].toString());
          log('MixMatch: $mixMatch');
          _addProduct(element, mixMatch: mixMatch);
          log('product id ${element['Id'].toString()}');
          // Now we fetch and apply mix and match logic
        }
      }

      // Now we fetch any special price that applies
      final specialPriceResponse = await _connectToSqlServerDirectlyPlugin.getRowsOfQueryResult("""
SELECT keycode, SpecialPrice FROM Products WHERE keycode = '$text'
AND CONVERT(DATE, GETDATE()) BETWEEN CONVERT(DATE, StartDate) AND CONVERT(DATE, EndDate)    AND OnSpecial = 1;
""");

/** 
 * SELECT Id, special_price
FROM Products
WHERE
    (plu_id = '$text' OR Barcode = '$text' OR Id IN (SELECT Product_Id FROM ProductSKUs WHERE SKU = '$text'))
    AND CONVERT(DATE, GETDATE()) BETWEEN CONVERT(DATE, on_special_datetime1) AND CONVERT(DATE, on_special_datetime2)
    AND on_special = 1;
*/

      // ("""SELECT Id, special_price
      // FROM Product
      // WHERE (plu_id = '$text' OR Barcode = '$text' OR sku = '$text')
      // AND '$today' BETWEEN CONVERT(DATE, on_special_datetime1) AND CONVERT(DATE, on_special_datetime2)
      // AND on_special = 1;""");
      log('special Price Response:    $specialPriceResponse');
      if (specialPriceResponse is List) {
        for (var product in productList) {
          print("product $product");
          List<Map<String, dynamic>> tempResult = specialPriceResponse.cast<Map<String, dynamic>>();
          for (var e in tempResult) {
            print('Temp Result: $tempResult');
            if (product.keycode == e['Id'].toString()) {
              product.specialPrice = double.tryParse(e["special_price"].toString()) ?? 0.0;
              print('Special Price: ${product.specialPrice}');
            }
          }
        }
      }

      // Check if no product was found in both cases
      if (productList.isEmpty) {
        showBottomSnackBar('No product found');
      } else {
        // Fetch product image if found
        final imageResponse = await _connectToSqlServerDirectlyPlugin.getRowsOfQueryResult(
          "SELECT image_url FROM Products WHERE ProductSKU = '$text'",
        );
        log('Image Response:    $imageResponse');

        if (imageResponse is List && imageResponse.isNotEmpty) {
          imageUrl = imageResponse.first["image_url"] ?? '';
          log('Image URL: $imageUrl');
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

  /// Add product to the display list
  void _addProduct(Map<String, dynamic> element, {String mixMatch = ''}) {
    final keycode = element['keycode']?.toString() ?? '';
    final sku = element['ProductSKU']?.toString() ?? '';
    final name = element['ProductName'] ?? 'Unknown Product';
    final retailPrice = double.tryParse(element['RetailPrice']?.toString() ?? '0.0') ?? 0.0;
    final specialPrice = double.tryParse(element['SpecialPrice']?.toString() ?? '0.0') ?? 0.0;

    log('Adding product to list (current empty: ${productList.isEmpty})');

    if (keycode.isNotEmpty) {
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
                color: Colors.green,
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
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
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
          actions: [
            Consumer<ConnectionProvider>(
              builder: (context, value, child) {
                bool connection = value.isConnected;
                // Connection status is managed by ConnectionProvider
                return IconButton(
                  icon: Icon(
                    Icons.settings,
                    color: connection ? Colors.green : Colors.red,
                  ),
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    KioskModeManager().showPasswordDialog(context);
                  },
                );
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
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0).r,
              child: Column(
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 0.5.w,
                    height: 60.h,
                    child: TextFormField(
                      style: const TextStyle(color: Colors.white),
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      controller: controller,
                      focusNode: _focusNode,
                      onFieldSubmitted: (value) {
                        log('item mixmatch : $value');
                        getProductsTableData(value);

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
                                          padding: const EdgeInsets.only(right: 8.0).r,
                                          child: Container(
                                            height: 320.h,
                                            decoration: BoxDecoration(
                                              image: imageUrl.isNotEmpty
                                                  ? DecorationImage(
                                                      image: NetworkImage(imageUrl),
                                                      filterQuality: FilterQuality.high,
                                                      fit: BoxFit.fill,
                                                    )
                                                  : const DecorationImage(
                                                      image: AssetImage('assets/images/sho.png'),
                                                      filterQuality: FilterQuality.high,
                                                      fit: BoxFit.fill,
                                                    ),
                                              color: Colors.transparent,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(height: 350.h, width: 1.w, color: Colors.grey.withOpacity(0.5)),
                                      Expanded(
                                        child: SingleChildScrollView(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: productList.map((item) {
                                              log('item mixmatch : ${item.mixAndMatch}');
                                              return Column(
                                                children: [
                                                  Container(
                                                    width: 160.w,
                                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30.r)),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Text(
                                                          item.name,
                                                          textAlign: TextAlign.center,
                                                          style: TextStyle(
                                                            fontSize: 10.sp,
                                                            fontWeight: FontWeight.w700,
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                                          child: Row(
                                                            children: [
                                                              Expanded(
                                                                flex: 3,
                                                                child: Text(
                                                                  'Retail Price: ',
                                                                  style: TextStyle(
                                                                    fontSize: 10.sp,
                                                                    fontWeight: FontWeight.bold,
                                                                    color: Colors.black,
                                                                  ),
                                                                ),
                                                              ),
                                                              Text(
                                                                '\$',
                                                                style: TextStyle(
                                                                  fontSize: 12.sp,
                                                                  fontWeight: FontWeight.bold,
                                                                  color: Colors.green,
                                                                ),
                                                              ),
                                                              Expanded(
                                                                flex: 2,
                                                                child: FittedBox(
                                                                  child: Text(
                                                                    item.retailPrice.toStringAsFixed(2),
                                                                    style: TextStyle(
                                                                      fontSize: 25.sp,
                                                                      fontWeight: FontWeight.bold,
                                                                      color: Colors.green,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        if (item.mixAndMatch!.isNotEmpty)
                                                          FittedBox(
                                                            child: AnimatedBuilder(
                                                              animation: _scaleAnimation,
                                                              builder: (context, child) {
                                                                return Transform.scale(
                                                                  scale: _scaleAnimation.value, // Apply zoom animation
                                                                  child: AnimatedBuilder(
                                                                    animation: _colorAnimation,
                                                                    builder: (context, child) {
                                                                      return Text(
                                                                        item.mixAndMatch!,
                                                                        style: TextStyle(
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
                                                        if (item.specialPrice != null && item.specialPrice != 0.00) ...[
                                                          Padding(
                                                            padding: const EdgeInsets.symmetric(horizontal: 15.0),
                                                            child: Container(
                                                              height: 1.h,
                                                              color: Colors.grey,
                                                            ),
                                                          ),
                                                          Padding(
                                                            padding: const EdgeInsets.symmetric(horizontal: 45.0),
                                                            child: Row(
                                                              children: [
                                                                Expanded(
                                                                  flex: 3,
                                                                  child: Text(
                                                                    'Discounted Price:',
                                                                    style: TextStyle(
                                                                      fontSize: 8.sp,
                                                                      fontWeight: FontWeight.bold,
                                                                      color: Colors.black,
                                                                    ),
                                                                  ),
                                                                ),
                                                                Text(
                                                                  '\$',
                                                                  style: TextStyle(
                                                                    fontSize: 12.sp,
                                                                    fontWeight: FontWeight.bold,
                                                                    color: Colors.green,
                                                                  ),
                                                                ),
                                                                Expanded(
                                                                  flex: 2,
                                                                  child: FittedBox(
                                                                    child: AnimatedBuilder(
                                                                      animation: _scaleAnimation,
                                                                      builder: (context, child) {
                                                                        return Transform.scale(
                                                                          scale: _scaleAnimation.value, // Apply zoom animation
                                                                          child: AnimatedBuilder(
                                                                            animation: _colorAnimation,
                                                                            builder: (context, child) {
                                                                              return Text(
                                                                                item.specialPrice!.toStringAsFixed(2),
                                                                                style: TextStyle(
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
                                : Consumer<ConnectionProvider>(
                                    builder: (context, value, child) {
                                      bool connection = value.isConnected; // Provider se value access ki.
                                      return Center(
                                        child: Text(
                                          connection ? 'Please Scan Your Product' : 'Please connect to your server',
                                          style: connection ? TextStyle(fontSize: 15.sp) : TextStyle(color: Colors.red, fontSize: 15.sp),
                                        ),
                                      );
                                    },
                                  )),
                  ),
                  SizedBox(height: 10.h),
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Expanded(
                        flex: 2,
                        child: Transform.translate(
                          offset: Offset(0, _animation.value),
                          child: SingleChildScrollView(
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
                        ),
                      );
                    },
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
