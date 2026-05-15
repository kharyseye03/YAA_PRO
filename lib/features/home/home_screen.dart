import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.availableOrders),
      ),
      body: const Center(
        child: Text('Dashboard livreur — à implémenter'),
      ),
    );
  }
}
