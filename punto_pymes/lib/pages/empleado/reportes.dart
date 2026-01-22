import 'package:flutter/material.dart';
import '../../service/supabase_service.dart';
import 'widgets/attendance_card.dart';
import 'widgets/hora_internet_ecuador.dart';

class ReportesPage extends StatefulWidget {
  const ReportesPage({super.key});

  @override
  State<ReportesPage> createState() => _ReportesPageState();
}

class _ReportesPageState extends State<ReportesPage> {
  late Future<List<Map<String, dynamic>>> _asistenciasFuture;

  @override
  void initState() {
    super.initState();
    _loadAsistencias();
  }

  void _loadAsistencias() {
    _asistenciasFuture = SupabaseService.instance
        .getHistorialAsistencias()
        .timeout(
          const Duration(seconds: 12),
          onTimeout: () => <Map<String, dynamic>>[],
        );
  }

  void refreshData() {
    setState(() {
      _loadAsistencias();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 16, bottom: 140, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reloj digital
          const HoraInternetEcuador(),
          const SizedBox(height: 24),
          const Text(
            'Historial de Asistencia',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Registros guardados de tu asistencia',
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _asistenciasFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final asistencias = snapshot.data ?? [];

              if (asistencias.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No hay registros de asistencia',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => refreshData(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: asistencias
                    .map((record) => AttendanceCard(record: record))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
