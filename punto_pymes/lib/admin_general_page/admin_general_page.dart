import 'package:flutter/material.dart';
import '../main.dart';

class AdminGeneralPage extends StatelessWidget {
  const AdminGeneralPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrador General'),
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
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.admin_panel_settings,
              size: 100,
              color: Color(0xFFD92344),
            ),
            SizedBox(height: 20),
            Text(
              'Panel de Administrador General',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD92344),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Bienvenido al panel de administración general',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
