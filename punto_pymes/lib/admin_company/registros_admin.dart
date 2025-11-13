import 'package:flutter/material.dart';
import '../widgets/registro_item.dart';

class RegistrosAdmin extends StatelessWidget {
  final String userId;
  final String? companyName;
  const RegistrosAdmin({required this.userId, this.companyName, super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Registros', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          RegistroItem(usuarioId: 'Juan Perez', timestamp: '2025-11-12 09:00'),
        ],
      ),
    );
  }
}
