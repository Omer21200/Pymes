import 'package:flutter/material.dart';

import '../../../service/supabase_service.dart';
import '../notificacion.dart';
import '../reportes.dart';

class EmpleadoSections extends StatefulWidget {
  final int tabIndex;

  const EmpleadoSections({super.key, required this.tabIndex});

  @override
  State<EmpleadoSections> createState() => _EmpleadoSectionsState();
}

class _EmpleadoSectionsState extends State<EmpleadoSections> {
  late Future<List<Map<String, dynamic>>> _noticiasFuture;

  @override
  void initState() {
    super.initState();
    _noticiasFuture = SupabaseService.instance.getNoticiasUsuario();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.tabIndex) {
      case 0:
        return _buildInicio(context);
      case 1:
        return _buildNotifications(context);
      case 2:
        return _buildReports(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildInicio(BuildContext context) {
    final stats = [
      {'label': 'Días', 'value': '20', 'icon': Icons.calendar_today},
      {'label': 'Asistencia', 'value': '95%', 'icon': Icons.show_chart},
      {'label': 'A tiempo', 'value': '18', 'icon': Icons.thumb_up},
    ];

    final quickAccess = [
      {
        'label': 'Registrar',
        'subtitle': 'Marcar asistencia',
        'icon': Icons.access_time,
      },
      {
        'label': 'Reportes',
        'subtitle': 'Ver historial',
        'icon': Icons.description,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 16, bottom: 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Bienvenido',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tu espacio de empleado',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: stats
                .map(
                  (item) => Expanded(
                    child: _buildTinyCard(
                      item['label'] as String,
                      item['value'] as String,
                      item['icon'] as IconData,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          const Text(
            'Accesos rápidos',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children:
                quickAccess
                    .map(
                      (item) => Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.red.shade50,
                                child: Icon(
                                  item['icon'] as IconData,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                item['label'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['subtitle'] as String,
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList()
                  ..removeLast(),
          ),
          const SizedBox(height: 8),
          ...quickAccess.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    child: Icon(item['icon'] as IconData, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['label'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['subtitle'] as String,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'Noticias y anuncios',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _noticiasFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error al cargar noticias: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              final noticias = snapshot.data ?? [];

              if (noticias.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No hay noticias disponibles',
                    style: TextStyle(color: Colors.black54),
                  ),
                );
              }

              return Column(
                children: noticias
                    .take(3)
                    .map((noticia) => _buildNewsRow(noticia))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 140),
        ],
      ),
    );
  }

  Widget _buildTinyCard(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.red.shade50,
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsRow(Map<String, dynamic> data) {
    final titulo = data['titulo'] ?? '';
    final contenido = data['contenido'] ?? '';
    final fechaPublicacion = data['fecha_publicacion'] ?? '';
    final esImportante = data['es_importante'] ?? false;

    String formatearFecha(String fecha) {
      try {
        final date = DateTime.parse(fecha);
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      } catch (e) {
        return fecha;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: esImportante ? Colors.red.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                esImportante ? Icons.priority_high : Icons.notifications,
                color: esImportante ? Colors.red : const Color(0xFFD92344),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            contenido,
            style: const TextStyle(color: Colors.black54),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            formatearFecha(fechaPublicacion),
            style: TextStyle(
              color: esImportante ? Colors.red : Colors.redAccent,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifications(BuildContext context) {
    return const NotificacionView(
      padding: EdgeInsets.only(top: 16, bottom: 140),
    );
  }

  Widget _buildReports(BuildContext context) {
    return const ReportesPage();
  }
}
