class CartItem {
  final String id; // Product ID as string (consistent with API usage)
  final String title;
  final double price;
  final int quantity;

  CartItem({
    required this.id,
    required this.title,
    required this.price,
    required this.quantity,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['product_id'].toString(), // Use product_id for consistency
      title: json['product_name'] ?? json['product']['name'] ?? 'Unknown',
      price: double.tryParse(
              json['price']?.toString() ??
              json['product']?['price']?.toString() ??
              '0') ??
          0.0,
      quantity: json['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': id,
      'product_name': title,
      'price': price,
      'quantity': quantity,
    };
  }
}
