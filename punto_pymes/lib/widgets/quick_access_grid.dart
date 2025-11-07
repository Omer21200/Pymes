import 'package:flutter/material.dart';

class QuickAccessGrid extends StatelessWidget {
  final VoidCallback? onRegister;
  final VoidCallback? onReports;

  const QuickAccessGrid({
    this.onRegister,
    this.onReports,
    super.key,
  });

  Widget _tile(IconData icon, String title, String subtitle, Color bg, Color iconColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: bg, radius: 20, child: Icon(icon, color: iconColor)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(onTap: onRegister, child: _tile(Icons.alarm, 'Registrar', 'Marcar asistencia', const Color(0xFFFFEFEF), const Color(0xFFD23A3A))),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(onTap: onReports, child: _tile(Icons.description, 'Reportes', 'Ver historial', const Color(0xFFEFF6FF), const Color(0xFF2B6CB0))),
            ),
          ],
        ),
      ],
    );
  }
}
