import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../service/supabase_service.dart';
import 'creacion_noticia_page.dart';

class NoticiasAdminListPage extends StatefulWidget {
  const NoticiasAdminListPage({super.key});

  @override
  State<NoticiasAdminListPage> createState() => _NoticiasAdminListPageState();
}

class _NoticiasAdminListPageState extends State<NoticiasAdminListPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _noticias = [];

  @override
  void initState() {
    super.initState();
    _fetchNoticias();
  }

  Future<void> _fetchNoticias() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final data = await SupabaseService.instance.getNoticiasAdmin();
      if (!mounted) return;
      setState(() {
        _noticias = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar noticias: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }
  
  Future<void> _deleteNoticia(String noticiaId) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text('¿Estás seguro de que quieres eliminar esta noticia? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseService.instance.deleteNoticia(noticiaId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Noticia eliminada'), backgroundColor: Colors.green));
        _fetchNoticias(); // Refresh the list
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar: ${e.toString()}'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchNoticias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 16.0),
                    child: Text(
                      'Anuncios y Notificaciones',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                  Expanded(
                    child: _noticias.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.newspaper, size: 60, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('No hay noticias creadas.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                                SizedBox(height: 8),
                                Text('Usa el botón para crear la primera.', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _noticias.length,
                            itemBuilder: (context, index) {
                              final noticia = _noticias[index];
                              final fecha = DateFormat('dd/MM/yyyy', 'es_ES').format(DateTime.parse(noticia['fecha_publicacion']));
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  title: Text(noticia['titulo'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('Publicado: $fecha'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _deleteNoticia(noticia['id']!),
                                  ),
                                  onTap: () async {
                                     final result = await Navigator.of(context).push<bool>(
                                      MaterialPageRoute(
                                        builder: (_) => CreacionNoticiaPage(noticia: noticia),
                                      ),
                                    );
                                    if (result == true) {
                                      _fetchNoticias();
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => const CreacionNoticiaPage(),
            ),
          );
          // Si la página de creación devuelve 'true', refrescamos la lista
          if (result == true) {
            _fetchNoticias();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Crear Noticia'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }
}
