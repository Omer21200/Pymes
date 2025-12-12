import 'package:flutter/material.dart';

class EmpleadoNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const EmpleadoNav({super.key, required this.currentIndex, required this.onTabSelected});

  static const _tabs = [
    {'icon': Icons.home, 'label': 'Inicio'},
    {'icon': Icons.notifications, 'label': 'Notificaciones'},
    {'icon': Icons.description, 'label': 'Reportes'},
  ];

  @override
  State<EmpleadoNav> createState() => _EmpleadoNavState();
}

class _EmpleadoNavState extends State<EmpleadoNav> {
  final ScrollController _scrollController = ScrollController();
  late final List<GlobalKey> _keys;

  @override
  void initState() {
    super.initState();
    _keys = List.generate(EmpleadoNav._tabs.length, (_) => GlobalKey());
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToIndex(widget.currentIndex));
  }

  @override
  void didUpdateWidget(covariant EmpleadoNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      // center new index
      Future.delayed(const Duration(milliseconds: 160), () => _scrollToIndex(widget.currentIndex));
    }
  }

  void _onTap(int index) {
    widget.onTabSelected(index);
    Future.delayed(const Duration(milliseconds: 160), () => _scrollToIndex(index));
  }

  void _scrollToIndex(int index) {
    final ctx = _keys[index].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut, alignment: 0.5);
  }

  double _computeWidthForLabel(String label, bool selected) {
    if (!selected) return 60.0;
    final base = 60.0;
    final padding = 20.0;
    final estimated = label.length * 9.0;
    final total = base + padding + estimated;
    return total.clamp(112.0, 220.0);
  }

  Widget _buildItem(IconData icon, String label, int index) {
    final bool selected = index == widget.currentIndex;
    const primary = Color(0xFFD92344);

    final width = _computeWidthForLabel(label, selected);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      width: width,
      height: 52,
      padding: EdgeInsets.symmetric(horizontal: selected ? 12 : 0),
      decoration: BoxDecoration(
        color: selected ? primary : Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          if (!selected) const BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: selected ? Colors.white : Colors.black54, size: 20),
          if (selected) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int index = 0; index < EmpleadoNav._tabs.length; index++) ...[
                KeyedSubtree(
                  key: _keys[index],
                  child: GestureDetector(
                    onTap: () => _onTap(index),
                    child: _buildItem(EmpleadoNav._tabs[index]['icon'] as IconData, EmpleadoNav._tabs[index]['label'] as String, index),
                  ),
                ),
                if (index != EmpleadoNav._tabs.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}