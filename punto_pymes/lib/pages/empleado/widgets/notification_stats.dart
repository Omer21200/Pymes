import 'package:flutter/material.dart';
import '../../../theme.dart';

class NotificationStats extends StatelessWidget {
  final int noticiasNuevas;
  final int totalNoticias;

  const NotificationStats({
    super.key,
    required this.noticiasNuevas,
    required this.totalNoticias,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado
        Text(
          'Resumen',
          style: AppTextStyles.sectionTitle.copyWith(fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 14),

        // Grid de estadísticas
        Row(
          children: [
            // Estadística de Nuevas
            Expanded(
              child: _StatCard(
                icon: Icons.priority_high,
                iconColor: AppColors.brandRedAlt,
                  backgroundColor: AppColors.notificationBg,
                label: 'Nuevas',
                value: noticiasNuevas,
              ),
            ),
            const SizedBox(width: 12),
            
            // Estadística de Total
            Expanded(
              child: _StatCard(
                icon: Icons.inbox,
                iconColor: AppColors.mutedGray,
                  backgroundColor: AppColors.subtleBg,
                label: 'Total',
                value: totalNoticias,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String label;
  final int value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: AppDecorations.statCardDecoration(iconColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono top-right
          Align(
            alignment: Alignment.topRight,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.16),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(height: 18),

          // Label
          Text(
            label,
            style: AppTextStyles.smallLabel.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 6),

          // Valor
          Text(
            value.toString(),
            style: AppTextStyles.statsValue.copyWith(fontSize: 32, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
