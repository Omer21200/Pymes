import 'package:flutter/material.dart';

class ReportSummary extends StatelessWidget {
  final int asistencias;
  final int inasistencias;
  final double puntualidad; // 0..100
  final int diasTrabajados;
  final String promedioEntrada;

  const ReportSummary({
    this.asistencias = 20,
    this.inasistencias = 1,
    this.puntualidad = 95.0,
    this.diasTrabajados = 20,
    this.promedioEntrada = '8:42 AM',
    super.key,
  });

  Widget _bigCard(Color bg, String title, String value, String subtitle) {
    return Container(
      height: 110,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _bigCard(const Color(0xFF00B569), 'Asistencias', '$asistencias', 'Este mes')),
            const SizedBox(width: 12),
            Expanded(child: _bigCard(const Color(0xFFD92344), 'Inasistencias', '$inasistencias', 'Este mes')),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 4))],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.show_chart, color: Color(0xFF2B6CB0)),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Rendimiento', style: TextStyle(fontWeight: FontWeight.w600))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFEFFBF0), borderRadius: BorderRadius.circular(12)),
                    child: const Text('Excelente', style: TextStyle(color: Color(0xFF2F855A), fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Puntualidad', style: TextStyle(color: Colors.black54)),
                        const SizedBox(height: 6),
                        Stack(
                          children: [
                            Container(height: 8, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6))),
                            Container(height: 8, width: MediaQuery.of(context).size.width * (puntualidad / 100) * 0.6, decoration: BoxDecoration(color: const Color(0xFF2ECC71), borderRadius: BorderRadius.circular(6))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text('${puntualidad.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Días trabajados', style: TextStyle(color: Colors.black54, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('$diasTrabajados días', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Promedio entrada', style: TextStyle(color: Colors.black54, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(promedioEntrada, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }
}
