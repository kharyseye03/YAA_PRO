import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';

class DeliveryScreen extends StatelessWidget {
  const DeliveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.activeDelivery)),
      body: const Center(
        child: Text('Livraison en cours — à implémenter'),
      ),
    );
  }
}
