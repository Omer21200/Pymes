import 'package:flutter/material.dart';

class NotificationItem extends StatelessWidget {
  final String title;
  final String body;
  final String date;
  final bool isNew;
  final IconData? icon;

  const NotificationItem({
    required this.title,
    required this.body,
    required this.date,
    this.isNew = false,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
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
}
