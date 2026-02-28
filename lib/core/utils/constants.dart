class AppConstants {
  AppConstants._();

  static const String baseUrl = 'https://ordersync-backend-production.up.railway.app/api';

  // Auth endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';

  // Order endpoints
  static const String orders = '/orders';
  static const String customerOrders = '/orders/customer';
  static const String sellerOrders = '/orders/seller';

  // User endpoints
  static const String sellers = '/users/sellers';
}
