import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bakery_app/services/cart_service.dart';
import 'package:bakery_app/pages/home.dart';

void main() {
  runApp(BakeryApp());
}

class BakeryApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CartService(),
      child: MaterialApp(
        title: 'Toko Roti Online',
        theme: ThemeData(
          primarySwatch: Colors.orange,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: HomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}