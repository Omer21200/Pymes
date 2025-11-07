import 'package:flutter/material.dart';

class MetricsRow extends StatelessWidget {
  final String dias;
  final String asistencia;
  final String aTiempo;

  const MetricsRow({
    this.dias = '20',
    this.asistencia = '95%',
    this.aTiempo = '18',
    super.key,
  });

  Widget _item(String value, String label, IconData icon, Color iconBg, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            CircleAvatar(backgroundColor: iconBg, radius: 18, child: Icon(icon, color: iconColor, size: 18)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _item(dias, 'Días', Icons.calendar_today, const Color(0xFFE9F2FF), const Color(0xFF2B6CB0)),
        _item(asistencia, 'Asistencia', Icons.show_chart, const Color(0xFFEFF8F0), const Color(0xFF2F855A)),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: const [
                CircleAvatar(backgroundColor: Color(0xFFFFF7E6), radius: 18, child: Icon(Icons.emoji_events, color: Color(0xFFB76300), size: 18)),
                SizedBox(height: 8),
                Text('18', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                SizedBox(height: 4),
                Text('A tiempo', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
