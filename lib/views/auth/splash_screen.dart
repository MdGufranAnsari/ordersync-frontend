import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/local_storage.dart';
import 'login_screen.dart';
import '../orders/customer_dashboard.dart';
import '../orders/seller_dashboard.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    final token = TokenStorage.getToken();
    final role = TokenStorage.getRole();

    if (token != null && role != null) {
      if (role == 'seller') {
        _go(const SellerDashboard());
      } else {
        _go(const CustomerDashboard());
      }
    } else {
      _go(const LoginScreen());
    }
  }

  void _go(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.shopping_bag_rounded, size: 44, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              'Customer Seller',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Order Management',
              style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 40),
            CircularProgressIndicator(color: cs.primary),
          ],
        ),
      ),
    );
  }
}
