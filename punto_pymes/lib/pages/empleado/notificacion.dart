import 'package:flutter/material.dart';

class NotificacionPage extends StatelessWidget {
  const NotificacionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD92344),
        elevation: 0,
        title: const Text('Notificaciones'),
        centerTitle: false,
      ),
      body: const NotificacionView(),
    );
  }
}

/// Shared notification layout so the same cards can be embedded elsewhere.
class NotificacionView extends StatelessWidget {
  final EdgeInsetsGeometry padding;

  const NotificacionView({super.key, this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0)});

  static final List<Map<String, Object>> _summaryStats = [
    {
      'label': 'Nuevas',
      'value': '2',
      'icon': Icons.add_alert,
      'color': Color(0xFFFAD1D1),
    },
    {
      'label': 'Total',
      'value': '4',
      'icon': Icons.inbox,
      'color': Colors.white,
    },
  ];

  static final List<Map<String, Object>> _notifications = [
    {
      'title': 'Actualización de horarios',
      'subtitle': 'Se modifican los horarios de entrada a partir del próximo lunes.',
      'date': '2025-11-01',
      'status': 'Nueva',
      'theme': Colors.redAccent,
    },
    {
      'title': 'Reunión general',
      'subtitle': 'Reunión general este viernes a las 3PM en el auditorio principal.',
      'date': '2025-10-28',
      'status': 'Nueva',
      'theme': Colors.redAccent,
    },
    {
      'title': '¡Felicidades!',
      'subtitle': 'Has completado 30 días consecutivos de puntualidad. Sigue así.',
      'date': '2025-10-24',
      'status': 'Logro',
      'theme': Color(0xFFFDEACF),
    },
  ];

  Widget _buildSummaryCard(Map<String, Object> stat) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: stat['color'] as Color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(stat['icon'] as IconData, color: Colors.black45),
            const SizedBox(height: 12),
            Text(stat['label'] as String, style: const TextStyle(color: Colors.black54, fontSize: 14)),
            const SizedBox(height: 8),
            Text(stat['value'] as String, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, Object> notification) {
    final bool highlight = notification['status'] == 'Nueva';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFFDEFF0) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notification_important, color: notification['theme'] as Color),
              const SizedBox(width: 8),
              Text(notification['title'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (notification['status'] == 'Nueva') ? Colors.redAccent : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  notification['status'] as String,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(notification['subtitle'] as String, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.schedule, size: 14, color: Colors.black45),
              const SizedBox(width: 6),
              Text(notification['date'] as String, style: const TextStyle(color: Colors.black45, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mensajes y actualizaciones', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 16),
          Row(
            children: _summaryStats.map(_buildSummaryCard).toList(),
          ),
          const SizedBox(height: 20),
          ..._notifications.map(_buildNotificationCard),
        ],
      ),
    );
  }
}
