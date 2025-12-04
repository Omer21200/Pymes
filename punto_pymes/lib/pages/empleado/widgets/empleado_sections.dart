import 'package:flutter/material.dart';

import '../notificacion.dart';

class EmpleadoSections extends StatelessWidget {
  final int tabIndex;

  const EmpleadoSections({super.key, required this.tabIndex});

  @override
  Widget build(BuildContext context) {
    switch (tabIndex) {
      case 0:
        return _buildInicio(context);
      case 1:
        return _buildNotifications(context);
      case 2:
        return _buildReports(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildInicio(BuildContext context) {
    final stats = [
      {'label': 'Días', 'value': '20', 'icon': Icons.calendar_today},
      {'label': 'Asistencia', 'value': '95%', 'icon': Icons.show_chart},
      {'label': 'A tiempo', 'value': '18', 'icon': Icons.thumb_up},
    ];

    final quickAccess = [
      {'label': 'Registrar', 'subtitle': 'Marcar asistencia', 'icon': Icons.access_time},
      {'label': 'Reportes', 'subtitle': 'Ver historial', 'icon': Icons.description},
    ];

    final news = [
      {
        'title': 'Actualización de horarios',
        'body': 'Se modifican los horarios de entrada a partir del próximo lunes.',
        'date': '2025-11-01'
      }
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 16, bottom: 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Bienvenido', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 4),
          const Text('Tu espacio de empleado', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: stats
                .map(
                  (item) => Expanded(
                    child: _buildTinyCard(item['label'] as String, item['value'] as String, item['icon'] as IconData),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          const Text('Accesos rápidos', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: quickAccess
                .map(
                  (item) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(backgroundColor: Colors.red.shade50, child: Icon(item['icon'] as IconData, color: Colors.white)),
                          const SizedBox(height: 12),
                          Text(item['label'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(item['subtitle'] as String, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                )
                .toList()
              ..removeLast(),
          ),
          const SizedBox(height: 8),
          ...quickAccess
              .map(
                (item) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(backgroundColor: Colors.blue.shade50, child: Icon(item['icon'] as IconData, color: Colors.blue)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['label'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(item['subtitle'] as String, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          const Text('Noticias y anuncios', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          ...news.map((item) => _buildNewsRow(item)),
          const SizedBox(height: 140),
        ],
      ),
    );
  }

  Widget _buildTinyCard(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: Colors.red.shade50, child: Icon(icon, color: Colors.white, size: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildNewsRow(Map<String, String> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications, color: Color(0xFFD92344)),
              const SizedBox(width: 10),
              Text(data['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(data['body'] ?? '', style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 8),
          Text(data['date'] ?? '', style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildNotifications(BuildContext context) {
    return const NotificacionView(padding: EdgeInsets.only(top: 16, bottom: 140));
  }

  Widget _buildReports(BuildContext context) {
    final reports = [
      {'name': 'Informe mensual', 'status': 'Listo para descargar'},
      {'name': 'Historial de asistencia', 'status': 'Actualizado hoy'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: reports
            .map(
              (report) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.insert_drive_file, color: Colors.black54),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(report['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(report['status'] ?? '', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black26),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
