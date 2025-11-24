import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';

class CartProvider with ChangeNotifier {
  Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};

  double get totalAmount {
    return _items.values.fold(
        0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  // 🔥 ADD ITEM TO CART
  Future<void> addItem(String productId, String title, double price) async {
    if (_items.containsKey(productId)) {
      _items.update(
        productId,
        (existingItem) => CartItem(
          id: existingItem.id,
          title: existingItem.title,
          price: existingItem.price,
          quantity: existingItem.quantity + 1,
        ),
      );
    } else {
      _items.putIfAbsent(
        productId,
        () => CartItem(
          id: productId,
          title: title,
          price: price,
          quantity: 1,
        ),
      );
    }
    notifyListeners();
  }

  // 📥 Fetch Cart from Backend
  Future<void> fetchCartFromServer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/cart/'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        _items = {}; // Clear local items

        for (var item in data['cart_items']) {
          _items[item['product_id'].toString()] = CartItem(
            id: item['product_id'].toString(),
            title: item['product_name'].toString(),
            quantity: int.tryParse(item['quantity'].toString()) ?? 1,
            price: double.tryParse(item['price'].toString()) ?? 0,
          );
        }
        notifyListeners();
      } else {
        debugPrint("Failed to load cart: ${response.statusCode}");
      }
    } catch (error) {
      debugPrint("Fetch Cart Error: $error");
    }
  }

  // ➕ Increment Quantity
  Future<void> incrementItem(String productId) async {
    if (_items.containsKey(productId)) {
      _items.update(
        productId,
        (item) => CartItem(
          id: item.id,
          title: item.title,
          price: item.price,
          quantity: item.quantity + 1,
        ),
      );
      notifyListeners();
    }
  }

  // ➖ Decrement Quantity
  Future<void> decrementItem(String productId) async {
    if (!_items.containsKey(productId)) return;

    if (_items[productId]!.quantity > 1) {
      _items.update(
        productId,
        (item) => CartItem(
          id: item.id,
          title: item.title,
          price: item.price,
          quantity: item.quantity - 1,
        ),
      );
    } else {
      removeItem(productId);
    }
    notifyListeners();
  }

  // 🗑 Remove Item
  Future<void> removeItem(String productId) async {
    _items.remove(productId);
    notifyListeners();
  }
}
