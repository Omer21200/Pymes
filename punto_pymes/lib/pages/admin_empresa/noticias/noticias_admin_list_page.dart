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
  List<bool> _noticiasActivas = [];

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
        _noticiasActivas = data
            .map((e) => (e['activo'] ?? false) as bool)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar noticias: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleActivo(int index) async {
    if (index < 0 || index >= _noticiasActivas.length) return;
    setState(() {
      _noticiasActivas[index] = !_noticiasActivas[index];
    });
    // Si quieres persistir este cambio en el backend, descomenta y adapta la llamada:
    // final id = _noticias[index]['id'];
    // await SupabaseService.instance.setNoticiaActivo(id, _noticiasActivas[index]);
  }

  Future<void> _deleteNoticia(String noticiaId) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar esta noticia? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Noticia eliminada'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchNoticias(); // Refresh the list
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color brandRed = Color(0xFFE2183D);
    const Color accentBlue = Color(0xFF3F51B5);
    const Color successGreen = Color(0xFF4CAF50);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchNoticias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Anuncios y Notificaciones',
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Crea y gestiona las notificaciones que recibirán tus empleados.',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _noticias.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.newspaper,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No hay noticias creadas.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Usa el botón para crear la primera.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _noticias.length,
                            itemBuilder: (context, index) {
                              final noticia = _noticias[index];
                              final fecha = DateFormat('dd/MM/yyyy', 'es_ES')
                                  .format(
                                    DateTime.parse(
                                      noticia['fecha_publicacion'],
                                    ),
                                  );
                              final bool esImportante =
                                  noticia['es_importante'] ?? false;
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color.fromARGB(
                                        255,
                                        0,
                                        0,
                                        0,
                                      ).withValues(alpha: 0.08),
                                      blurRadius: 12,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: const Color.fromARGB(0, 101, 6, 6),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () async {
                                      final result = await Navigator.of(context)
                                          .push<bool>(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  CreacionNoticiaPage(
                                                    noticia: noticia,
                                                  ),
                                            ),
                                          );
                                      if (result == true) _fetchNoticias();
                                    },
                                    child: Row(
                                      children: [
                                        // Accent bar
                                        Container(
                                          width: 8,
                                          height: 86,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                const BorderRadius.only(
                                                  topLeft: Radius.circular(22),
                                                  bottomLeft: Radius.circular(
                                                    22,
                                                  ),
                                                ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 12,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    GestureDetector(
                                                      onTap: () =>
                                                          _toggleActivo(index),
                                                      child: Container(
                                                        width: 22,
                                                        height: 22,
                                                        decoration: BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color:
                                                              (_noticiasActivas
                                                                          .length >
                                                                      index &&
                                                                  _noticiasActivas[index])
                                                              ? successGreen
                                                              : Colors
                                                                    .transparent,
                                                          border: Border.all(
                                                            color:
                                                                (_noticiasActivas
                                                                            .length >
                                                                        index &&
                                                                    _noticiasActivas[index])
                                                                ? successGreen
                                                                : Colors
                                                                      .grey
                                                                      .shade400,
                                                            width: 1.4,
                                                          ),
                                                        ),
                                                        child:
                                                            (_noticiasActivas
                                                                        .length >
                                                                    index &&
                                                                _noticiasActivas[index])
                                                            ? const Icon(
                                                                Icons.check,
                                                                size: 14,
                                                                color: Colors
                                                                    .white,
                                                              )
                                                            : null,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Text(
                                                        noticia['titulo'] ?? '',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          fontSize: 16,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                if (esImportante)
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: successGreen
                                                          .withValues(
                                                            alpha: 0.12,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.push_pin,
                                                          size: 14,
                                                          color: successGreen,
                                                        ),
                                                        const SizedBox(
                                                          width: 6,
                                                        ),
                                                        Text(
                                                          'Importante',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: successGreen,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                if (esImportante)
                                                  const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .calendar_today_rounded,
                                                      size: 16,
                                                      color: accentBlue,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Publicado: $fecha',
                                                      style: TextStyle(
                                                        color: accentBlue,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        // Delete button
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8.0,
                                          ),
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                            onTap: () =>
                                                _deleteNoticia(noticia['id']!),
                                            child: Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: brandRed.withValues(
                                                  alpha: 0.08,
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.delete_outline,
                                                color: brandRed,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_noticias',
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const CreacionNoticiaPage()),
          );
          // Si la página de creación devuelve 'true', refrescamos la lista
          if (result == true) {
            _fetchNoticias();
          }
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Crear Noticia',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }
}
