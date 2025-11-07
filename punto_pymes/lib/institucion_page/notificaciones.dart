import 'package:flutter/material.dart';
import '../widgets/notification_count_card.dart';
import '../widgets/notification_item.dart';

class _NotifItem {
  final String title;
  final String body;
  final String date;
  final bool isNew;
  final IconData icon;

  const _NotifItem({required this.title, required this.body, required this.date, this.isNew = false, this.icon = Icons.info});
}

enum NotificationFilter { nuevas, total }

class NotificacionesContent extends StatefulWidget {
  const NotificacionesContent({super.key});

  @override
  State<NotificacionesContent> createState() => _NotificacionesContentState();
}

class _NotificacionesContentState extends State<NotificacionesContent> {
  NotificationFilter _filter = NotificationFilter.nuevas;

  // Sample data model
  final List<_NotifItem> _items = [
    _NotifItem(title: 'Actualización de horarios', body: 'Se modifican los horarios de entrada a partir del próximo lunes', date: '2025-11-01', isNew: true, icon: Icons.error_outline),
    _NotifItem(title: 'Reunión general', body: 'Reunión general este viernes a las 3PM en el auditorio principal', date: '2025-10-28', isNew: true, icon: Icons.event),
    _NotifItem(title: '¡Felicidades!', body: 'Has completado 30 días consecutivos de puntualidad. Sigue así!', date: '2025-10-01', isNew: false, icon: Icons.emoji_events),
  ];

  @override
  Widget build(BuildContext context) {
    final filterLabel = _filter == NotificationFilter.nuevas ? 'Nuevas' : 'Total';
    return Padding(
      key: ValueKey('notificaciones-$_filter'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('Notificaciones', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFF6F6F6), borderRadius: BorderRadius.circular(12)),
                child: Text(filterLabel, style: const TextStyle(color: Colors.black54)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Mensajes y actualizaciones', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: NotificationCountCard(
                  title: 'Nuevas',
                  count: _items.where((e) => e.isNew).length,
                  selected: _filter == NotificationFilter.nuevas,
                  onTap: () => setState(() => _filter = NotificationFilter.nuevas),
                  borderColor: const Color(0xFFF8D7DA),
                  iconBg: const Color(0xFFFFECEC),
                  icon: Icons.notifications_active,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NotificationCountCard(
                  title: 'Total',
                  count: _items.length,
                  selected: _filter == NotificationFilter.total,
                  onTap: () => setState(() => _filter = NotificationFilter.total),
                  borderColor: Colors.grey.shade200,
                  iconBg: const Color(0xFFF6F6F6),
                  icon: Icons.notifications,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                // Filtrar por _filter
                ..._items.where((e) => _filter == NotificationFilter.total ? true : e.isNew).map((e) => NotificationItem(title: e.title, body: e.body, date: e.date, isNew: e.isNew, icon: e.icon)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

