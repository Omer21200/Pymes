import 'package:flutter/material.dart';
import 'package:pymes2/theme.dart'; // Importamos el diseño centralizado
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
    if (mounted) setState(() => _isLoading = true);
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
      }
    }
  }

  Future<void> _confirmDelete(String empresaId, String? nombre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Empresa'),
        content: Text('¿Estás seguro de eliminar a "$nombre"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            // Única excepción: Color de error específico para esta acción destructiva
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await SupabaseService.instance.deleteEmpresa(empresaId);
        await _loadEmpresas();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al eliminar')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos los estilos del texto desde el Theme
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. HEADER GLOBAL
            const SuperadminHeader(
              title: 'Gestión de Empresas',
              subtitle: 'Administra las organizaciones del sistema',
              showLogout: false,
            ),

            // 2. ZONA SUPERIOR: BOTÓN CREAR (Arriba del listado)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Listado de Empresas',
                    style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final created = await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CreacionEmpresas())
                      );
                      if (created == true) _loadEmpresas();
                    },
                    icon: const Icon(Icons.add_business_rounded, size: 18, color: Colors.white),
                    label: const Text('Crear Empresa'),
                  ),
                ],
              ),
            ),

            // 3. LISTADO DE TARJETAS
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadEmpresas,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _empresas.isEmpty
                        ? _buildEmptyState(textTheme)
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            itemCount: _empresas.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return _buildCompanyCard(_empresas[index], textTheme);
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyCard(Map<String, dynamic> empresa, TextTheme textTheme) {
    final nombre = empresa['nombre'] ?? 'Sin Nombre';
    final ruc = empresa['ruc'] ?? 'Sin RUC';
    final fotoUrl = empresa['empresa_foto_url'];

    return Container(
      // AQUÍ ESTÁ LA CLAVE: Usamos la decoración definida en theme.dart
      decoration: AppTheme.cardDecoration, 
      
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
                // Logo de la empresa
                Container(
                  width: 50, height: 50,
                  // Usamos la decoración de avatar definida en theme.dart
                  decoration: AppTheme.avatarDecoration, 
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: fotoUrl != null
                        ? Image.network(fotoUrl, fit: BoxFit.cover)
                        : const Icon(Icons.business_rounded, size: 28),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Textos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nombre, style: textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.badge_outlined, size: 14, color: AppTheme.iconGrey),
                          const SizedBox(width: 4),
                          Text('RUC: $ruc', style: textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),

                // Botón Eliminar
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor),
                  onPressed: () => _confirmDelete(empresa['id'], nombre),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.domain_disabled_rounded, size: 60, color: AppTheme.iconGrey),
          const SizedBox(height: 16),
          Text('No hay empresas registradas', style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}