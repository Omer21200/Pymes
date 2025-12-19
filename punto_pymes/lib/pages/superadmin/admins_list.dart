import 'package:flutter/material.dart';
import 'package:pymes2/theme.dart'; // Importamos el diseño centralizado
import '../../service/supabase_service.dart';
import 'widgets/superadmin_header.dart';
import 'creacionadmis.dart';

class AdminsList extends StatefulWidget {
  const AdminsList({super.key});

  @override
  State<AdminsList> createState() => _AdminsListState();
}

class _AdminsListState extends State<AdminsList> {
  List<Map<String, dynamic>> _admins = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  Future<void> _loadAdmins() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final admins = await SupabaseService.instance.client
          .from('profiles')
          .select('id,nombres,apellidos,rol,empresa_id, empresas(nombre)')
          .eq('rol', 'ADMIN_EMPRESA')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _admins = List<Map<String, dynamic>>.from(admins);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Manejo de error silencioso o snackbar si prefieres
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Referencia rápida a los textos del tema
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. HEADER GLOBAL
            const SuperadminHeader(
              title: 'Administradores',
              subtitle: 'Gestión de usuarios del sistema',
              showLogout: false,
            ),

            // 2. ZONA SUPERIOR: BOTÓN CREAR (Integrado en el cuerpo)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Listado de Usuarios',
                    style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final created = await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CreacionAdmis())
                      );
                      if (created == true) _loadAdmins();
                    },
                    icon: const Icon(Icons.person_add_rounded, size: 18, color: Colors.white),
                    label: const Text('Nuevo Admin'),
                  ),
                ],
              ),
            ),

            // 3. LISTADO DE ADMINS
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadAdmins,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _admins.isEmpty
                        ? _buildEmptyState(textTheme)
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            itemCount: _admins.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return _buildAdminCard(_admins[index], textTheme);
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard(Map<String, dynamic> admin, TextTheme textTheme) {
    final empresaNombre = admin['empresas'] != null ? admin['empresas']['nombre'] : 'Sin Asignar';
    final fullName = '${admin['nombres'] ?? ''} ${admin['apellidos'] ?? ''}'.trim();
    
    // Lógica de Iniciales (Mantenemos la lógica aquí, el diseño en el theme)
    String initials = '?';
    if (fullName.isNotEmpty) {
      initials = fullName[0].toUpperCase();
    }

    return Container(
      // DISEÑO: Decoración de tarjeta desde Theme
      decoration: AppTheme.cardDecoration,
      
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Acción al tocar la tarjeta (Detalle, Editar, etc.)
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 1. AVATAR
                Container(
                  width: 50, height: 50,
                  // DISEÑO: Decoración de avatar desde Theme
                  decoration: AppTheme.adminAvatarDecoration,
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 20
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // 2. INFORMACIÓN
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName.isEmpty ? 'Usuario Sin Nombre' : fullName,
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      
                      // Nombre de la empresa con icono
                      Row(
                        children: [
                          Icon(Icons.business_rounded, size: 14, color: AppTheme.iconGrey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              empresaNombre,
                              style: textTheme.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 6),

                      // Etiqueta de Rol (Chip)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: AppTheme.roleTagDecoration, // Desde Theme
                        child: Text(
                          'ADMIN EMPRESA',
                          style: AppTheme.roleTagTextStyle, // Desde Theme
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. MENÚ O ACCIÓN
                Icon(Icons.more_vert_rounded, color: AppTheme.iconGrey),
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
          const Icon(Icons.people_outline_rounded, size: 60, color: AppTheme.iconGrey),
          const SizedBox(height: 16),
          Text('No hay administradores registrados', style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}