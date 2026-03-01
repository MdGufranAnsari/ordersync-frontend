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
  final String? customerProfileImage;
  final String sellerId;
  final String sellerName;
  final String sellerPhone;
  final String? sellerProfileImage;
  final List<OrderItem> items;
  final double totalAmount;
  final String status;
  final String createdAt;

  // New lifecycle fields
  final String? pickupType;      // 'immediate' | 'later'
  final String? pickupCode;      // 4-digit code for later pickup
  final bool codeVerified;
  final String? readyAt;
  final String? pickupDeadline;

  OrderModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    this.customerProfileImage,
    required this.sellerId,
    required this.sellerName,
    required this.sellerPhone,
    this.sellerProfileImage,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.pickupType,
    this.pickupCode,
    this.codeVerified = false,
    this.readyAt,
    this.pickupDeadline,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      customerName: json['customerName'] as String? ?? 'Unknown',
      customerPhone: json['customerPhone'] as String? ?? 'N/A',
      customerProfileImage: json['customerProfileImage'] as String?,
      sellerId: json['sellerId'] as String,
      sellerName: json['sellerName'] as String? ?? 'Unknown',
      sellerPhone: json['sellerPhone'] as String? ?? 'N/A',
      sellerProfileImage: json['sellerProfileImage'] as String?,
      items: (json['items'] as List)
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: json['createdAt'] as String,
      pickupType: json['pickupType'] as String?,
      pickupCode: json['pickupCode'] as String?,
      codeVerified: json['codeVerified'] as bool? ?? false,
      readyAt: json['readyAt'] as String?,
      pickupDeadline: json['pickupDeadline'] as String?,
    );
  }

  /// Deadline as local DateTime for countdown calculations
  DateTime? get pickupDeadlineLocal {
    if (pickupDeadline == null) return null;
    return DateTime.tryParse(pickupDeadline!)?.toLocal();
  }

  bool get isExpired => pickupDeadlineLocal != null && DateTime.now().isAfter(pickupDeadlineLocal!);
}
