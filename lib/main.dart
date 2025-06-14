import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bakery_app/services/cart_service.dart';
import 'package:bakery_app/services/order_service.dart'; // TAMBAHKAN INI
import 'package:bakery_app/pages/home.dart';

void main() async {
  // TAMBAHKAN INI - Penting untuk async operations
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize CartService dan load data dari storage
  final cartService = CartService();
  await cartService.initializeCart(); // PENTING: Initialize cart sebelum app start
  
  runApp(BakeryApp(cartService: cartService));
}

class BakeryApp extends StatelessWidget {
  final CartService cartService;
  
  // TAMBAHKAN constructor untuk menerima cartService
  const BakeryApp({Key? key, required this.cartService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider( // GANTI dari ChangeNotifierProvider ke MultiProvider
      providers: [
        // Gunakan .value karena instance sudah dibuat
        ChangeNotifierProvider.value(value: cartService),
        
        // TAMBAHKAN OrderService - ini yang hilang!
        ChangeNotifierProvider(create: (context) => OrderService()),
      ],
      child: MaterialApp(
        title: 'Toko Roti Online',
        theme: ThemeData(
          primarySwatch: Colors.orange,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          // TAMBAHKAN theme customization untuk form
          inputDecorationTheme: InputDecorationTheme(
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.orange.shade600),
            ),
          ),
        ),
        home: HomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}