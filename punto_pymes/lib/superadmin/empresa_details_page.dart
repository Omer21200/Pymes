import 'package:flutter/material.dart';
import '../widgets/company_details_widgets.dart';

class EmpresaDetailsPage extends StatelessWidget {
  final Map<String, dynamic> company;

  const EmpresaDetailsPage({required this.company, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFD92344),
        title: Text(company['name']?.toString() ?? 'Empresa'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CompanyHeader(
              name: company['name'] ?? '',
              logoUrl: company['logo_url'] ?? '',
              codigo: company['codigo_empresa']?.toString() ?? '-',
            ),
            const SizedBox(height: 12),
            InfoSection(
              ruc: company['ruc'] ?? '-',
              telefono: company['telefono'] ?? '-',
              email: company['email'] ?? '-',
              direccion: company['direccion'] ?? '-',
            ),
            const SizedBox(height: 12),
            AttendanceConfigSection(
              horaEntrada: company['hora_entrada'] ?? '-',
              horaSalida: company['hora_salida'] ?? '-',
              horaAlmuerzo: company['hora_almuerzo'] ?? '-',
              horaEntradaAlmuerzo: company['hora_entrada_almuerzo'] ?? '-',
              toleranciaMinutos: (company['tolerancia_minutos'] ?? 0)
                  .toString(),
            ),
            const SizedBox(height: 12),
            StatsSection(
              empleadosRegistrados:
                  company['empleados_registrados']?.toString() ?? '—',
              administradores: company['administradores']?.toString() ?? '—',
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD92344),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
