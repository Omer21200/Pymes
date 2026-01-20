import 'package:flutter/material.dart';
import '../../service/supabase_service.dart';
import '../../theme.dart';
import 'widgets/notification_card.dart';
import 'widgets/notification_stats.dart';
import 'widgets/attendance_violations_section.dart';

class NotificacionPage extends StatelessWidget {
  const NotificacionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text('Notificaciones'),
        centerTitle: false,
      ),
      body: const NotificacionView(),
    );
  }
}

/// Shared notification layout so the same cards can be embedded elsewhere.
class NotificacionView extends StatefulWidget {
  final EdgeInsetsGeometry padding;

  const NotificacionView({
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
  });

  @override
  State<NotificacionView> createState() => _NotificacionViewState();
}

class _NotificacionViewState extends State<NotificacionView> {
  late Future<List<Map<String, dynamic>>> _noticiasFuture;
  late Future<List<Map<String, dynamic>>> _misAsistenciasFuture;

  @override
  void initState() {
    super.initState();
    _noticiasFuture = _safelyLoadNoticias();
    // Cargar también las últimas acciones de asistencia del usuario (últimas 4)
    _misAsistenciasFuture = _loadMisAsistencias();
  }

  Future<List<Map<String, dynamic>>> _loadMisAsistencias() async {
    try {
      final rows = await SupabaseService.instance.getHistorialAsistencias(
        limite: 20,
      );
      final List<Map<String, dynamic>> events = [];

      String? combineDateTime(String fecha, String hora) {
        try {
          final date = DateTime.parse(fecha);
          final parts = hora.split(':');
          final dt = DateTime(
            date.year,
            date.month,
            date.day,
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
          return dt.toUtc().toIso8601String();
        } catch (_) {
          return null;
        }
      }

      for (final r in rows) {
        final fecha = r['fecha']?.toString() ?? '';
        final horaEntrada = r['hora_entrada']?.toString();
        final horaSalidaAlm = r['hora_salida_almuerzo']?.toString();
        final horaRegresoAlm = r['hora_regreso_almuerzo']?.toString();
        final horaSalida = r['hora_salida']?.toString();

        if (horaEntrada != null) {
          final ts = combineDateTime(fecha, horaEntrada);
          if (ts != null)
            events.add({
              'titulo': 'Entrada',
              'contenido': 'Entrada registrada a las $horaEntrada',
              'fecha_publicacion': ts,
              'es_importante': false,
            });
        }
        if (horaSalidaAlm != null) {
          final ts = combineDateTime(fecha, horaSalidaAlm);
          if (ts != null)
            events.add({
              'titulo': 'Salida a almuerzo',
              'contenido': 'Salida a almuerzo registrada a las $horaSalidaAlm',
              'fecha_publicacion': ts,
              'es_importante': false,
            });
        }
        if (horaRegresoAlm != null) {
          final ts = combineDateTime(fecha, horaRegresoAlm);
          if (ts != null)
            events.add({
              'titulo': 'Regreso de almuerzo',
              'contenido':
                  'Regreso de almuerzo registrado a las $horaRegresoAlm',
              'fecha_publicacion': ts,
              'es_importante': false,
            });
        }
        if (horaSalida != null) {
          final ts = combineDateTime(fecha, horaSalida);
          if (ts != null)
            events.add({
              'titulo': 'Salida',
              'contenido': 'Salida registrada a las $horaSalida',
              'fecha_publicacion': ts,
              'es_importante': false,
            });
        }
      }

      // Ordenar por fecha desc y tomar las últimas 4
      events.sort((a, b) {
        final da = DateTime.parse(a['fecha_publicacion']);
        final db = DateTime.parse(b['fecha_publicacion']);
        return db.compareTo(da);
      });

      return events.take(4).toList();
    } catch (e) {
      // ignore errors; return empty list
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _safelyLoadNoticias() async {
    try {
      // double-guard: service has its own timeout, but add one here too
      final result = await SupabaseService.instance
          .getNoticiasUsuario()
          .timeout(const Duration(seconds: 12));
      return result;
    } catch (e) {
      // Avoid propagating an exception that might cause UI ANR; log and return empty list
      // The FutureBuilder will then show a friendly 'no data' state instead of freezing.
      // Use developer log if needed.
      // ignore: avoid_print
      print('Error loading noticias (safe): $e');
      return <Map<String, dynamic>>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _noticiasFuture,
      builder: (context, snapshot) {
        // Estado: Cargando
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Estado: Error
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
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

        // Preparar datos
        final noticias = snapshot.data ?? [];
        final totalNoticias = noticias.length;
        final noticiasNuevas = noticias
            .where((n) => n['es_importante'] ?? false)
            .length;

        // Estado: Sin datos
        if (noticias.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox,
                    // ignore: deprecated_member_use
                    color: AppColors.mutedGray.withOpacity(0.3),
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay noticias disponibles',
                    style: AppTextStyles.smallLabel.copyWith(
                      color: AppColors.mutedGray,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Estado: Con datos
        return SingleChildScrollView(
          child: Padding(
            padding: widget.padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Estadísticas
                NotificationStats(
                  noticiasNuevas: noticiasNuevas,
                  totalNoticias: totalNoticias,
                ),
                const SizedBox(height: 28),
                // Últimas acciones del usuario (si existen)
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _misAsistenciasFuture,
                  builder: (context, mSnap) {
                    if (mSnap.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    }
                    if (mSnap.hasError) return const SizedBox.shrink();
                    final mis = mSnap.data ?? [];
                    if (mis.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tus últimas acciones',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: mis.length,
                          itemBuilder: (context, idx) {
                            final n = mis[idx];
                            return NotificationCard(
                              titulo: n['titulo'] ?? '',
                              contenido: n['contenido'] ?? '',
                              fechaPublicacion:
                                  n['fecha_publicacion']?.toString() ?? '',
                              esImportante: n['es_importante'] ?? false,
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),

                // Sección de violaciones bajo Reportes
                const SizedBox(height: 8),
                AttendanceViolationsSection(),

                // Título de lista
                const Text(
                  'Historial de notificaciones',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 12),

                // Lista de notificaciones (eficiente y segura en ScrollViews)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: noticias.length,
                  itemBuilder: (context, index) {
                    final notification = noticias[index];
                    final titulo = notification['titulo'] ?? '';
                    final contenido = notification['contenido'] ?? '';
                    final fechaPublicacion =
                        notification['fecha_publicacion']?.toString() ?? '';
                    final esImportante = notification['es_importante'] ?? false;
                    final imagenUrl = notification['imagen_url']?.toString();

                    return NotificationCard(
                      titulo: titulo,
                      contenido: contenido,
                      fechaPublicacion: fechaPublicacion,
                      esImportante: esImportante,
                      imagenUrl: imagenUrl,
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
