import 'package:flutter/material.dart';

class AdminEmpresaHeader extends StatelessWidget {
  final String? nombreAdmin;
  final String? nombreEmpresa;
  final VoidCallback? onLogout;

  const AdminEmpresaHeader({
    super.key,
    this.nombreAdmin,
    this.nombreEmpresa,
    this.onLogout,
  });

  String _getInitials() {
    if (nombreAdmin == null || nombreAdmin!.isEmpty) return 'AD';
    final parts = nombreAdmin!.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return nombreAdmin!.substring(0, 2).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFFD92344),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Text(
              _getInitials(),
              style: const TextStyle(color: Color(0xFFD92344), fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin ${nombreEmpresa ?? "Empresa"}',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  nombreAdmin ?? 'Administrador',
                  style: const TextStyle(color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.exit_to_app, color: Colors.white, size: 24),
            onPressed: onLogout,
          ),
        ],
      ),
    );
  }
}
