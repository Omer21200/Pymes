import 'package:flutter/material.dart';
import '../widgets/report_summary.dart';
import '../widgets/report_history_item.dart';

class ReportesContent extends StatelessWidget {
  const ReportesContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('reportes'),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 120, top: 16),
        children: [
          const Text('Reportes', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Tus estadísticas de asistencia', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          const ReportSummary(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Historial Reciente', style: TextStyle(fontWeight: FontWeight.w600)),
              TextButton(onPressed: () {}, child: const Text('Noviembre', style: TextStyle(color: Color(0xFFD92344))))
            ],
          ),
          const SizedBox(height: 8),
          const ReportHistoryItem(initials: 'MG', time: '08:45 AM', date: '2025-11-05', location: 'Lat: -4.0323, Lng: -79.2039', today: true),
          const ReportHistoryItem(initials: 'MG', time: '08:42 AM', date: '2025-11-04', location: 'Lat: -4.0323, Lng: -79.2039'),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
