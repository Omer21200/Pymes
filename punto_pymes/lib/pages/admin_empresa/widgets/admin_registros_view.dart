import 'package:flutter/material.dart';
import '../../../service/supabase_service.dart';

class AdminRegistrosView extends StatefulWidget {
  const AdminRegistrosView({super.key});

  @override
  State<AdminRegistrosView> createState() => _AdminRegistrosViewState();
}

class _AdminRegistrosViewState extends State<AdminRegistrosView> {
  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<Map<String, dynamic>> _loadData() async {
    try {
      final registros = await SupabaseService.instance.getUltimosRegistros();

      int entradas = 0;
      int salidas = 0;
      int tardanzas = 0;
      int ausencias = 0;

      for (final reg in registros) {
        final estado = reg['estado']?.toString().toLowerCase() ?? '';
        if (estado == 'presente') {
          entradas++;
          if (reg['hora_entrada_tarde'] == true) tardanzas++;
        } else if (estado == 'salida') {
          salidas++;
        } else if (estado == 'ausente') {
          ausencias++;
        }
      }

      return {
        'entradas': entradas,
        'salidas': salidas,
        'tardanzas': tardanzas,
        'ausencias': ausencias,
        'registros': registros,
      };
    } catch (e) {
      print('Error cargando datos: $e');
      return {
        'entradas': 0,
        'salidas': 0,
        'tardanzas': 0,
        'ausencias': 0,
        'registros': <Map<String, dynamic>>[],
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color pink = Colors.pink;
    const Color blue = Colors.blue;
    const Color orange = Colors.orange;
    const Color red = Color(0xFFD32F2F);

    return FutureBuilder<Map<String, dynamic>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        final data = snapshot.data ?? {};
        final entradas = data['entradas'] as int? ?? 0;
        final salidas = data['salidas'] as int? ?? 0;
        final tardanzas = data['tardanzas'] as int? ?? 0;
        final ausencias = data['ausencias'] as int? ?? 0;
        final registros = (data['registros'] as List? ?? [])
            .cast<Map<String, dynamic>>();

        return ListView(
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
                  value: entradas.toString(),
                  icon: Icons.login_rounded,
                  color: pink,
                ),
                _RegistroCard(
                  label: 'Salidas de Hoy',
                  value: salidas.toString(),
                  icon: Icons.logout_rounded,
                  color: blue,
                ),
                _RegistroCard(
                  label: 'Marcajes Tarde',
                  value: tardanzas.toString(),
                  icon: Icons.schedule,
                  color: orange,
                ),
                _RegistroCard(
                  label: 'Ausencias',
                  value: ausencias.toString(),
                  icon: Icons.cancel_schedule_send,
                  color: red,
                ),
              ],
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: registros.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.pending_actions_outlined,
                            size: 72,
                            color: Color(0xFFD32F2F),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Sin registros hoy',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No hay asistencias registradas aún.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF757575),
                              height: 1.4,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Últimos Registros',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...registros.take(5).map((reg) {
                            final nombre =
                                '${reg['nombres'] ?? ''} ${reg['apellidos'] ?? ''}'
                                    .trim();
                            final estado = reg['estado'] ?? 'desconocido';
                            final horaEntrada = reg['hora_entrada'] ?? '—';
                            final horaSalida = reg['hora_salida'] ?? '—';

                            Color stateColor = Colors.blue;
                            IconData stateIcon = Icons.info;
                            if (estado.toString().toLowerCase() == 'presente') {
                              stateColor = Colors.green;
                              stateIcon = Icons.check_circle;
                            } else if (estado.toString().toLowerCase() ==
                                'ausente') {
                              stateColor = Colors.red;
                              stateIcon = Icons.cancel;
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: stateColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: stateColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(stateIcon, color: stateColor, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          nombre.isNotEmpty
                                              ? nombre
                                              : 'Sin nombre',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Entrada: $horaEntrada | Salida: $horaSalida',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
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
