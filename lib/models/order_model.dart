class OrderItem {
  final String name;
  final int quantity;
  final double? price;

  OrderItem({required this.name, required this.quantity, this.price});

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['name'] as String,
      quantity: json['quantity'] as int,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
    );
  }
}

class OrderModel {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String sellerId;
  final String sellerName;
  final String sellerPhone;
  final List<OrderItem> items;
  final double totalAmount;
  final String status;
  final String createdAt;

  OrderModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.sellerId,
    required this.sellerName,
    required this.sellerPhone,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      customerName: json['customerName'] as String? ?? 'Unknown',
      customerPhone: json['customerPhone'] as String? ?? 'N/A',
      sellerId: json['sellerId'] as String,
      sellerName: json['sellerName'] as String? ?? 'Unknown',
      sellerPhone: json['sellerPhone'] as String? ?? 'N/A',
      items: (json['items'] as List)
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: json['createdAt'] as String,
    );
  }
}
