import 'package:flutter/material.dart';

class SuperadminBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const SuperadminBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  Widget _buildItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool selected = index == currentIndex;
    final primary = const Color(0xFFD92344);

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
          if (!selected)
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: selected ? Colors.white : Colors.black54),
          if (selected) ...[
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.transparent,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => onTap(0),
                child: _buildItem(icon: Icons.home, label: 'Resumen', index: 0),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => onTap(1),
                child: _buildItem(
                  icon: Icons.apartment,
                  label: 'Empresas',
                  index: 1,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => onTap(2),
                child: _buildItem(icon: Icons.group, label: 'Admins', index: 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
