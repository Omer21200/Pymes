import 'package:flutter/material.dart';
import '../../../theme.dart';

class EmpleadoQuickAccess extends StatelessWidget {
  final VoidCallback? onRegistrarPressed;
  final VoidCallback? onReportesPressed;

  const EmpleadoQuickAccess({
    super.key,
    this.onRegistrarPressed,
    this.onReportesPressed,
  });

  @override
  Widget build(BuildContext context) {
    final quickAccessItems = [
      {
        'label': 'Registrar',
        'subtitle': 'Marcar asistencia',
        'icon': Icons.access_time,
        'color': const Color(0xFFD92344),
        'action': onRegistrarPressed,
      },
      {
        'label': 'Reportes',
        'subtitle': 'Ver historial',
        'icon': Icons.description,
        'color': const Color(0xFF4A90E2),
        'action': onReportesPressed,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Accesos rápidos',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Colors.black87,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 12),
        ...quickAccessItems.map((item) {
          final color = item['color'] as Color;
          final onTap = item['action'] as VoidCallback?;
          
          return GestureDetector(
            onTap: onTap,
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: AppDecorations.card,
              child: Row(
                children: [
                  // Icono con fondo
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Contenido
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['label'] as String,
                          style: AppTextStyles.sectionTitle.copyWith(fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['subtitle'] as String,
                          style: AppTextStyles.smallLabel,
                        ),
                      ],
                    ),
                  ),
                  
                  // Icono de flecha
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.black26,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
