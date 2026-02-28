import '../core/utils/constants.dart';
import '../core/services/api_service.dart';
import '../models/order_model.dart';

class OrderRepository {
  Future<OrderModel> createOrder({
    required String sellerId,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await ApiClient.post(AppConstants.orders, {
      'sellerId': sellerId,
      'items': items,
    });
    return OrderModel.fromJson(response['order'] as Map<String, dynamic>);
  }

  Future<List<OrderModel>> getCustomerOrders() async {
    final response = await ApiClient.get(AppConstants.customerOrders);
    final list = response['orders'] as List;
    return list.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<OrderModel>> getSellerOrders() async {
    final response = await ApiClient.get(AppConstants.sellerOrders);
    final list = response['orders'] as List;
    return list.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<OrderModel> updateOrderPrices({
    required String orderId,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await ApiClient.put(
      '${AppConstants.orders}/$orderId',
      {'items': items},
    );
    return OrderModel.fromJson(response['order'] as Map<String, dynamic>);
  }

  Future<OrderModel> updateOrderItems({
    required String orderId,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await ApiClient.patch(
      '${AppConstants.orders}/$orderId/items',
      {'items': items},
    );
    return OrderModel.fromJson(response['order'] as Map<String, dynamic>);
  }
}
