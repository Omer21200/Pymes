import 'package:flutter/material.dart';

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

  Widget _buildCountCard(String title, int count, NotificationFilter cardFilter, {Color? borderColor, Color? iconBg, IconData? icon}) {
    final selected = _filter == cardFilter;
    return GestureDetector(
      onTap: () => setState(() => _filter = cardFilter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF5F6) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? const Color(0xFFFFD6D9) : (borderColor ?? Colors.grey.shade200), width: selected ? 1.2 : 1.0),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: iconBg ?? const Color(0xFFFDEAEA), child: Icon(icon ?? Icons.notifications, color: const Color(0xFFD92344))),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: selected ? const Color(0xFFD92344) : Colors.black)),
              ],
            ),
            const SizedBox(height: 8),
            // number aligned left, bigger
            Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: selected ? const Color(0xFFD92344) : Colors.black)),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(String title, String body, String date, {bool isNew = false, IconData? icon}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isNew ? const Color(0xFFFFF1F1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isNew ? const Color(0xFFFFE6E6) : Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(backgroundColor: isNew ? const Color(0xFFFFECEC) : const Color(0xFFF6F6F6), child: Icon(icon ?? Icons.info, color: const Color(0xFFD92344))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600))),
                    if (isNew)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFD92344), borderRadius: BorderRadius.circular(12)),
                        child: const Text('Nueva', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(body, style: const TextStyle(color: Colors.black87)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

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
              Expanded(child: _buildCountCard('Nuevas', _items.where((e) => e.isNew).length, NotificationFilter.nuevas, borderColor: const Color(0xFFF8D7DA), iconBg: const Color(0xFFFFECEC), icon: Icons.notifications_active)),
              const SizedBox(width: 12),
              Expanded(child: _buildCountCard('Total', _items.length, NotificationFilter.total, borderColor: Colors.grey.shade200, iconBg: const Color(0xFFF6F6F6), icon: Icons.notifications)),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                // Filtrar por _filter
                ..._items.where((e) => _filter == NotificationFilter.total ? true : e.isNew).map((e) => _buildNotificationItem(e.title, e.body, e.date, isNew: e.isNew, icon: e.icon)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

