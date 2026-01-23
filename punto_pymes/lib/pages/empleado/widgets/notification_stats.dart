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
          style: AppTextStyles.sectionTitle.copyWith(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),

        // Row compacto de estadísticas
        Row(
          children: [
            // Estadística de Nuevas (compacta)
            Expanded(
              child: _CompactStatCard(
                icon: Icons.priority_high,
                iconColor: AppColors.brandRedAlt,
                label: 'Nuevas',
                value: noticiasNuevas,
              ),
            ),
            const SizedBox(width: 10),

            // Estadística de Total (compacta)
            Expanded(
              child: _CompactStatCard(
                icon: Icons.inbox,
                iconColor: AppColors.mutedGray,
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

class _CompactStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final int value;

  const _CompactStatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [iconColor.withOpacity(0.9), iconColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icono a la izquierda
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),

          // Texto
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.smallLabel.copyWith(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.toString(),
                  style: AppTextStyles.statsValue.copyWith(
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
