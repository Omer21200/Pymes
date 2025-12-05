import 'package:flutter/material.dart';
import '../../../service/supabase_service.dart';
import 'creacion_departamentos.dart';
import 'departamento_detalle.dart';

class DepartamentosAdminListPage extends StatefulWidget {
  const DepartamentosAdminListPage({super.key});

  @override
  State<DepartamentosAdminListPage> createState() => _DepartamentosAdminListPageState();
}

class _DepartamentosAdminListPageState extends State<DepartamentosAdminListPage> {
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
      final data = await SupabaseService.instance.getDepartamentosPorEmpresa(empresaId);
      if (!mounted) return;
      setState(() {
        _departamentos = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar departamentos: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _deleteDepartamento(String departamentoId) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text('¿Estás seguro de que deseas eliminar este departamento? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseService.instance.deleteDepartamento(departamentoId);
        if (!mounted) return;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Departamento eliminado'), backgroundColor: Colors.green));
        }
        await _fetchDepartamentos();
      } catch (e) {
        if (!mounted) return;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.red));
        }
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
              onRefresh: _fetchDepartamentos,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 16.0),
                    child: Text(
                      'Departamentos',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                  Expanded(
                    child: _departamentos.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.business_center, size: 60, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('No hay departamentos creados.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                                SizedBox(height: 8),
                                Text('Usa el botón para crear el primero.', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _departamentos.length,
                            itemBuilder: (context, index) {
                              final depto = _departamentos[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  title: Text(depto['nombre'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: depto['descripcion'] != null ? Text(depto['descripcion']) : null,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.schedule),
                                        tooltip: 'Horario',
                                        onPressed: () async {
                                          final result = await Navigator.of(context).push<bool>(
                                            MaterialPageRoute(
                                              builder: (_) => DepartamentoDetallePage(
                                                departamentoId: depto['id'],
                                                departamentoNombre: depto['nombre'] ?? 'Departamento',
                                              ),
                                            ),
                                          );
                                            if (result == true) {
                                              if (mounted) await _fetchDepartamentos();
                                            }
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: () => _deleteDepartamento(depto['id']),
                                      ),
                                    ],
                                  ),
                                  onTap: () async {
                                    final result = await Navigator.of(context).push<bool>(
                                      MaterialPageRoute(
                                        builder: (_) => DepartamentoDetallePage(
                                          departamentoId: depto['id'],
                                          departamentoNombre: depto['nombre'] ?? 'Departamento',
                                        ),
                                      ),
                                    );
                                    if (result == true) {
                                      if (mounted) await _fetchDepartamentos();
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
        heroTag: 'fab_departamentos',
        onPressed: () async {
          // Obtener empresa id para pasar a la pantalla de creación
          final empleado = await SupabaseService.instance.getEmpleadoActual();
          final empresaId = empleado?['empresa_id']?.toString();
          if (empresaId == null) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se encontró la empresa asociada.'), backgroundColor: Colors.red));
            return;
          }

          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => CreacionDepartamentos(empresaId: empresaId)),
          );
          if (result == true) {
            if (mounted) await _fetchDepartamentos();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Crear Departamento'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }
}
