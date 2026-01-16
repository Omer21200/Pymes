import 'package:flutter/material.dart';

class NotificationCard extends StatelessWidget {
  final String titulo;
  final String contenido;
  final String fechaPublicacion;
  final bool esImportante;

  const NotificationCard({
    super.key,
    required this.titulo,
    required this.contenido,
    required this.fechaPublicacion,
    this.esImportante = false,
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
        ? const Color(0xFFD92344)
        : const Color(0xFF4A90E2);
    final backgroundColor = esImportante
        ? const Color(0xFFFDEFF0)
        : const Color(0xFFF8F9FB);
    final borderColor = esImportante
        ? const Color(0xFFFFD6E0)
        : const Color(0xFFE0E7FF);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: accentColor.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Barra de color izquierda
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),
          ),

          // Contenido
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado con título y badge
                Row(
                  children: [
                    // Icono
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        // ignore: deprecated_member_use
                        color: accentColor.withOpacity(0.1),
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

                    // Título
                    Expanded(
                      child: Text(
                        titulo,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Colors.black87,
                          letterSpacing: 0.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Contenido
                Text(
                  contenido,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

                // Footer con fecha y badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Fecha
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 13, color: Colors.black38),
                        const SizedBox(width: 6),
                        Text(
                          _formatearFecha(fechaPublicacion),
                          style: const TextStyle(
                            color: Colors.black38,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        esImportante ? 'Importante' : 'Nueva',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
