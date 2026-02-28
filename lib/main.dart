import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/services/local_storage.dart';
import 'views/auth/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox(TokenStorage.boxName);

  runApp(
    const ProviderScope(
      child: CustomerSellerApp(),
    ),
  );
}

class CustomerSellerApp extends StatelessWidget {
  const CustomerSellerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Customer Seller',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3D52D5),
          brightness: Brightness.light,
          surface: const Color(0xFFF0F2F5),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF0F2F5),
      ),
      home: const SplashScreen(),
    );
  }
}
