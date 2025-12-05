import 'package:flutter/material.dart';

class AdminEmpresaNav extends StatefulWidget {
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
    {'icon': Icons.apartment, 'label': 'Departamentos'},
    {'icon': Icons.receipt_long, 'label': 'Registros'},
  ];

  @override
  State<AdminEmpresaNav> createState() => _AdminEmpresaNavState();
}

class _AdminEmpresaNavState extends State<AdminEmpresaNav> {
  final ScrollController _scrollController = ScrollController();
  late final List<GlobalKey> _itemKeys;

  @override
  void initState() {
    super.initState();
    _itemKeys = List.generate(AdminEmpresaNav._tabConfig.length, (_) => GlobalKey());
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToIndex(widget.currentIndex));
  }

  void _onTap(int index) {
    widget.onIndexChanged(index);
    // Allow a short delay for the selected item to expand, then center it.
    Future.delayed(const Duration(milliseconds: 160), () => _scrollToIndex(index));
  }

  void _scrollToIndex(int index) {
    final ctx = _itemKeys[index].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: 0.5,
    );
  }

  Widget _buildItem({required IconData icon, required String label, required int index}) {
    final bool selected = index == widget.currentIndex;
    const primary = Color(0xFFD92344);
    final double itemWidth = selected ? _computeWidthForLabel(label) : 56.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      width: itemWidth,
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
            Flexible(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                overflow: TextOverflow.visible,
                maxLines: 1,
                softWrap: false,
              ),
            ),
          ],
        ],
      ),
    );
  }

  double _computeWidthForLabel(String label) {
    // Base width for icon-only state is 56. For expanded, estimate width by chars.
    final base = 56.0; // icon
    final padding = 24.0; // internal paddings and spacing
    // Estimate ~9px per character (approx). Clamp to reasonable min/max.
    final estimatedLabel = label.length * 9.0;
    final total = base + padding + estimatedLabel;
    return total.clamp(140.0, 300.0);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(AdminEmpresaNav._tabConfig.length, (index) {
                final tab = AdminEmpresaNav._tabConfig[index];
                return Row(
                  children: [
                    KeyedSubtree(
                      key: _itemKeys[index],
                      child: GestureDetector(
                        onTap: () => _onTap(index),
                        child: _buildItem(icon: tab['icon'] as IconData, label: tab['label'] as String, index: index),
                      ),
                    ),
                    if (index != AdminEmpresaNav._tabConfig.length - 1) const SizedBox(width: 8),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
