import 'package:flutter/material.dart';

class NotificationStats extends StatelessWidget {
  final int noticiasNuevas;
  final int totalNoticias;

  const NotificationStats({
    super.key,
    required this.noticiasNuevas,
    required this.totalNoticias,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado
        const Text(
          'Resumen',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 14),

        // Grid de estadísticas
        Row(
          children: [
            // Estadística de Nuevas
            Expanded(
              child: _StatCard(
                icon: Icons.priority_high,
                iconColor: const Color(0xFFD92344),
                backgroundColor: const Color(0xFFFDEFF0),
                label: 'Nuevas',
                value: noticiasNuevas,
              ),
            ),
            const SizedBox(width: 12),

            // Estadística de Total
            Expanded(
              child: _StatCard(
                icon: Icons.inbox,
                iconColor: const Color(0xFF666666),
                backgroundColor: const Color(0xFFF0F0F0),
                label: 'Total',
                value: totalNoticias,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String label;
  final int value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono con fondo
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10),

          // Label
          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),

          // Valor
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
