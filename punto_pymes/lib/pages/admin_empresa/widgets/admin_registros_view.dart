import 'package:flutter/material.dart';
import '../../../service/supabase_service.dart';

class AdminRegistrosView extends StatefulWidget {
  const AdminRegistrosView({super.key});

  @override
  State<AdminRegistrosView> createState() => _AdminRegistrosViewState();
}

class _AdminRegistrosViewState extends State<AdminRegistrosView> {
  bool _loading = true;
  int _entradasHoy = 0;
  int _salidasHoy = 0;
  int _tardanzas = 0;
  int _ausencias = 0;
  List<Map<String, dynamic>> _violaciones = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final me = await SupabaseService.instance.getEmpleadoActual();
      final empresaId = me?['empresa_id']?.toString();
      if (empresaId == null) {
        setState(() {
          _loading = false;
        });
        return;
      }

      // Hoy YYYY-MM-DD
      final today = DateTime.now().toIso8601String().split('T').first;

      // Query all asistencias for empresa/today and compute counts in Dart
      final dynamic resp = await SupabaseService.instance.client
          .from('asistencias')
          .select('id, hora_entrada, hora_salida, estado, fecha')
          .eq('empresa_id', empresaId)
          .eq('fecha', today);

      int entradasCnt = 0;
      int salidasCnt = 0;
      int tardanzasCnt = 0;
      int ausenciasCnt = 0;

      List<dynamic> rows = [];
      try {
        rows = List<dynamic>.from(resp ?? []);
      } catch (_) {
        rows = [];
      }

      for (final r in rows) {
        Map<String, dynamic> row;
        try {
          row = Map<String, dynamic>.from(r as Map);
        } catch (_) {
          continue;
        }
        final horaEntrada = row['hora_entrada'];
        final horaSalida = row['hora_salida'];
        final estado = row['estado']?.toString() ?? '';

        if (horaEntrada != null) entradasCnt++;
        if (horaSalida != null) salidasCnt++;
        if (horaEntrada == null) ausenciasCnt++;
        if (estado.toLowerCase().contains('tard') ||
            estado.toLowerCase().contains('tarde')) {
          tardanzasCnt++;
        }
      }

      final viols = await SupabaseService.instance.getViolationsForCompany(
        empresaId,
        limit: 10,
      );

      setState(() {
        _entradasHoy = entradasCnt;
        _salidasHoy = salidasCnt;
        _tardanzas = tardanzasCnt;
        _ausencias = ausenciasCnt;
        _violaciones = viols;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color pink = Colors.pink;
    final Color blue = Colors.blue;
    final Color orange = Colors.orange;
    final Color red = const Color(0xFFD32F2F);

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: ListView(
        padding: const EdgeInsets.all(0),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Text(
              'Registros',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 4, 8, 16),
            child: Text(
              'Revisa la actividad de asistencia y los movimientos recientes de tus empleados.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _RegistroCard(
                label: 'Entradas de Hoy',
                value: _loading ? '...' : '$_entradasHoy',
                icon: Icons.login_rounded,
                color: pink,
              ),
              _RegistroCard(
                label: 'Salidas de Hoy',
                value: _loading ? '...' : '$_salidasHoy',
                icon: Icons.logout_rounded,
                color: blue,
              ),
              _RegistroCard(
                label: 'Marcajes Tarde',
                value: _loading ? '...' : '$_tardanzas',
                icon: Icons.schedule,
                color: orange,
              ),
              _RegistroCard(
                label: 'Ausencias',
                value: _loading ? '...' : '$_ausencias',
                icon: Icons.cancel_schedule_send,
                color: red,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(0, 0, 0, 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Últimas Violaciones',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else if (_violaciones.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Column(
                          children: const [
                            Icon(
                              Icons.check_circle_outline,
                              size: 56,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Sin violaciones recientes',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      children: _violaciones.map((v) {
                        final empleado = v['empleados'];
                        String nombre =
                            v['empleado_id']?.toString() ?? 'Empleado';
                        if (empleado is Map) {
                          final noms = empleado['nombres']?.toString() ?? '';
                          final apes = empleado['apellidos']?.toString() ?? '';
                          final full = [
                            noms,
                            apes,
                          ].where((s) => s.isNotEmpty).join(' ').trim();
                          if (full.isNotEmpty) nombre = full;
                        }
                        final dist =
                            double.tryParse('${v['distance_m'] ?? ''}') ?? 0;
                        final created = v['created_at']?.toString() ?? '';
                        return ListTile(
                          leading: const Icon(
                            Icons.report_problem,
                            color: Colors.red,
                          ),
                          title: Text(
                            '$nombre • ${dist.toStringAsFixed(0)} m fuera',
                          ),
                          subtitle: Text(created),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _RegistroCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _RegistroCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.95), color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
