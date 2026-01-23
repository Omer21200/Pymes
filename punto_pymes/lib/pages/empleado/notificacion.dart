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

  @override
  void initState() {
    super.initState();
    _noticiasFuture = _safelyLoadNoticias();
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

        // Siempre mostrar el layout principal. Si no hay noticias,
        // mostraremos una sección de 'No hay noticias' más abajo en el listado,
        // pero mantendremos visibles las secciones útiles como violaciones.
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
                // (Se eliminó la sección "Tus últimas acciones" por solicitud)

                // Sección de violaciones bajo Reportes
                const SizedBox(height: 8),
                const AttendanceViolationsSection(),

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
                Builder(
                  builder: (ctx) {
                    if (noticias.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(
                          child: Text(
                            'No hay noticias disponibles',
                            style: AppTextStyles.smallLabel.copyWith(
                              color: AppColors.mutedGray,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: noticias.length,
                      itemBuilder: (context, index) {
                        final notification = noticias[index];
                        final titulo = notification['titulo'] ?? '';
                        final contenido = notification['contenido'] ?? '';
                        final fechaPublicacion =
                            notification['fecha_publicacion']?.toString() ?? '';
                        final esImportante =
                            notification['es_importante'] ?? false;
                        final imagenUrl = notification['imagen_url']
                            ?.toString();

                        return NotificationCard(
                          titulo: titulo,
                          contenido: contenido,
                          fechaPublicacion: fechaPublicacion,
                          esImportante: esImportante,
                          imagenUrl: imagenUrl,
                        );
                      },
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
