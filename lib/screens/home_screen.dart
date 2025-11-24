import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:carousel_slider/carousel_slider.dart';

// Import CartProvider with alias to avoid ambiguity
import 'package:rjn_store_app/providers/cart_provider.dart' as cart_provider;

import 'package:rjn_store_app/screens/category_screen.dart';
import 'package:rjn_store_app/screens/product_detail_screen.dart';
import 'package:rjn_store_app/screens/cart_screen.dart';
import 'package:rjn_store_app/screens/orders_screen.dart';
import 'package:rjn_store_app/screens/profile_screen.dart';

import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<dynamic> products = [];
  List<dynamic> filteredProducts = [];
  List<dynamic> categories = [];
  List<dynamic> offers = [];
  bool isLoadingProducts = true;
  bool isLoadingCategories = true;
  int selectedCategoryId = 0;
  bool isSearching = false;
  String searchQuery = "";

  final String baseUrl = "http://10.0.2.2:8000/api";

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    await Future.wait([fetchCategories(), fetchProducts(), fetchOffers()]);
  }

  Future<void> fetchOffers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/offers/'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> fetchedOffers = [];
        if (data is Map && data['results'] != null) {
          fetchedOffers = data['results'];
        } else if (data is List) {
          fetchedOffers = data;
        }
        setState(() {
          offers = fetchedOffers;
        });
      } else {
        debugPrint('❌ Failed to fetch offers: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('🚨 Error fetching offers: $e');
    }
  }

  Future<void> fetchProducts() async {
    setState(() => isLoadingProducts = true);
    try {
      final response = await http.get(Uri.parse('$baseUrl/products/'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> fetchedProducts = [];
        if (data is Map && data['results'] != null) {
          fetchedProducts = data['results'];
        } else if (data is List) {
          fetchedProducts = data;
        }
        setState(() {
          products = fetchedProducts;
          filteredProducts = products;
          isLoadingProducts = false;
        });
      } else {
        setState(() => isLoadingProducts = false);
        debugPrint('❌ Failed to fetch products: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => isLoadingProducts = false);
      debugPrint('🚨 Error fetching products: $e');
    }
  }

  Future<void> fetchCategories() async {
    setState(() => isLoadingCategories = true);
    try {
      final response = await http.get(Uri.parse('$baseUrl/categories/'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> fetchedCategories = [];
        if (data is Map && data['results'] != null) {
          fetchedCategories = data['results'];
        } else if (data is List) {
          fetchedCategories = data;
        }
        setState(() {
          categories = [
            {'id': 0, 'name': 'All', 'image': null},
            ...fetchedCategories
          ];
          isLoadingCategories = false;
        });
      } else {
        setState(() => isLoadingCategories = false);
        debugPrint('❌ Failed to fetch categories: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => isLoadingCategories = false);
      debugPrint('🚨 Error fetching categories: $e');
    }
  }

  void filterByCategory(int categoryId) {
    setState(() {
      selectedCategoryId = categoryId;
      filteredProducts = categoryId == 0
          ? products
          : products.where((p) {
              final c = p['category'];
              if (c is int) return c == categoryId;
              if (c is Map<String, dynamic>) return c['id'] == categoryId;
              return false;
            }).toList();

      if (searchQuery.isNotEmpty) {
        filteredProducts = filteredProducts
            .where((p) =>
                p['name'].toLowerCase().contains(searchQuery.toLowerCase()) ||
                (p['description'] ?? '')
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()))
            .toList();
      }
    });
  }

  void _filterProducts(String query) {
    setState(() {
      searchQuery = query;
      filteredProducts = products
          .where((p) =>
              (selectedCategoryId == 0 ||
                  (p['category'] is int
                      ? p['category'] == selectedCategoryId
                      : p['category']['id'] == selectedCategoryId)) &&
              (p['name'].toLowerCase().contains(query.toLowerCase()) ||
                  (p['description'] ?? '')
                      .toLowerCase()
                      .contains(query.toLowerCase())))
          .toList();
    });
  }

  void resetSearch() {
    setState(() {
      isSearching = false;
      searchQuery = "";
      filteredProducts = selectedCategoryId == 0
          ? products
          : products.where((p) {
              final c = p['category'];
              if (c is int) return c == selectedCategoryId;
              if (c is Map<String, dynamic>) return c['id'] == selectedCategoryId;
              return false;
            }).toList();
    });
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  PreferredSizeWidget? buildAppBar() {
    if (_selectedIndex != 0) return null;

    return AppBar(
      title: !isSearching
          ? const Text("RJN Store", style: TextStyle(fontWeight: FontWeight.bold))
          : TextField(
              autofocus: true,
              onChanged: _filterProducts,
              decoration: const InputDecoration(
                hintText: "Search products...",
                border: InputBorder.none,
              ),
            ),
      centerTitle: true,
      backgroundColor: Colors.deepPurple,
      actions: [
        IconButton(
          icon: Icon(isSearching ? Icons.close : Icons.search),
          onPressed: () {
            setState(() {
              if (isSearching) resetSearch();
              isSearching = !isSearching;
            });
          },
        ),
      ],
    );
  }

  Widget buildOffers() {
    if (offers.isEmpty) return const SizedBox.shrink();
    return CarouselSlider(
      options: CarouselOptions(
        height: 180,
        enlargeCenterPage: true,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 3),
        viewportFraction: 0.9,
      ),
      items: offers.map((offer) {
        return Builder(
          builder: (BuildContext context) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                image: DecorationImage(
                  image: NetworkImage(offer['image']),
                  fit: BoxFit.cover,
                ),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(2, 2)),
                ],
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget buildCategories() {
    if (isLoadingCategories) {
      return const Center(child: CircularProgressIndicator());
    }

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final bool isSelected = selectedCategoryId == category['id'];
          final imageUrl = category['image'] ?? 'https://cdn-icons-png.flaticon.com/512/3081/3081559.png';

          return GestureDetector(
            onTap: () => filterByCategory(category['id']),
            child: Container(
              width: 80,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.deepPurple : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.category, color: Colors.deepPurple),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildProducts() {
    if (isLoadingProducts) {
      return const Center(child: CircularProgressIndicator());
    }
    if (filteredProducts.isEmpty) {
      return const Center(child: Text("No products found"));
    }

    final cartProvider = Provider.of<cart_provider.CartProvider>(context, listen: false);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.70,
      ),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        final imageUrl = product['image'] ?? 'https://via.placeholder.com/150';

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(
                  product: product,
                  onAddToCart: () {
                   cartProvider.addItem(
  product['id'].toString(),
  product['name'].toString(),
  double.tryParse(product['price'].toString()) ?? 0,
);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Added to cart!')),
                    );
                  },
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(color: Colors.grey.shade300, blurRadius: 5, offset: const Offset(2, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  child: Image.network(
                    imageUrl,
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey.withAlpha((0.1 * 255).round()),
                      child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "₹${product['price']}",
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_shopping_cart),
                        onPressed: () {
                          cartProvider.addItem(
  product['id'].toString(),
  product['name'].toString(),
  double.tryParse(product['price'].toString()) ?? 0,
);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Added to cart!')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildOffers(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text("Categories", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              buildCategories(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text("Products", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              buildProducts(),
            ],
          ),
        );
      case 1:
        return const CategoryScreen();
      case 2:
        return CartScreen();
      case 3:
        return const OrdersScreen();
      case 4:
        return const ProfileScreen();
      default:
        return buildProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      body: getSelectedPage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: "Categories"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Cart"),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: "Orders"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
