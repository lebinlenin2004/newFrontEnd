import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../models/product_model.dart';
import '../models/category_model.dart';

class ApiService {
  // Base URL (update according to your setup)
  final String baseUrl = "http://10.0.2.2:8000/api"; // Android emulator
  // final String baseUrl = 'http://192.168.x.x:8000/api'; // Real device

  String? _accessToken;
  String? _refreshToken;

  // Getter for access token
  String? get accessToken => _accessToken;

  // REGISTER USER
  Future<bool> registerUser(String username, String email, String password) async {
    final url = Uri.parse('$baseUrl/register/');
    debugPrint('📡 Sending registration request to: $url');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'email': email, 'password': password}),
      );

      debugPrint('📩 Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Registration successful');
        return true;
      } else {
        debugPrint('❌ Registration failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('🚨 Registration error: $e');
      return false;
    }
  }

  // LOGIN USER (JWT)
  Future<bool> loginUser(String username, String password) async {
    final url = Uri.parse('$baseUrl/login/');
    debugPrint('📡 Sending login request to: $url');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      debugPrint('📩 Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access'];
        _refreshToken = data['refresh'];

        if (_accessToken != null && _refreshToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access', _accessToken!);
          await prefs.setString('refresh', _refreshToken!);
          debugPrint('✅ Login successful — Tokens saved.');
          return true;
        }
      }

      debugPrint('❌ Login failed: ${response.statusCode} - ${response.body}');
      return false;
    } catch (e) {
      debugPrint('🚨 Login error: $e');
      return false;
    }
  }

  // LOAD TOKENS
  Future<void> loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access');
    _refreshToken = prefs.getString('refresh');
    debugPrint('🔑 Tokens loaded: access=$_accessToken, refresh=$_refreshToken');
  }

  // AUTHORIZED GET REQUEST
  Future<http.Response> getAuthorized(String endpoint) async {
    await loadTokens(); // ensure token is loaded
    final url = Uri.parse('$baseUrl/$endpoint');
    debugPrint('📡 Authorized GET request to: $url');

    return await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      },
    );
  }

  // FETCH PRODUCTS
  Future<List<Product>> fetchProducts() async {
    await loadTokens(); // ensure token is loaded
    final url = Uri.parse('$baseUrl/products/');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
        },
      );

      debugPrint('Products Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Product.fromJson(e)).toList();
      } else {
        debugPrint('❌ Failed to fetch products: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('🚨 Error fetching products: $e');
      return [];
    }
  }

  // FETCH CATEGORIES
  Future<List<Category>> fetchCategories() async {
    await loadTokens(); // ensure token is loaded
    final url = Uri.parse('$baseUrl/categories/');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
        },
      );

      debugPrint('Categories Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Category.fromJson(e)).toList();
      } else {
        debugPrint('❌ Failed to fetch categories: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('🚨 Error fetching categories: $e');
      return [];
    }
  }

  // FETCH OFFERS
  Future<List<Map<String, dynamic>>> fetchOffers() async {
    await loadTokens(); // ensure token is loaded
    final url = Uri.parse('$baseUrl/offers/');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
        },
      );

      debugPrint('Offers Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['results'] != null) {
          return List<Map<String, dynamic>>.from(data['results']);
        } else if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return [];
      } else {
        debugPrint('❌ Failed to fetch offers: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('🚨 Error fetching offers: $e');
      return [];
    }
  }

  // LOGOUT
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access');
    await prefs.remove('refresh');
    _accessToken = null;
    _refreshToken = null;
    debugPrint('🚪 Logged out — Tokens cleared.');
  }
}
