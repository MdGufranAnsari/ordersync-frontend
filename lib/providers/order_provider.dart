import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/order_repository.dart';
import '../models/order_model.dart';

// Repository provider
final orderRepositoryProvider =
    Provider<OrderRepository>((ref) => OrderRepository());

// Order state
class OrderState {
  final bool isLoading;
  final List<OrderModel> orders;
  final String? error;

  const OrderState({
    this.isLoading = false,
    this.orders = const [],
    this.error,
  });

  OrderState copyWith({
    bool? isLoading,
    List<OrderModel>? orders,
    String? error,
  }) {
    return OrderState(
      isLoading: isLoading ?? this.isLoading,
      orders: orders ?? this.orders,
      error: error,
    );
  }
}

// Order notifier
class OrderNotifier extends StateNotifier<OrderState> {
  final OrderRepository _repository;

  OrderNotifier(this._repository) : super(const OrderState());

  // ── Helper: replace a single order in the list ──
  List<OrderModel> _replace(OrderModel updated) =>
      state.orders.map((o) => o.id == updated.id ? updated : o).toList();

  Future<bool> createOrder({
    required String sellerId,
    required List<Map<String, dynamic>> items,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final order = await _repository.createOrder(sellerId: sellerId, items: items);
      state = state.copyWith(isLoading: false, orders: [...state.orders, order]);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> fetchCustomerOrders() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final orders = await _repository.getCustomerOrders();
      state = state.copyWith(isLoading: false, orders: orders);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchSellerOrders() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final orders = await _repository.getSellerOrders();
      state = state.copyWith(isLoading: false, orders: orders);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> updateOrderPrices({
    required String orderId,
    required List<Map<String, dynamic>> items,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await _repository.updateOrderPrices(orderId: orderId, items: items);
      state = state.copyWith(isLoading: false, orders: _replace(updated));
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateOrderItems({
    required String orderId,
    required List<Map<String, dynamic>> items,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await _repository.updateOrderItems(orderId: orderId, items: items);
      state = state.copyWith(isLoading: false, orders: _replace(updated));
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> confirmOrder({
    required String orderId,
    required String pickupType,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await _repository.confirmOrder(orderId: orderId, pickupType: pickupType);
      state = state.copyWith(isLoading: false, orders: _replace(updated));
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> markReady({required String orderId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await _repository.markReady(orderId: orderId);
      state = state.copyWith(isLoading: false, orders: _replace(updated));
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> verifyCode({
    required String orderId,
    required String code,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await _repository.verifyCode(orderId: orderId, code: code);
      state = state.copyWith(isLoading: false, orders: _replace(updated));
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> completeOrder({required String orderId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await _repository.completeOrder(orderId: orderId);
      state = state.copyWith(isLoading: false, orders: _replace(updated));
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<Map<String, dynamic>?> reportNoShow({required String orderId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repository.reportNoShow(orderId: orderId);
      // Remove the expired order from the list
      final updated = state.orders.where((o) => o.id != orderId).toList();
      // Re-fetch to get updated status
      state = state.copyWith(isLoading: false, orders: updated);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

// Provider
final orderProvider =
    StateNotifierProvider<OrderNotifier, OrderState>((ref) {
  return OrderNotifier(ref.read(orderRepositoryProvider));
});
