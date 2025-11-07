import 'package:flutter/material.dart';

class ProfileCard extends StatelessWidget {
  final String userName;
  final String institutionName;
  final String role;
  final VoidCallback? onAction;

  const ProfileCard({
    required this.userName,
    required this.institutionName,
    this.role = 'Empleado',
    this.onAction,
    super.key,
  });

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _initials(userName);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFDC0F1A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(institutionName, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(role, style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onAction,
            icon: const Icon(Icons.login_outlined, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
