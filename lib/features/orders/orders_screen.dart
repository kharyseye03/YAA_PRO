import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.myDeliveries)),
      body: const Center(
        child: Text('Liste des livraisons — à implémenter'),
      ),
    );
  }
}
