import 'package:flutter/material.dart';

class EmpleadoNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback? onRegister;

  const EmpleadoNav({super.key, required this.currentIndex, required this.onTabSelected, this.onRegister});

  static const _tabs = [
    {'icon': Icons.home, 'label': 'Inicio'},
    {'icon': Icons.notifications, 'label': 'Notificaciones'},
    {'icon': Icons.description, 'label': 'Reportes'},
  ];

  Widget _buildItem(IconData icon, String label, int index) {
    final bool selected = index == currentIndex;
    const primary = Color(0xFFD92344);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      width: selected ? 140 : 56,
      height: 56,
      padding: EdgeInsets.symmetric(horizontal: selected ? 12 : 0),
      decoration: BoxDecoration(
        color: selected ? primary : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          if (!selected) const BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: selected ? Colors.white : Colors.black54, size: 20),
          if (selected) ...[
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 6))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int index = 0; index < _tabs.length; index++) ...[
              GestureDetector(
                onTap: () => onTabSelected(index),
                child: _buildItem(_tabs[index]['icon'] as IconData, _tabs[index]['label'] as String, index),
              ),
              if (index != _tabs.length - 1) const SizedBox(width: 8),
            ],
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onRegister,
              child: Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFD92344),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 6))],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
