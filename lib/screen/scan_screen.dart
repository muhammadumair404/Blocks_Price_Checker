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

class _ScanScreenState extends State<ScanScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
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
  late AnimationController _controller;
  late Animation<double> _animation;
  late Timer _timer;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _colorController;
  late Animation<Color?> _colorAnimation;
  Timer? _clearProductTimer; // Timer for clearing the product

  // Lifecycle changes ko handle karna
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Jab app resume ho (minimize se wapas aaye) to kiosk mode start karein
      _launchAppOnBoot();
    }
  }

  // Kiosk mode start karne ka method
  Future<void> _launchAppOnBoot() async {
    await KioskModeManager.startKioskMode();
    try {
      var result = await platform.invokeMethod('startKioskMode');
      log(result.toString());
    } on PlatformException catch (e) {
      print("Failed to invoke method: '${e.message}'.");
    }
  }

  bool isWithinDateRange(DateTime startDate, DateTime endDate, DateTime currentDate) {
    return startDate.isBefore(currentDate) && endDate.isAfter(currentDate);
  }

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
    List<String> weekdays = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    String currentDayName =
        weekdays[today.weekday % 7]; // Weekday starts from 1 (Monday), so adjust for Sunday.
    String weekdayCheck = "${currentDayName}_Check"; // e.g., "[Monday_Check]"

    log('Crurrent Day :>>> $weekdayCheck');
    var data = [];
    try {
      log('Before query execution');

      // Query to get mix and match details for the product
      final response = await _connectToSqlServerDirectlyPlugin.getRowsOfQueryResult("""SELECT
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
      //     ("""
      // SELECT Mix_And_Match.Id, Mix_And_Match.Discount, Mix_And_Match.Type, Mix_And_Match.Quantity, Mix_And_Match.Is_Limited_Date,
      //        Mix_And_Match.Limited_Start_Date, Mix_And_Match.Limited_End_Date, Mix_And_Match.Is_Time_Restricted,
      //        Mix_And_Match.Restricted_Time_Start_Date, Mix_And_Match.Restricted_Time_End_Date, $weekdayCheck
      // FROM Mix_And_Match, Mix_And_Match_Products
      // WHERE Mix_And_Match.Id = Mix_And_Match_Products.Mix_And_Match_Id
      // AND Mix_And_Match_Products.Product_Id = '$productId'
      // AND Mix_And_Match.Is_Active = '1';
      // """);
      log('getMixAndMatchData response >>> $response');
      if (response != null && response is List && response.isNotEmpty) {
        for (var row in response) {
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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    // Check if already connected to the server
    _checkInitialConnection();
    WidgetsBinding.instance.addObserver(this); // Lifecycle observer add karein
    _launchAppOnBoot(); // App start hone pe kiosk mode automatically start ho
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
  }

  Future<void> _checkInitialConnection() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isConnected = false;

    if (prefs.containsKey('serverIp') &&
        prefs.containsKey('database') &&
        prefs.containsKey('userName') &&
        prefs.containsKey('password')) {
      // Retrieve saved credentials
      final serverIp = prefs.getString('serverIp')!;
      final database = prefs.getString('database')!;
      final username = prefs.getString('userName')!;
      final password = prefs.getString('password')!;

      // Try to establish a connection using the saved credentials
      try {
        isConnected = await _connectToSqlServerDirectlyPlugin.initializeConnection(
            serverIp, database, username, password);

        if (isConnected) {
          // Test with a simple query to confirm the connection
          final testResponse = await _connectToSqlServerDirectlyPlugin
              .getRowsOfQueryResult("SELECT TOP 1 * FROM Product;");

          isConnected = testResponse != null && testResponse is List;
        }
      } catch (e) {
        isConnected = false;
        print('Failed to connect at startup: $e');
      }
    }

    // Update connection status in ConnectionProvider and SharedPreferences
    Provider.of<ConnectionProvider>(context, listen: false).updateConnectionStatus(isConnected);
    prefs.setBool('connection', isConnected);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Observer ko remove karein
    _focusNode.dispose();
    controller.dispose();
    _controller.dispose();
    _scaleController.dispose();
    _colorController.dispose(); // Dispose the controller
    _timer.cancel();
    _clearProductTimer?.cancel(); // Cancel the timer when the screen is disposed
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

  Future<void> getProductsTableData(String text) async {
    setState(() {
      isLoading = true;
      controller.text = text;
    });
    productList.clear();
    log('Product list >>::>> ${productList.isEmpty}');
    log('TextField Text >>::>> $text');

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
        final tables = await _connectToSqlServerDirectlyPlugin
            .getRowsOfQueryResult('SELECT * FROM INFORMATION_SCHEMA.TABLES');

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

      // Query to get the basic product data based on barcode or plu_id
      final productResponse = await _connectToSqlServerDirectlyPlugin.getRowsOfQueryResult(
          // """SELECT Id, Barcode, product_name, retail_price, product_type, tax, ebt_eligible_checkbox, weight_item_checkbox, loyality_point FROM Product WHERE plu_id =  '$text' OR Barcode =  '$text' ;""",
          """SELECT Id, Barcode, product_name, retail_price, product_type, tax, ebt_eligible_checkbox, weight_item_checkbox, loyality_point FROM Product WHERE Id In(select Product_Id from ProductSKUs where SKU = '$text') or Barcode = '$text' or plu_id = '$text';""");
      log('Text:?? $text');

      log('product Response>>>>: $productResponse');

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
      final specialPriceResponse =
          await _connectToSqlServerDirectlyPlugin.getRowsOfQueryResult("""	SELECT Id, special_price 
FROM Product
WHERE 
    (plu_id = '$text' OR Barcode = '$text' OR Id IN (SELECT Product_Id FROM ProductSKUs WHERE SKU = '$text'))
    AND CONVERT(DATE, GETDATE()) BETWEEN CONVERT(DATE, on_special_datetime1) AND CONVERT(DATE, on_special_datetime2)
    AND on_special = 1;
""");

      // ("""SELECT Id, special_price
      // FROM Product
      // WHERE (plu_id = '$text' OR Barcode = '$text' OR sku = '$text')
      // AND '$today' BETWEEN CONVERT(DATE, on_special_datetime1) AND CONVERT(DATE, on_special_datetime2)
      // AND on_special = 1;""");
      log('special Price Response:    $specialPriceResponse');
      if (specialPriceResponse is List) {
        for (var product in productList) {
          List<Map<String, dynamic>> tempResult = specialPriceResponse.cast<Map<String, dynamic>>();
          for (var e in tempResult) {
            if (product.keycode == e['Id'].toString()) {
              product.specialPrice = double.tryParse(e["special_price"].toString()) ?? 0.0;
            }
          }
        }
      }

      // // If no product was found, check using SKU
      // if (productList.isEmpty) {
      //   final skuResponse = await _connectToSqlServerDirectlyPlugin.getRowsOfQueryResult(
      //     "SELECT Product.Id, product_name, retail_price, product_type, tax, ebt_eligible_checkbox, weight_item_checkbox, loyality_point FROM Product, ProductSKUs WHERE ProductSKUs.SKU = '$text' AND Product.Id = ProductSKUs.Product_Id",
      //   );
      //   log('SKU Response:    $skuResponse');
      //   if (skuResponse.runtimeType == String) {
      //     showBottomSnackBar(skuResponse.toString());
      //   } else {
      //     List<Map<String, dynamic>> tempResult = skuResponse.cast<Map<String, dynamic>>();
      //     for (var element in tempResult) {
      //       _addProduct(element);
      //       print('Element :>>> $element');
      //     }
      //   }
      // }

      // Check if no product was found in both cases
      if (productList.isEmpty) {
        showBottomSnackBar('No product found');
      } else {
        // Fetch product image if found
        final imageResponse = await _connectToSqlServerDirectlyPlugin.getRowsOfQueryResult(
          "SELECT image_url FROM Product WHERE Barcode = '$text'",
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

  void _addProduct(Map<String, dynamic> element, {String mixMatch = ''}) {
    final keycode = element['Id']?.toString() ?? '';
    final sku = element['Barcode']?.toString() ?? '';
    final name = element['product_name'] ?? 'Unknown Product';
    final retailPrice = double.tryParse(element['retail_price']?.toString() ?? '0.0') ?? 0.0;
    final specialPrice = double.tryParse(element['special_price']?.toString() ?? '0.0') ?? 0.0;

    log('Product list : ${productList.isEmpty}');

    if (keycode.isNotEmpty || sku.isNotEmpty) {
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
    final connection = Provider.of<ConnectionProvider>(context).isConnected;

    return WillPopScope(
      onWillPop: () async => false, // Disable back button
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
                                    Container(
                                        height: 350.h,
                                        width: 1.w,
                                        color: Colors.grey.withOpacity(0.5)),
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
                                                  height: 400.h,
                                                  width: 160.w,
                                                  decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius: BorderRadius.circular(30.r)),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Text(
                                                        item.name,
                                                        textAlign: TextAlign.center,
                                                        style: TextStyle(
                                                          fontSize: 13.sp,
                                                          fontWeight: FontWeight.w700,
                                                        ),
                                                      ),
                                                      SizedBox(height: 20.h),
                                                      Padding(
                                                        padding: const EdgeInsets.symmetric(
                                                            horizontal: 8.0),
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment.center,
                                                          children: [
                                                            Expanded(
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
                                                              // flex: 2,
                                                              child: FittedBox(
                                                                child: Text(
                                                                  item.retailPrice
                                                                      .toStringAsFixed(2),
                                                                  style: TextStyle(
                                                                    fontSize: 20.sp,
                                                                    fontWeight: FontWeight.bold,
                                                                    color: Colors.green,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      SizedBox(height: 20.h),
                                                      if (item.mixAndMatch!.isNotEmpty)
                                                        FittedBox(
                                                          child: AnimatedBuilder(
                                                            animation: _scaleAnimation,
                                                            builder: (context, child) {
                                                              return Transform.scale(
                                                                scale: _scaleAnimation
                                                                    .value, // Apply zoom animation
                                                                child: AnimatedBuilder(
                                                                  animation: _colorAnimation,
                                                                  builder: (context, child) {
                                                                    return Text(
                                                                      item.mixAndMatch!,
                                                                      style: TextStyle(
                                                                        fontSize: 20.sp,
                                                                        fontWeight: FontWeight.bold,
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
                                                      if (item.specialPrice != null &&
                                                          item.specialPrice != 0.00) ...[
                                                        Padding(
                                                          padding: const EdgeInsets.symmetric(
                                                              horizontal: 15.0),
                                                          child: Container(
                                                            height: 1.h,
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding: const EdgeInsets.symmetric(
                                                              horizontal: 45.0),
                                                          child: Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment.center,
                                                            children: [
                                                              Expanded(
                                                                child: Text(
                                                                  'Discounted Price:',
                                                                  style: TextStyle(
                                                                    fontSize: 7.sp,
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
                                                                child: FittedBox(
                                                                  child: AnimatedBuilder(
                                                                    animation: _scaleAnimation,
                                                                    builder: (context, child) {
                                                                      return Transform.scale(
                                                                        scale: _scaleAnimation
                                                                            .value, // Apply zoom animation
                                                                        child: AnimatedBuilder(
                                                                          animation:
                                                                              _colorAnimation,
                                                                          builder:
                                                                              (context, child) {
                                                                            return Text(
                                                                              item.specialPrice!
                                                                                  .toStringAsFixed(
                                                                                      2),
                                                                              style: TextStyle(
                                                                                fontSize: 20.sp,
                                                                                fontWeight:
                                                                                    FontWeight.bold,
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
                                    'Please Scan Your Product',
                                    style: TextStyle(fontSize: 15.sp),
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
      ),
    );
  }
}
