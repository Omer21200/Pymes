import 'package:flutter/material.dart';
import '../../../theme.dart';

class NotificationCard extends StatelessWidget {
  final String titulo;
  final String contenido;
  final String fechaPublicacion;
  final bool esImportante;
  final String? imagenUrl;

  const NotificationCard({
    super.key,
    required this.titulo,
    required this.contenido,
    required this.fechaPublicacion,
    this.esImportante = false,
    this.imagenUrl,
  });

  String _formatearFecha(String fecha) {
    try {
      final date = DateTime.parse(fecha);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return fecha;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = esImportante
        ? AppColors.brandRed
        : AppColors.accentBlue;
    final backgroundColor = AppColors.surface; // white card for clarity
    final borderColor = AppColors.divider;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Banda de acento a la izquierda
          Container(
            width: 4,
            height: 110,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
            ),
          ),

          // Contenido en fila: imagen (opcional) + detalles
          // Imagen o placeholder a la izquierda
          if (imagenUrl != null && imagenUrl!.isNotEmpty)
            SizedBox(
              width: 110,
              height: 110,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
                child: Image.network(
                  imagenUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Container(
                    color: AppColors.surfaceSoft,
                    child: Icon(
                      Icons.image_not_supported,
                      color: AppColors.mutedGray,
                      size: 40,
                    ),
                  ),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: AppColors.surfaceSoft,
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ),
            )
          else
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
              child: Icon(
                Icons.newspaper,
                color: AppColors.mutedGray,
                size: 40,
              ),
            ),

          // Contenido textual que ocupa el espacio restante
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row: icon + title + badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: accentColor.withAlpha((0.12 * 255).round()),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          esImportante
                              ? Icons.priority_high
                              : Icons.notifications_active,
                          color: accentColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          titulo,
                          style: AppTextStyles.sectionTitle.copyWith(
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          esImportante ? 'Importante' : 'Nueva',
                          style: AppTextStyles.smallLabel.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Contenido
                  Text(
                    contenido,
                    style: AppTextStyles.smallLabel.copyWith(
                      fontSize: 13,
                      height: 1.45,
                      color: AppColors.darkText,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Footer con fecha y acción
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: AppColors.mutedGray,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatearFecha(fechaPublicacion),
                        style: AppTextStyles.smallLabel.copyWith(
                          color: AppColors.mutedGray,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            'Leer más',
                            style: AppTextStyles.smallLabel.copyWith(
                              color: accentColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: accentColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
