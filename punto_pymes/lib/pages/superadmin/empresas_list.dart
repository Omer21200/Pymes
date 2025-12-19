import 'package:flutter/material.dart';
import 'package:pymes2/theme.dart'; 
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
      if (mounted) {
        setState(() {
          _empresas = empresas;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar empresas: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(String empresaId, String? nombre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Empresa'),
        content: Text('¿Estás seguro de eliminar a "$nombre"?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
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
            const SnackBar(content: Text('Empresa eliminada')),
          );
        }
      } catch (e) {
        // Manejo de error
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      
      // 1. CORRECCIÓN: HEADER (AppBar)
      // Añadimos el AppBar rojo para mantener consistencia y que no se vea vacío
      appBar: AppBar(
        title: const Text(
          'Gestión de Empresas',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryColor, // El rojo de tu marca
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false, // Quitamos la flecha de volver porque es una pestaña principal
      ),

      // 2. CORRECCIÓN: BOTÓN FLOTANTE (Posición)
      // Usamos un Padding para levantar el botón 80 pixeles y que no lo tape el menú
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0), // <-- ESTO EVITA EL SOLAPAMIENTO
        child: FloatingActionButton.extended(
          onPressed: () async {
            final created = await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreacionEmpresas())
            );
            if (created == true) _loadEmpresas();
          },
          backgroundColor: AppTheme.primaryColor,
          icon: const Icon(Icons.add_business_rounded, color: Colors.white),
          label: const Text('Crear Empresa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          elevation: 4,
        ),
      ),

      body: RefreshIndicator(
        onRefresh: _loadEmpresas,
        child: CustomScrollView(
          slivers: [
            // Pequeño espacio superior
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Lista de empresas
            _isLoading
                ? const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _empresas.isEmpty
                    ? SliverFillRemaining(child: _buildEmptyState())
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final empresa = _empresas[index];
                            // Añadimos padding extra al final para scroll seguro
                            final isLast = index == _empresas.length - 1;
                            return Padding(
                              padding: EdgeInsets.fromLTRB(16, 0, 16, isLast ? 100 : 12),
                              child: _buildCompanyCard(empresa),
                            );
                          },
                          childCount: _empresas.length,
                        ),
                      ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS DE DISEÑO ---

  Widget _buildCompanyCard(Map<String, dynamic> empresa) {
    final nombre = empresa['nombre'] ?? 'Sin Nombre';
    final ruc = empresa['ruc'] ?? 'Sin RUC';
    final email = empresa['email'] ?? 'Sin Email'; 
    final fotoUrl = empresa['empresa_foto_url'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
             final id = empresa['id'] as String?;
             if (id != null) {
               Navigator.of(context).push(MaterialPageRoute(
                 builder: (_) => EmpresaDetallePage(empresaId: id, initialEmpresa: empresa),
               )).then((_) => _loadEmpresas());
             }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Logo
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: fotoUrl != null
                        ? Image.network(fotoUrl, fit: BoxFit.cover)
                        : Icon(Icons.business_rounded, color: Colors.blue.shade700, size: 28),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: const TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold, 
                          color: AppTheme.secondaryColor
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'RUC: $ruc',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                // Eliminar
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                  onPressed: () => _confirmDelete(empresa['id'], nombre),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.domain_disabled_rounded, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No hay empresas',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}