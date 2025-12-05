import 'package:flutter/material.dart';

class AdminEmpresaNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;

  const AdminEmpresaNav({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
  });

  static const _tabConfig = [
    {'icon': Icons.home, 'label': 'Inicio'},
    {'icon': Icons.campaign, 'label': 'Noticias'},
    {'icon': Icons.receipt_long, 'label': 'Registros'},
  ];

  Widget _buildItem({required IconData icon, required String label, required int index}) {
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
          Icon(icon, color: selected ? Colors.white : Colors.black54),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.transparent,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 6))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_tabConfig.length, (index) {
              final tab = _tabConfig[index];
              return Row(
                children: [
                  GestureDetector(
                    onTap: () => onIndexChanged(index),
                    child: _buildItem(icon: tab['icon'] as IconData, label: tab['label'] as String, index: index),
                  ),
                  if (index != _tabConfig.length - 1) const SizedBox(width: 8),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
