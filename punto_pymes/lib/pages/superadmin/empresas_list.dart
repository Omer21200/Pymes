import 'package:flutter/material.dart';
import 'widgets/company_tile.dart';
import 'widgets/superadmin_header.dart';
import '../../theme.dart';
import 'empresa_detalle.dart';
import 'creacionempresas.dart';
import '../../service/supabase_service.dart';

class EmpresasList extends StatefulWidget {
  const EmpresasList({super.key});

  @override
  State<EmpresasList> createState() => _EmpresasListState();
}

class _EmpresasListState extends State<EmpresasList> {
  List<Map<String, dynamic>> _empresas = [];
  bool _isLoading = true;
  // Filters
  final TextEditingController _filterNameController = TextEditingController();
  DateTime? _filterFrom;
  DateTime? _filterTo;
  List<Map<String, dynamic>> _filteredEmpresas = [];

  @override
  void initState() {
    super.initState();
    _loadEmpresas();
  }

  @override
  void dispose() {
    _filterNameController.dispose();
    super.dispose();
  }

  Future<void> _loadEmpresas() async {
    setState(() => _isLoading = true);
    try {
      final empresas = await SupabaseService.instance.getEmpresas();
      setState(() {
        _empresas = empresas;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar empresas: $e')));
      }
    }
  }

  void _applyFilters() {
    final nameQ = _filterNameController.text.trim().toLowerCase();
    DateTime? from = _filterFrom;
    DateTime? to = _filterTo;

    List<Map<String, dynamic>> list = List.from(_empresas);

    if (nameQ.isNotEmpty) {
      list = list.where((e) {
        final n = (e['nombre'] ?? '').toString().toLowerCase();
        return n.contains(nameQ);
      }).toList();
    }

    if (from != null || to != null) {
      list = list.where((e) {
        final created = e['created_at'];
        DateTime? dt;
        if (created is String) {
          dt = DateTime.tryParse(created);
        } else if (created is DateTime) {
          dt = created;
        }
        if (dt == null) return false;
        if (from != null && dt.isBefore(from)) return false;
        if (to != null) {
          // include whole day for 'to' by setting to end of day
          final end = DateTime(to.year, to.month, to.day, 23, 59, 59);
          if (dt.isAfter(end)) return false;
        }
        return true;
      }).toList();
    }

    setState(() {
      _filteredEmpresas = list;
    });
  }

  Widget _verticalDatePill(String label, DateTime? date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Icon(
            Icons.calendar_today,
            color: const Color(0xFFD92344),
            size: 22,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(String empresaId, String? nombre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de eliminar la empresa "${nombre ?? 'Sin nombre'}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await SupabaseService.instance.deleteEmpresa(empresaId);
        await _loadEmpresas();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Empresa eliminada'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header outside the inner padding so it spans full width
            const SuperadminHeader(),
            const SizedBox(height: 16),

            // Main content with horizontal padding
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Empresas',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Lista completa de empresas registradas',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final created = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CreacionEmpresas(),
                            ),
                          );
                          if (created == true) {
                            await _loadEmpresas();
                          }
                        },
                        icon: const Icon(Icons.add_business),
                        label: const Text('Crear Empresa'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 8,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Filters: name search + date range
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                // ignore: deprecated_member_use
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _filterNameController,
                            decoration: InputDecoration(
                              hintText: 'Buscar por nombre',
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Colors.grey,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (_) => _applyFilters(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _filterFrom = null;
                            _filterTo = null;
                            _filterNameController.clear();
                            _applyFilters();
                          });
                        },
                        child: const Text('Limpiar'),
                      ),
                      const SizedBox(width: 8),
                      _verticalDatePill('Fecha', _filterFrom, () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _filterFrom ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now().add(
                            const Duration(days: 3650),
                          ),
                        );
                        if (picked != null) {
                          setState(() => _filterFrom = picked);
                          _applyFilters();
                        }
                      }),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_empresas.isEmpty)
                    Card(
                      color: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.business_outlined,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No hay empresas registradas',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else if (_filteredEmpresas.isEmpty)
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Center(
                          child: Text(
                            'No hay empresas que coincidan con los filtros',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      ),
                    )
                  else
                    ..._filteredEmpresas.map((empresa) {
                      return CompanyTile(
                        empresa: empresa,
                        trailing: InkWell(
                          onTap: () =>
                              _confirmDelete(empresa['id'], empresa['nombre']),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  // ignore: deprecated_member_use
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Color(0xFFD92344),
                            ),
                          ),
                        ),
                        onTap: () {
                          final id = empresa['id'] as String?;
                          if (id != null) {
                            Navigator.of(context)
                                .push(
                                  MaterialPageRoute(
                                    builder: (_) => EmpresaDetallePage(
                                      empresaId: id,
                                      initialEmpresa: empresa,
                                    ),
                                  ),
                                )
                                .then((_) => _loadEmpresas());
                          }
                        },
                      );
                    }),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
