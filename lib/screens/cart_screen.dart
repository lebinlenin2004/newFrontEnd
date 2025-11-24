import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'buy_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Future<void> _cartFuture;

  @override
  void initState() {
    super.initState();
    _cartFuture = Provider.of<CartProvider>(context, listen: false).fetchCartFromServer();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
      ),
      body: FutureBuilder(
        future: _cartFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final cartItems = cartProvider.items.values.toList();

          return cartItems.isEmpty
              ? const Center(child: Text('Your cart is empty'))
              : ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (_, index) {
                    final item = cartItems[index];

                    return Card(
                      child: ListTile(
                        title: Text(item.title),
                        subtitle: Text('₹${item.price.toStringAsFixed(2)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () async {
                                await cartProvider.decrementItem(item.id);
                              },
                            ),
                            Text('${item.quantity}'),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () async {
                                await cartProvider.incrementItem(item.id);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                await cartProvider.removeItem(item.id);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total: ₹${cartProvider.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            ElevatedButton(
  onPressed: cartProvider.items.isEmpty
      ? null
      : () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BuyScreen(
                totalAmount: cartProvider.totalAmount,
                items: cartProvider.items.values.toList(),
              ),
            ),
          );
        },
  child: const Text('Buy'),
),

          ],
        ),
      ),
    );
  }
}
