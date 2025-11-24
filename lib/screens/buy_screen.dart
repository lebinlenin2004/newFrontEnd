import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BuyScreen extends StatefulWidget {
  final double totalAmount;
  final List<CartItem> items;

  const BuyScreen({
    required this.totalAmount,
    required this.items,
    super.key,
  });

  @override
  BuyScreenState createState() => BuyScreenState();
}

class BuyScreenState extends State<BuyScreen> {
  final TextEditingController _addressController = TextEditingController();
  bool _isLoading = false;

  Future<void> placeOrder() async {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter delivery address")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final url = Uri.parse('http://10.0.2.2:8000/api/order/create/');
    final body = {
      "address": _addressController.text,
      "total_amount": widget.totalAmount,
      "items": widget.items
          .map((item) => {
                "product_id": item.id,
                "quantity": item.quantity,
                "price": item.price,
              })
          .toList(),
    };

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    // ⛑️ Safety check to prevent using context if widget disposed
    if (!mounted) return;

    setState(() => _isLoading = false);

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order placed successfully")),
      );
      Navigator.pop(context); // Go back to cart
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order failed, try again!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Place Order')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Amount: ₹${widget.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Delivery Address',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: placeOrder,
                      child: const Text('Confirm Order'),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
