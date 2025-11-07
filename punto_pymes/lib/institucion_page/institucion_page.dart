import 'package:flutter/material.dart';
import '../main.dart';

class InstitucionPage extends StatelessWidget {
  final String institutionName;

  const InstitucionPage({required this.institutionName, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(institutionName),
        backgroundColor: const Color(0xFFD92344),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await supabase.auth.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/access-selection',
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.apartment, size: 100, color: Color(0xFFD92344)),
            const SizedBox(height: 20),
            Text(
              'Panel de $institutionName',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD92344),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Bienvenido al panel de la institución',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
