import 'package:flutter/material.dart';

class NewsSection extends StatelessWidget {
  final VoidCallback? onViewAll;

  const NewsSection({
    this.onViewAll,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Noticias y Anuncios', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            TextButton(onPressed: onViewAll, child: const Text('Ver todas >', style: TextStyle(color: Color(0xFFD92344))))
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 4))],
            border: Border(left: BorderSide(color: const Color(0xFFD92344), width: 4)),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.notification_important, color: Color(0xFFD92344)),
                  SizedBox(width: 8),
                  Expanded(child: Text('Actualización de horarios', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Se modifican los horarios de entrada a partir del próximo lunes', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              const Text('2025-11-01', style: TextStyle(color: Color(0xFFD92344), fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}
