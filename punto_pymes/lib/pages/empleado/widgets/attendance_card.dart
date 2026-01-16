import 'package:flutter/material.dart';

class AttendanceCard extends StatelessWidget {
  final Map<String, dynamic> record;

  const AttendanceCard({super.key, required this.record});

  String _formatearFecha(String fecha) {
    try {
      final date = DateTime.parse(fecha);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return fecha;
    }
  }

  String _formatearHora(String? hora) {
    if (hora == null) return '--:--';
    try {
      // Si viene en formato HH:mm:ss, tomar solo HH:mm
      if (hora.contains(':')) {
        return hora.substring(0, 5);
      }
      return hora;
    } catch (e) {
      return hora;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fecha = record['fecha'] ?? '';
    final horaEntrada = _formatearHora(record['hora_entrada']);
    final horaSalida = _formatearHora(record['hora_salida']);
    final fotoUrl = record['foto_url'] as String?;
    final estado = record['estado'] ?? 'pendiente';

    final tieneEntrada = record['hora_entrada'] != null;
    final tieneSalida = record['hora_salida'] != null;

    final statusColor = tieneSalida
        ? Colors.green
        : tieneEntrada
        ? Colors.orange
        : Colors.grey;

    final statusText = tieneSalida
        ? 'Completo'
        : tieneEntrada
        ? 'Entrada'
        : 'Sin registro';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        // ignore: deprecated_member_use
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatearFecha(fecha),
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Entrada',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            horaEntrada,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Salida',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            horaSalida,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (estado != 'pendiente') ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        'Estado: ${estado.substring(0, 1).toUpperCase()}${estado.substring(1)}',
                        style: TextStyle(color: statusColor, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: statusColor, width: 2),
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: statusColor.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              backgroundColor: Colors.grey.shade300,
              backgroundImage: fotoUrl != null ? NetworkImage(fotoUrl) : null,
              child: fotoUrl == null
                  ? Icon(Icons.person, color: Colors.grey.shade600, size: 40)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
