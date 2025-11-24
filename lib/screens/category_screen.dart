import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rjn_store_app/providers/cart_provider.dart' as cart_provider;
import 'package:rjn_store_app/screens/product_detail_screen.dart';
import 'dart:convert'; // For jsonDecode
import 'package:http/http.dart' as http;

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  CategoryScreenState createState() => CategoryScreenState();
}

class CategoryScreenState extends State<CategoryScreen> {
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> allProducts = [];
  List<Map<String, dynamic>> filteredProducts = [];

  bool isLoadingCategories = true;
  bool isLoadingProducts = true;
  int? selectedCategoryId;

  final String baseUrl = "http://10.0.2.2:8000/api";

  @override
  void initState() {
    super.initState();
    fetchCategoriesAndProducts();
  }

  Future<void> fetchCategoriesAndProducts() async {
    setState(() {
      isLoadingCategories = true;
      isLoadingProducts = true;
    });

    try {
      final categoryResponse = await http.get(Uri.parse("$baseUrl/categories/"));
      if (categoryResponse.statusCode == 200) {
        final categoryData = jsonDecode(categoryResponse.body);
        categories = parseListFromResponse(categoryData);
      } else {
        categories = [];
      }

      final productResponse = await http.get(Uri.parse("$baseUrl/products/"));
      if (productResponse.statusCode == 200) {
        final productData = jsonDecode(productResponse.body);
        allProducts = parseListFromResponse(productData);
        filteredProducts = List.from(allProducts);
      } else {
        allProducts = [];
        filteredProducts = [];
      }
    } catch (e) {
      categories = [];
      allProducts = [];
      filteredProducts = [];
    } finally {
      setState(() {
        isLoadingCategories = false;
        isLoadingProducts = false;
      });
    }
  }

  List<Map<String, dynamic>> parseListFromResponse(dynamic data) {
    if (data is List) {
      return data
          .where((e) => e != null)
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
          .toList();
    } else if (data is Map) {
      if (data.containsKey('results') && data['results'] is List) {
        return List<Map<String, dynamic>>.from(data['results']);
      } else if (data.containsKey('data') && data['data'] is List) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else if (data.containsKey('categories') && data['categories'] is List) {
        return List<Map<String, dynamic>>.from(data['categories']);
      } else {
        for (final entry in data.entries) {
          if (entry.value is List) {
            return List<Map<String, dynamic>>.from(entry.value);
          }
        }
      }
    }
    return [];
  }

  void filterProductsByCategory(int? categoryId) {
    setState(() {
      selectedCategoryId = categoryId;
      if (categoryId == null || categoryId == 0) {
        filteredProducts = List.from(allProducts);
      } else {
        filteredProducts = allProducts.where((p) {
          final category = p['category'];
          if (category is Map<String, dynamic>) {
            return category['id'] == categoryId;
          } else if (category is int) {
            return category == categoryId;
          }
          return false;
        }).toList();
      }
    });
  }

  PreferredSizeWidget buildCategoryAppBar() {
    return AppBar(
      title:
          const Text('Categories', style: TextStyle(fontWeight: FontWeight.bold)),
      centerTitle: true,
      backgroundColor: Colors.deepPurple,
      elevation: 2,
    );
  }

  Widget buildCategoryList() {
    if (isLoadingCategories) {
      return const Center(child: CircularProgressIndicator());
    }
    if (categories.isEmpty) {
      return const Center(child: Text("No categories available"));
    }

    return SizedBox(
      height: 150, // Increased size
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final bool isSelected = selectedCategoryId == category['id'];
          final imageUrl = (category['image'] ?? '').toString();

          return GestureDetector(
            onTap: () {
              final id = category['id'];
              int? categoryId;
              if (id is int) {
                categoryId = id;
              } else if (id is String) {
                final parsedId = int.tryParse(id);
                if (parsedId != null) categoryId = parsedId;
              }
              filterProductsByCategory(categoryId);
            },
            child: Container(
              width: 130, // Increased width
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              padding: const EdgeInsets.all(8), // Padding added
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.deepPurple.withAlpha(25)
                    : Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12, blurRadius: 5, offset: Offset(0, 2)),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      imageUrl.isNotEmpty
                          ? imageUrl
                          : 'https://via.placeholder.com/80',
                      width: 80, // Increased image size
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported, size: 50),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Flexible(
                    child: Text(
                      category['name']?.toString() ?? 'No Name',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color:
                            isSelected ? Colors.deepPurple : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildProductList() {
    if (isLoadingProducts) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }
    if (filteredProducts.isEmpty) {
      return const Expanded(
          child: Center(child: Text("No products in this category")));
    }

    final cartProvider =
        Provider.of<cart_provider.CartProvider>(context, listen: false);

    return Expanded(
      child: ListView.builder(
        itemCount: filteredProducts.length,
        itemBuilder: (context, index) {
          final product = filteredProducts[index];
          final imageUrl =
              (product['image'] ?? 'https://via.placeholder.com/100')
                  .toString();

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
            child: Card(
              margin:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              elevation: 3,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        bottomLeft: Radius.circular(15)),
                    child: Image.network(
                      imageUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey.withAlpha(25),
                        child:
                            const Icon(Icons.image_not_supported, size: 40),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['name']?.toString() ?? 'No Name',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "₹${product['price'] ?? '0'}",
                            style: const TextStyle(
                                fontSize: 15,
                                color: Colors.green,
                                fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product['description']?.toString() ??
                                'No description',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Colors.black.withAlpha(150),
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildCategoryAppBar(),
      body: Column(
        children: [
          buildCategoryList(),
          const Divider(height: 1),
          buildProductList(),
        ],
      ),
    );
  }
}
