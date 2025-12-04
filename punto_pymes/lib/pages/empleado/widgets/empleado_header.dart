import 'package:flutter/material.dart';

class EmpleadoHeader extends StatelessWidget {
  final String name;
  final String affiliation;
  final VoidCallback? onLogout;

  const EmpleadoHeader({super.key, required this.name, required this.affiliation, this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: const BoxDecoration(
        color: Color(0xFFD92344),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Text(name.split(' ').map((e) => e.isEmpty ? '' : e[0]).take(2).join().toUpperCase(), style: const TextStyle(color: Color(0xFFD92344))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(affiliation, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.exit_to_app, color: Colors.white, size: 24),
            onPressed: onLogout,
          ),
        ],
      ),
    );
  }
}
