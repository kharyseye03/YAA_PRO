import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.myProfile)),
      body: const Center(
        child: Text('Profil livreur — à implémenter'),
      ),
    );
  }
}
