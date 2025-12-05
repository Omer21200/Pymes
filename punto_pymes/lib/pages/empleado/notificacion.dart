import 'package:flutter/material.dart';
import '../../service/supabase_service.dart';

class NotificacionPage extends StatelessWidget {
  const NotificacionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD92344),
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

  const NotificacionView({super.key, this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0)});

  @override
  State<NotificacionView> createState() => _NotificacionViewState();
}

class _NotificacionViewState extends State<NotificacionView> {
  late Future<List<Map<String, dynamic>>> _noticiasFuture;

  @override
  void initState() {
    super.initState();
    _noticiasFuture = SupabaseService.instance.getNoticiasUsuario();
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final titulo = notification['titulo'] ?? '';
    final contenido = notification['contenido'] ?? '';
    final fechaPublicacion = notification['fecha_publicacion'] ?? '';
    final esImportante = notification['es_importante'] ?? false;

    String formatearFecha(String fecha) {
      try {
        final date = DateTime.parse(fecha);
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      } catch (e) {
        return fecha;
      }
    }

    final themeColor = esImportante ? Colors.redAccent : Colors.blue;
    final backgroundColor = esImportante ? const Color(0xFFFDEFF0) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                esImportante ? Icons.priority_high : Icons.notifications,
                color: themeColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: esImportante ? Colors.redAccent : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  esImportante ? 'Importante' : 'Nueva',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
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
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.schedule, size: 14, color: Colors.black45),
              const SizedBox(width: 6),
              Text(
                formatearFecha(fechaPublicacion),
                style: const TextStyle(color: Colors.black45, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _noticiasFuture,
      builder: (context, snapshot) {
        List<Map<String, dynamic>> noticias = [];
        int totalNoticias = 0;
        int noticiasNuevas = 0;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (snapshot.hasData) {
          noticias = snapshot.data ?? [];
          totalNoticias = noticias.length;
          noticiasNuevas = noticias.where((n) => n['es_importante'] ?? false).length;
        }

        return SingleChildScrollView(
          child: Padding(
            padding: widget.padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mensajes y actualizaciones', style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAD1D1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFEEEEEE)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.add_alert, color: Colors.black45),
                            const SizedBox(height: 12),
                            const Text('Nuevas', style: TextStyle(color: Colors.black54, fontSize: 14)),
                            const SizedBox(height: 8),
                            Text(
                              noticiasNuevas.toString(),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFEEEEEE)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.inbox, color: Colors.black45),
                            const SizedBox(height: 12),
                            const Text('Total', style: TextStyle(color: Colors.black54, fontSize: 14)),
                            const SizedBox(height: 8),
                            Text(
                              totalNoticias.toString(),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (noticias.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'No hay noticias disponibles',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  )
                else
                  ...noticias.map(_buildNotificationCard),
              ],
            ),
          ),
        );
      },
    );
  }
}
