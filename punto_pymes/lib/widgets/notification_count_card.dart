import 'package:flutter/material.dart';

typedef VoidIntCallback = void Function();

class NotificationCountCard extends StatelessWidget {
  final String title;
  final int count;
  final bool selected;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? iconBg;
  final IconData? icon;

  const NotificationCountCard({
    required this.title,
    required this.count,
    this.selected = false,
    this.onTap,
    this.borderColor,
    this.iconBg,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
            Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: selected ? const Color(0xFFD92344) : Colors.black)),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }
}
