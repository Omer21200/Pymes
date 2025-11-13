import 'package:flutter/material.dart';

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? bg;

  const MetricCard({required this.title, required this.value, required this.icon, this.bg, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              ]),
            ),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: bg ?? const Color(0xFFFFEAEA), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: const Color(0xFFD92344)),
            ),
          ],
        ),
      ),
    );
  }
}
