import 'package:flutter/material.dart';
import 'package:pymes2/theme.dart';
import '../../service/supabase_service.dart';
import 'creacionadmis.dart'; // Asegúrate de que este nombre sea correcto (a veces es creacion_admins.dart)

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar admins: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      
      // 1. APPBAR ROJO (COHERENCIA VISUAL)
      appBar: AppBar(
        title: const Text(
          'Administradores',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false, // Sin flecha de volver
      ),

      // 2. BOTÓN FLOTANTE (LEVANTADO)
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0), // Evita solapamiento con el menú
        child: FloatingActionButton.extended(
          onPressed: () async {
            final created = await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreacionAdmis())
            );
            if (created == true) _loadAdmins();
          },
          backgroundColor: AppTheme.primaryColor,
          icon: const Icon(Icons.person_add_rounded, color: Colors.white),
          label: const Text('Nuevo Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          elevation: 4,
        ),
      ),

      body: RefreshIndicator(
        onRefresh: _loadAdmins,
        child: CustomScrollView(
          slivers: [
            // Header descriptivo grande
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gestión de Usuarios',
                      style: TextStyle(
                        fontSize: 24, 
                        fontWeight: FontWeight.bold, 
                        color: AppTheme.secondaryColor
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Lista completa de administradores de empresa registrados.',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),

            // Lista de admins
            _isLoading
                ? const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _admins.isEmpty
                    ? SliverFillRemaining(child: _buildEmptyState())
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final admin = _admins[index];
                            final isLast = index == _admins.length - 1;
                            
                            return Padding(
                              padding: EdgeInsets.fromLTRB(20, 0, 20, isLast ? 100 : 12), // Padding inferior extra
                              child: _buildAdminCard(admin),
                            );
                          },
                          childCount: _admins.length,
                        ),
                      ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS DE DISEÑO ---

  Widget _buildAdminCard(Map<String, dynamic> admin) {
    final empresaNombre = admin['empresas'] != null ? admin['empresas']['nombre'] : 'Sin Asignar';
    final nombres = admin['nombres'] ?? '';
    final apellidos = admin['apellidos'] ?? '';
    final fullName = '$nombres $apellidos'.trim().isEmpty ? 'Usuario Sin Nombre' : '$nombres $apellidos';
    
    // Iniciales para el avatar
    String initials = '';
    if (nombres.isNotEmpty) initials += nombres[0];
    if (apellidos.isNotEmpty) initials += apellidos[0];
    if (initials.isEmpty) initials = '?';

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
            // Aquí podrías navegar al detalle del admin si existiera esa pantalla
            // Navigator.push(...) 
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 1. AVATAR CON INICIALES
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryColor.withOpacity(0.8), AppTheme.primaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initials.toUpperCase(),
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
                        fullName,
                        style: const TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold, 
                          color: AppTheme.secondaryColor
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.business_rounded, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              empresaNombre,
                              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ADMIN EMPRESA',
                          style: TextStyle(fontSize: 10, color: Colors.blue.shade800, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. ICONO DE ACCIÓN
                Icon(Icons.more_vert_rounded, color: Colors.grey[400]),
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.people_outline_rounded, size: 60, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay administradores',
            style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca el botón + para añadir uno.',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}