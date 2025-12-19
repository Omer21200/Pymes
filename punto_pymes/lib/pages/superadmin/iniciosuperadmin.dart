import 'package:flutter/material.dart';
import 'package:pymes2/theme.dart'; // Asegúrate de importar tu theme
import '../../service/supabase_service.dart';

// Importa tus páginas de listas para la navegación
import 'empresas_list.dart';
import 'admins_list.dart';
import 'empresa_detalle.dart'; 
// import 'widgets/logout_helper.dart'; // Si tienes el helper de logout, úsalo

class InicioSuperadmin extends StatefulWidget {
  const InicioSuperadmin({super.key});

  @override
  State<InicioSuperadmin> createState() => _InicioSuperadminState();
}

class _InicioSuperadminState extends State<InicioSuperadmin> {
  int _currentIndex = 0;
  
  // Datos
  List<Map<String, dynamic>> _empresas = [];
  List<Map<String, dynamic>> _adminsRecientes = [];
  int _totalAdmins = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final empresas = await SupabaseService.instance.getEmpresas();
      
      // Contar admins de empresas (Optimizado: count exact)
      final profilesCount = await SupabaseService.instance.client
          .from('profiles')
          .select('id') // Solo traemos ID para contar más rápido
          .eq('rol', 'ADMIN_EMPRESA')
          .count(); // Usamos count si supabase lo permite, sino .length abajo

      // Cargar admins recientes con empresa
      final adminsRecientes = await SupabaseService.instance.client
          .from('profiles')
          .select('id,nombres,apellidos,rol,created_at,empresa_id,empresas(nombre)')
          .eq('rol', 'ADMIN_EMPRESA')
          .order('created_at', ascending: false)
          .limit(5);
      
      if (mounted) {
        setState(() {
          _empresas = empresas;
          _totalAdmins = profilesCount.count; 
          _adminsRecientes = List<Map<String, dynamic>>.from(adminsRecientes);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      // Fallback si count falla (versión antigua de supabase flutter)
      debugPrint('Error cargando datos: $e');
    }
  }

  // Lógica de "Hace X tiempo"
  String _timeAgo(String? dateString) {
    if (dateString == null) return 'Reciente';
    try {
      final date = DateTime.parse(dateString);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 0) return 'Hace ${diff.inDays} ${diff.inDays == 1 ? 'día' : 'días'}';
      if (diff.inHours > 0) return 'Hace ${diff.inHours} ${diff.inHours == 1 ? 'hora' : 'horas'}';
      if (diff.inMinutes > 0) return 'Hace ${diff.inMinutes} ${diff.inMinutes == 1 ? 'minuto' : 'minutos'}';
      return 'Hace un momento';
    } catch (_) {
      return 'Reciente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      // AppBar unificada para todas las pestañas o dinámica según el index
      appBar: _currentIndex == 0 ? _buildDashboardAppBar() : null,
      
      body: Stack(
        children: [
          // 1. Contenido Principal (IndexedStack para mantener estado)
          IndexedStack(
            index: _currentIndex,
            children: [
              _buildDashboardTab(), // Tab 0: Resumen
              const EmpresasList(), // Tab 1: Empresas
              const AdminsList(),   // Tab 2: Admins
            ],
          ),

          // 2. Barra de Navegación Flotante
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: _buildFloatingBottomNav(),
          ),
        ],
      ),
    );
  }

  // --- APPBAR ---
  AppBar _buildDashboardAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Panel de Control', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('Super Administrador', 
            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.normal)
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.logout_rounded, size: 18),
          ),
          onPressed: () {
            // Tu lógica de logout
             SupabaseService.instance.signOut();
             Navigator.of(context).pushReplacementNamed('/access-selection');
          },
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  // --- PESTAÑA RESUMEN (DASHBOARD) ---
  Widget _buildDashboardTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), // Padding inferior extra para el nav
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Texto de bienvenida
            const Text(
              'Resumen del Sistema',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
            ),
            Text(
              'Estadísticas generales de NEXUS',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // 1. GRID DE ESTADÍSTICAS
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildStatCard(
                  title: 'Empresas',
                  count: '${_empresas.length}',
                  icon: Icons.business_rounded,
                  color: Colors.blue,
                  bgColor: const Color(0xFFE3F2FD),
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _buildStatCard(
                  title: 'Admins',
                  count: '$_totalAdmins',
                  icon: Icons.supervisor_account_rounded,
                  color: AppTheme.primaryColor,
                  bgColor: const Color(0xFFFFEBEE),
                  onTap: () => setState(() => _currentIndex = 2),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 2. EMPRESAS RECIENTES
            _buildSectionHeader('Empresas Recientes', Icons.new_releases_outlined),
            const SizedBox(height: 12),
            if (_empresas.isEmpty)
              _buildEmptyState('No hay empresas registradas')
            else
              ..._empresas.take(3).map((empresa) {
                 // Ordenar por fecha si fuera necesario, aquí asumo que vienen como sea o las ordenas
                 return _buildListCard(
                  title: empresa['nombre'] ?? 'Sin Nombre',
                  subtitle: empresa['ruc'] ?? 'Sin RUC', // O email
                  icon: Icons.apartment,
                  iconColor: Colors.blue,
                  timeAgo: _timeAgo(empresa['created_at']),
                  onTap: () {
                     final id = empresa['id'] as String?;
                     if (id != null) {
                       Navigator.of(context).push(MaterialPageRoute(
                         builder: (_) => EmpresaDetallePage(empresaId: id, initialEmpresa: empresa),
                       )).then((_) => _loadData());
                     }
                  },
                 );
              }),

            const SizedBox(height: 24),

            // 3. ACTIVIDAD RECIENTE (ADMINS)
            _buildSectionHeader('Nuevos Administradores', Icons.history),
            const SizedBox(height: 12),
            if (_adminsRecientes.isEmpty)
               _buildEmptyState('No hay actividad reciente')
            else
              ..._adminsRecientes.map((admin) {
                final nombreEmpresa = admin['empresas'] != null ? admin['empresas']['nombre'] : 'Sin empresa';
                final nombreCompleto = '${admin['nombres'] ?? ''} ${admin['apellidos'] ?? ''}';
                
                return _buildListCard(
                  title: nombreCompleto,
                  subtitle: 'Empresa: $nombreEmpresa',
                  icon: Icons.person_add_alt_1_rounded,
                  iconColor: Colors.teal,
                  timeAgo: _timeAgo(admin['created_at']),
                  onTap: () {}, // Acción al tocar admin si se desea
                );
              }),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS DE DISEÑO ---

  // Header de sección
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
        ),
      ],
    );
  }

  // Tarjeta de Estadística (Grid)
  Widget _buildStatCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryColor,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // Tarjeta de Lista (Para Empresas y Admins recientes)
  Widget _buildListCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required String timeAgo,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  timeAgo,
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(msg, style: TextStyle(color: Colors.grey[500])),
      ),
    );
  }

  // --- BARRA DE NAVEGACIÓN FLOTANTE (ESTILO CÁPSULA) ---
  Widget _buildFloatingBottomNav() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.dashboard_rounded, 'Inicio'),
          _buildNavItem(1, Icons.business_rounded, 'Empresas'),
          _buildNavItem(2, Icons.group_rounded, 'Admins'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
        if (index == 0) _loadData(); // Recargar al volver al inicio
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[400],
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}