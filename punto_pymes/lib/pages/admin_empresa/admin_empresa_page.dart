import 'package:flutter/material.dart';
import '../../service/supabase_service.dart';
import '../superadmin/logout_helper.dart';
import 'widgets/admin_empresa_header.dart';
import 'widgets/admin_empresa_nav.dart';
import 'widgets/admin_empresa_sections.dart';

class AdminEmpresaPage extends StatefulWidget {
  const AdminEmpresaPage({super.key});

  @override
  State<AdminEmpresaPage> createState() => _AdminEmpresaPageState();
}

class _AdminEmpresaPageState extends State<AdminEmpresaPage> {
  int _currentIndex = 0;
  String? _nombreAdmin;
  String? _nombreEmpresa;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    try {
      final datosEmpleado = await SupabaseService.instance.getEmpleadoActual();
      debugPrint('AdminEmpresaPage: datosEmpleado -> $datosEmpleado');
      if (datosEmpleado != null) {
        final nombreCompleto =
            datosEmpleado['nombre_completo'] ?? 'Administrador';
        final empresaId = datosEmpleado['empresa_id'];

        if (empresaId != null) {
          final empresa = await SupabaseService.instance.getEmpresaById(
            empresaId.toString(),
          );
          debugPrint('AdminEmpresaPage: empresa lookup -> $empresa');
          if (mounted) {
            setState(() {
              _nombreAdmin = nombreCompleto;
              _nombreEmpresa = empresa?['nombre'] ?? 'Empresa';
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error cargando datos del admin: $e');
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _onNavTap(int index) => setState(() => _currentIndex = index);

  Future<void> _showLogoutConfirmation() async {
    // Use the shared superadmin logout dialog to keep UI consistent
    await showLogoutConfirmation(context, afterRoute: '/access-selection');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            AdminEmpresaHeader(
              nombreAdmin: _nombreAdmin,
              nombreEmpresa: _nombreEmpresa,
              onLogout: _showLogoutConfirmation,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: IndexedStack(
                  index: _currentIndex,
                  children: const [
                    AdminEmpresaSections(tabIndex: 0),
                    AdminEmpresaSections(tabIndex: 1),
                    AdminEmpresaSections(tabIndex: 2),
                    AdminEmpresaSections(tabIndex: 3),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: AdminEmpresaNav(
                currentIndex: _currentIndex,
                onIndexChanged: _onNavTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
