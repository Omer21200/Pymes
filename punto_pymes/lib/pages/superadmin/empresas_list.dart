import 'package:flutter/material.dart';
import 'widgets/company_tile.dart';
import 'widgets/superadmin_header.dart';
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

  @override
  void initState() {
    super.initState();
    _loadEmpresas();
  }

  Future<void> _loadEmpresas() async {
    setState(() => _isLoading = true);
    try {
      final empresas = await SupabaseService.instance.getEmpresas();
      setState(() {
        _empresas = empresas;
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
                  const Text(
                    'Empresas',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Lista completa de empresas registradas',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
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
                        backgroundColor: const Color(0xFFD92344),
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
                  ),
                  const SizedBox(height: 12),

                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_empresas.isEmpty)
                    Card(
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
                  else
                    ..._empresas.map((empresa) {
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
