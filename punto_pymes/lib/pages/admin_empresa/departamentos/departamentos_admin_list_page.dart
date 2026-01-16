import 'package:flutter/material.dart';
import '../../../service/supabase_service.dart';
import 'creacion_departamentos.dart';
import 'departamento_detalle.dart';

class DepartamentosAdminListPage extends StatefulWidget {
  const DepartamentosAdminListPage({super.key});

  @override
  State<DepartamentosAdminListPage> createState() =>
      _DepartamentosAdminListPageState();
}

class _DepartamentosAdminListPageState
    extends State<DepartamentosAdminListPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _departamentos = [];

  @override
  void initState() {
    super.initState();
    _fetchDepartamentos();
  }

  Future<void> _fetchDepartamentos() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // Obtener empresa id desde el empleado actual
      final empleado = await SupabaseService.instance.getEmpleadoActual();
      if (empleado == null || empleado['empresa_id'] == null) {
        throw Exception('No se pudo identificar la empresa asociada.');
      }
      final empresaId = empleado['empresa_id'].toString();
      final data = await SupabaseService.instance.getDepartamentosPorEmpresa(
        empresaId,
      );
      if (!mounted) return;
      setState(() {
        _departamentos = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error al cargar departamentos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteDepartamento(String departamentoId) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este departamento? Esta acción no se puede deshacer.',
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
        await SupabaseService.instance.deleteDepartamento(departamentoId);
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Departamento eliminado'),
            backgroundColor: Colors.green,
          ),
        );
        await _fetchDepartamentos();
      } catch (e) {
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchDepartamentos,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 0.0),
                    child: Text(
                      'Departamentos',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 16.0),
                    child: Text(
                      'Crea, edita y organiza los departamentos de tu empresa.',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ),
                  Expanded(
                    child: _departamentos.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.business_center,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No hay departamentos creados.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Usa el botón para crear el primero.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _departamentos.length,
                            itemBuilder: (context, index) {
                              final depto = _departamentos[index];
                              final nombre = depto['nombre'] ?? '';
                              final descripcion =
                                  depto['descripcion']?.toString() ?? '';
                              return GestureDetector(
                                onTap: () async {
                                  final result = await Navigator.of(context)
                                      .push<bool>(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              DepartamentoDetallePage(
                                                departamentoId: depto['id'],
                                                departamentoNombre: nombre,
                                              ),
                                        ),
                                      );
                                  if (result == true) {
                                    if (mounted) await _fetchDepartamentos();
                                  }
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    // Fondo y sombra alineados con las tarjetas de noticias
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
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        // Ícono/figura del departamento
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: accentBlue.withValues(
                                              alpha: 0.12,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.grid_view_rounded,
                                            size: 22,
                                            color: accentBlue,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                nombre,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                descripcion.isNotEmpty
                                                    ? descripcion
                                                    : 'Sin descripción',
                                                style: const TextStyle(
                                                  color: Colors.black54,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                          onTap: () =>
                                              _deleteDepartamento(depto['id']),
                                          child: Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: brandRed.withValues(
                                                alpha: 0.08,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.04),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 6),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.delete_outline,
                                              color: brandRed,
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
        heroTag: 'fab_departamentos',
        onPressed: () async {
          // Obtener empresa id para pasar a la pantalla de creación
          final empleado = await SupabaseService.instance.getEmpleadoActual();
          if (!mounted) return;
          final empresaId = empleado?['empresa_id']?.toString();
          if (empresaId == null) {
            final messenger = ScaffoldMessenger.of(context);
            messenger.showSnackBar(
              const SnackBar(
                content: Text('No se encontró la empresa asociada.'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => CreacionDepartamentos(empresaId: empresaId),
            ),
          );
          if (!mounted) return;
          if (result == true) {
            await _fetchDepartamentos();
          }
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Crear Departamento',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }
}
