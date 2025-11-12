import 'package:flutter/material.dart';

class ReportHistoryItem extends StatelessWidget {
  final String initials;
  final String time;
  final String date;
  final String location;
  final bool today;

  const ReportHistoryItem({
    required this.initials,
    required this.time,
    required this.date,
    required this.location,
    this.today = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 20, backgroundColor: const Color(0xFFD92344), child: Text(initials, style: const TextStyle(color: Colors.white))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(time, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Text(date, style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (location.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                        child: Text(location, style: const TextStyle(color: Color(0xFF2B6CB0))),
                      ),
                  ],
                ),
              ),
              if (today)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFFEFFBF0), borderRadius: BorderRadius.circular(12)),
                  child: const Text('Hoy', style: TextStyle(color: Color(0xFF2F855A))),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
