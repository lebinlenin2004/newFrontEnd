import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../models/product_model.dart';
import '../models/cart_item.dart';

class ApiService {
  final String baseUrl = "http://10.0.2.2:8000/api";

  String? _accessToken;
  String? _refreshToken;

  String? get accessToken => _accessToken;

  Future<void> loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access');
    _refreshToken = prefs.getString('refresh');
  }

  Future<Map<String, String>> _headers() async {
    await loadTokens();
    return {
      "Content-Type": "application/json",
      if (_accessToken != null) "Authorization": "Bearer $_accessToken",
    };
  }

  // REGISTER USER
  Future<bool> registerUser(String username, String email, String password) async {
    final url = Uri.parse('$baseUrl/register/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'email': email, 'password': password}),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Registration Error: $e');
      return false;
    }
  }

  // LOGIN USER
  Future<bool> loginUser(String username, String password) async {
    final url = Uri.parse('$baseUrl/login/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access'];
        _refreshToken = data['refresh'];

        if (_accessToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access', _accessToken!);
          await prefs.setString('refresh', _refreshToken!);
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Login Error: $e');
      return false;
    }
  }

  // FETCH PRODUCTS
  Future<List<Product>> fetchProducts() async {
    final url = Uri.parse('$baseUrl/products/');
    try {
      final response = await http.get(url, headers: await _headers());
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Product>.from(data.map((p) => Product.fromJson(p)));
      }
    } catch (e) {
      debugPrint('Fetch Products Error: $e');
    }
    return [];
  }

  // ADD TO CART
  Future<bool> addToCart(String productId) async {
    final url = Uri.parse("$baseUrl/cart/add/");
    try {
      final response = await http.post(
        url,
        headers: await _headers(),
        body: jsonEncode({"product_id": productId}),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("Add to Cart Error: $e");
      return false;
    }
  }

  // UPDATE CART
  Future<bool> updateCart(String productId, int qty) async {
    final url = Uri.parse("$baseUrl/cart/update/");
    try {
      final response = await http.put(
        url,
        headers: await _headers(),
        body: jsonEncode({"product_id": productId, "quantity": qty}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Update Cart Error: $e");
      return false;
    }
  }

  // REMOVE FROM CART
  Future<bool> removeFromCart(String productId) async {
    final url = Uri.parse("$baseUrl/cart/remove/");
    try {
      final response = await http.delete(
        url,
        headers: await _headers(),
        body: jsonEncode({"product_id": productId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Remove Cart Error: $e");
      return false;
    }
  }

  // FETCH CART (Correct Method)
  Future<List<CartItem>> fetchCart() async {
    final url = Uri.parse("$baseUrl/cart/");
    try {
      final response = await http.get(url, headers: await _headers());
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<CartItem>.from(data.map((i) => CartItem.fromJson(i)));
      }
    } catch (e) {
      debugPrint("Fetch Cart Error: $e");
    }
    return [];
  }
}
