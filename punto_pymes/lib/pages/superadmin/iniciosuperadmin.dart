import 'package:flutter/material.dart';
import '../../theme.dart';
import 'widgets/summary_card.dart';
import 'widgets/bottom_nav.dart';
import 'empresas_list.dart';
import 'admins_list.dart';
import 'empresa_detalle.dart';
import 'widgets/superadmin_header.dart';
import 'widgets/company_tile.dart';
import '../../service/supabase_service.dart';

class InicioSuperadmin extends StatefulWidget {
  const InicioSuperadmin({super.key});

  @override
  State<InicioSuperadmin> createState() => _InicioSuperadminState();
}

class _InicioSuperadminState extends State<InicioSuperadmin> {
  int _currentIndex = 0;
  List<Map<String, dynamic>> _empresas = [];
  bool _isLoading = true;
  int _totalAdmins = 0;
  List<Map<String, dynamic>> _adminsRecientes = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final empresas = await SupabaseService.instance.getEmpresas();

      // Contar admins de empresas
      final profiles = await SupabaseService.instance.client
          .from('profiles')
          .select()
          .eq('rol', 'ADMIN_EMPRESA');
      // Cargar admins recientes con empresa
      final adminsRecientes = await SupabaseService.instance.client
          .from('profiles')
          .select(
            'id,nombres,apellidos,rol,created_at,empresa_id,empresas(nombre)',
          )
          .eq('rol', 'ADMIN_EMPRESA')
          .order('created_at', ascending: false)
          .limit(5);

      setState(() {
        _empresas = empresas;
        _totalAdmins = profiles.length;
        _adminsRecientes = List<Map<String, dynamic>>.from(adminsRecientes);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar datos: $e')));
      }
    }
  }

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
    // Recargar datos cuando vuelva al resumen
    if (index == 0) {
      _loadData();
    }
  }

  List<Widget> _buildActividadReciente() {
    final actividades = <Widget>[];

    // 1) Admins recientes
    for (var admin in _adminsRecientes) {
      final createdAt = admin['created_at'];
      String timeAgo = 'Reciente';
      if (createdAt != null) {
        try {
          final date = DateTime.parse(createdAt);
          final diff = DateTime.now().difference(date);
          if (diff.inDays > 0) {
            timeAgo =
                'Hace ${diff.inDays} ${diff.inDays == 1 ? 'día' : 'días'}';
          } else if (diff.inHours > 0) {
            timeAgo =
                'Hace ${diff.inHours} ${diff.inHours == 1 ? 'hora' : 'horas'}';
          } else if (diff.inMinutes > 0) {
            timeAgo =
                'Hace ${diff.inMinutes} ${diff.inMinutes == 1 ? 'minuto' : 'minutos'}';
          } else {
            timeAgo = 'Hace unos momentos';
          }
        } catch (_) {}
      }

      final empresaNombre = admin['empresas'] != null
          ? admin['empresas']['nombre']
          : 'Sin empresa';
      final fullName = '${admin['nombres'] ?? ''} ${admin['apellidos'] ?? ''}'
          .trim();

      actividades.add(
        Card(
          color: AppColors.surface,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.surfaceSoft,
                  child: const Icon(
                    Icons.person_add_alt,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nuevo administrador creado:',
                        style: AppTextStyles.smallLabel.copyWith(
                          color: AppColors.mutedGray,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$fullName • $empresaNombre',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  timeAgo,
                  style: AppTextStyles.smallLabel.copyWith(
                    color: AppColors.mutedGray,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 2) Empresas recientes (ordenar por fecha desc y tomar 3)
    final empresasOrdenadas = [..._empresas];
    empresasOrdenadas.sort((a, b) {
      final ca = a['created_at'];
      final cb = b['created_at'];
      if (ca == null || cb == null) return 0;
      return DateTime.parse(cb).compareTo(DateTime.parse(ca));
    });

    for (var empresa in empresasOrdenadas.take(3)) {
      final createdAt = empresa['created_at'];
      String timeAgo = 'Reciente';

      if (createdAt != null) {
        try {
          final date = DateTime.parse(createdAt);
          final diff = DateTime.now().difference(date);
          if (diff.inDays > 0) {
            timeAgo =
                'Hace ${diff.inDays} ${diff.inDays == 1 ? 'día' : 'días'}';
          } else if (diff.inHours > 0) {
            timeAgo =
                'Hace ${diff.inHours} ${diff.inHours == 1 ? 'hora' : 'horas'}';
          } else if (diff.inMinutes > 0) {
            timeAgo =
                'Hace ${diff.inMinutes} ${diff.inMinutes == 1 ? 'minuto' : 'minutos'}';
          } else {
            timeAgo = 'Hace unos momentos';
          }
        } catch (e) {
          // Mantener "Reciente" si hay error
        }
      }

      actividades.add(
        Card(
          color: AppColors.surface,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.surfaceSoft,
                  child: Icon(
                    Icons.apartment,
                    color: AppColors.accentBlue,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nueva empresa registrada:',
                        style: AppTextStyles.smallLabel.copyWith(
                          color: AppColors.mutedGray,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        empresa['nombre'] ?? 'Sin nombre',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  timeAgo,
                  style: AppTextStyles.smallLabel.copyWith(
                    color: AppColors.mutedGray,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (actividades.isEmpty) {
      actividades.add(
        Card(
          color: AppColors.surface,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
            child: Center(
              child: Text(
                'No hay actividad reciente',
                style: AppTextStyles.smallLabel.copyWith(
                  color: AppColors.mutedGray,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return actividades;
  }

  Widget _buildResumen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SuperadminHeader(),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resumen del Sistema',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Vista general de NEXUS',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 12),

                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  Row(
                    children: [
                      SummaryCard(
                        title: 'Empresas',
                        value: '${_empresas.length}',
                        icon: Icons.apartment,
                      ),
                      const SizedBox(width: 12),
                      SummaryCard(
                        title: 'Admins',
                        value: '$_totalAdmins',
                        icon: Icons.group,
                      ),
                    ],
                  ),

                const SizedBox(height: 18),

                // Lista de empresas
                const Text(
                  'Empresas Registradas',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),

                if (_empresas.isEmpty && !_isLoading)
                  Card(
                    color: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
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
                  ...(() {
                    final empresasOrdenadas = [..._empresas];
                    empresasOrdenadas.sort((a, b) {
                      final ca = a['created_at'];
                      final cb = b['created_at'];
                      if (ca == null || cb == null) return 0;
                      return DateTime.parse(cb).compareTo(DateTime.parse(ca));
                    });
                    return empresasOrdenadas
                        .take(4)
                        .map(
                          (empresa) => CompanyTile(
                            empresa: empresa,
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
                                    .then((_) => _loadData());
                              }
                            },
                          ),
                        );
                  }()),

                const SizedBox(height: 18),

                // Actividad Reciente
                const Text(
                  'Actividad Reciente',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),

                ..._buildActividadReciente(),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            // IndexedStack keeps state of each tab
            IndexedStack(
              index: _currentIndex,
              children: [
                _buildResumen(),
                const EmpresasList(),
                // Admis tab -> list of admins
                const AdminsList(),
              ],
            ),

            // Positioned bottom nav floating above content
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Center(
                  child: SuperadminBottomNav(
                    currentIndex: _currentIndex,
                    onTap: _onNavTap,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
