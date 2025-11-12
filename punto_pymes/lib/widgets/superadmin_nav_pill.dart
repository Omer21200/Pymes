import 'package:flutter/material.dart';

typedef OnSelectIndex = void Function(int index);

class SuperAdminNavPill extends StatelessWidget {
  final int selectedIndex;
  final OnSelectIndex onSelect;
  const SuperAdminNavPill({
    required this.selectedIndex,
    required this.onSelect,
    super.key, required Null Function() onFloating,
  });

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label) {
    const unselectedColor = Color(0xFF333333);
    final selected = selectedIndex == index;
    if (selected) {
      return GestureDetector(
        onTap: () => onSelect(index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFD92344),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: const Color(0xFFD92344).withOpacity(0.18), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => onSelect(index),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: unselectedColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          // Main pill (expanded)
          Expanded(
            child: Container(
              height: 66,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 6))],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildNavItem(context, 0, Icons.home, 'Resumen'),
                  const SizedBox(width: 8),
                  _buildNavItem(context, 1, Icons.apartment, 'Empresas'),
                  const SizedBox(width: 8),
                  _buildNavItem(context, 2, Icons.group, 'Admins'),
                  const Spacer(),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
