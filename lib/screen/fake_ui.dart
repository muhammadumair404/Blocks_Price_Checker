import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

class ProductModel {
  final String barcode;
  final String name;
  final double price;
  final String? imageUrl;

  ProductModel({
    required this.barcode,
    required this.name,
    required this.price,
    this.imageUrl,
  });
}

class ScanScreen1 extends StatefulWidget {
  const ScanScreen1({super.key});

  @override
  State<ScanScreen1> createState() => _ScanScreen1State();
}

class _ScanScreen1State extends State<ScanScreen1>
    with TickerProviderStateMixin {
  final TextEditingController controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool isLoading = false;
  ProductModel? matchedProduct;
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
  List<ProductModel> filteredProducts = [];
  late Timer _timer;
  late AnimationController _scaleController;
  late AnimationController _colorController;
  Timer? _clearProductTimer; // Timer for clearing the product

  @override
  void initState() {
    super.initState();
    filteredProducts = List.from(staticProductList);
    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
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

    // Color Transition Animation
    _colorController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
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

  // Static list of 20 fruit products
  List<ProductModel> staticProductList = [
    ProductModel(
      barcode: '100001',
      name: 'Apple',
      price: 2.99,
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/1/15/Red_Apple.jpg/100px-Red_Apple.jpg',
    ),
    ProductModel(
      barcode: '100002',
      name: 'Banana',
      price: 1.99,
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8a/Banana-Single.jpg/100px-Banana-Single.jpg',
    ),
    ProductModel(
      barcode: '100003',
      name: 'Orange',
      price: 3.49,
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c4/Orange-Fruit-Pieces.jpg/100px-Orange-Fruit-Pieces.jpg',
    ),
    ProductModel(
      barcode: '100004',
      name: 'Strawberry',
      price: 4.25,
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/2/29/PerfectStrawberry.jpg/100px-PerfectStrawberry.jpg',
    ),
    ProductModel(
      barcode: '100005',
      name: 'Pineapple',
      price: 3.99,
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cb/Pineapple_and_cross_section.jpg/100px-Pineapple_and_cross_section.jpg',
    ),
    ProductModel(
      barcode: '100006',
      name: 'Mango',
      price: 5.99,
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/Hapus_Mango.jpg/100px-Hapus_Mango.jpg',
    ),
    ProductModel(
      barcode: '100007',
      name: 'Watermelon',
      price: 6.99,
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fc/Melon.jpg/100px-Melon.jpg',
    ),
    ProductModel(
      barcode: '100008',
      name: 'Grapes',
      price: 2.49,
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/b/bb/Table_grapes_on_white.jpg/100px-Table_grapes_on_white.jpg',
    ),
    ProductModel(
      barcode: '100009',
      name: 'Blueberry',
      price: 7.99,
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/1/12/Blueberries.jpg/100px-Blueberries.jpg',
    ),
    ProductModel(
      barcode: '100010',
      name: 'Cherry',
      price: 8.99,
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/b/bb/Cherry_Stella444.jpg/100px-Cherry_Stella444.jpg',
    ),
    ProductModel(
      barcode: '100011',
      name: 'Peach',
      price: 3.25,
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9f/Nectarine_and_cross_section02.jpg/100px-Nectarine_and_cross_section02.jpg',
    ),
    ProductModel(
      barcode: '100012',
      name: 'Plum',
      price: 2.75,
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f2/Plums.jpg/100px-Plums.jpg',
    ),
    ProductModel(
      barcode: '100013',
      name: 'Kiwi',
      price: 1.75,
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d3/Kiwi_aka.jpg/100px-Kiwi_aka.jpg',
    ),
    ProductModel(
      barcode: '100014',
      name: 'Papaya',
      price: 4.99,
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9f/Papaya_cross_section_BNC.jpg/100px-Papaya_cross_section_BNC.jpg',
    ),
    ProductModel(
      barcode: '100015',
      name: 'Lemon',
      price: 0.99,
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e4/Lemon.jpg/100px-Lemon.jpg',
    ),
    ProductModel(
      barcode: '100016',
      name: 'Grapefruit',
      price: 3.49,
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/0/07/Grapefruit.jpg/100px-Grapefruit.jpg',
    ),
    ProductModel(
      barcode: '100017',
      name: 'Pomegranate',
      price: 5.49,
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f7/Pomegranate_DSR.jpg/100px-Pomegranate_DSR.jpg',
    ),
    ProductModel(
      barcode: '100018',
      name: 'Coconut',
      price: 2.99,
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/7/75/Coconut.jpg/100px-Coconut.jpg',
    ),
    ProductModel(
      barcode: '100019',
      name: 'Blackberry',
      price: 6.49,
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/Blackberries.jpg/100px-Blackberries.jpg',
    ),
    ProductModel(
      barcode: '100020',
      name: 'Raspberry',
      price: 6.99,
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/9/91/Raspberries05.jpg/100px-Raspberries05.jpg',
    ),
  ];

  void searchProduct(String query) {
    setState(() {
      filteredProducts = staticProductList.where((product) {
        final nameLower = product.name.toLowerCase();
        final barcodeLower = product.barcode.toLowerCase();
        final searchLower = query.toLowerCase();
        return nameLower.contains(searchLower) ||
            barcodeLower.contains(searchLower);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search Field
                TextFormField(
                  style: const TextStyle(color: Colors.white),
                  controller: controller,
                  focusNode: _focusNode,
                  onChanged: searchProduct,
                  decoration: InputDecoration(
                    labelText: 'Search by Name or Barcode',
                    labelStyle: const TextStyle(color: Colors.white),
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Product GridView
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return ProductCard(product: product);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final ProductModel product;

  const ProductCard({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: product.imageUrl != null
                ? Image.network(
                    product.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.image_not_supported, size: 60);
                    },
                  )
                : const Icon(Icons.image_not_supported, size: 60),
          ),
          const SizedBox(height: 8),
          Text(
            product.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Price: \$${product.price.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.green),
          ),
          const SizedBox(height: 4),
          Text(
            'Barcode: ${product.barcode}',
            style: const TextStyle(fontSize: 10, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
