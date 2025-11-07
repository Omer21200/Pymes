import 'package:flutter/material.dart';
import '../main.dart';
import 'notificaciones.dart';
import '../splash_screen/splash_screen.dart';
import '../widgets/profile_card.dart';
import '../widgets/metrics_row.dart';
import '../widgets/quick_access_grid.dart';
import '../widgets/news_section.dart';
import '../widgets/bottom_nav_pill.dart';


class InstitucionPage extends StatefulWidget {
  final String institutionName;
  final String userName;
  final String role; // e.g. 'Empleado', 'Administrador'

  const InstitucionPage({
    required this.institutionName,
    this.userName = 'Juan Pérez',
    this.role = 'Empleado',
    super.key,
  });

  @override
  State<InstitucionPage> createState() => _InstitucionPageState();
}

class _InstitucionPageState extends State<InstitucionPage> {
  int _selectedIndex = 0;

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _initials(widget.userName);
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          child: _buildBodyForIndex(_selectedIndex, initials),
        ),
      ),
      bottomNavigationBar: BottomNavPill(
        selectedIndex: _selectedIndex,
        onSelect: (i) => setState(() => _selectedIndex = i),
        onFloating: () => setState(() => _selectedIndex = 3),
      ),
    );
  }


  Widget _buildBodyForIndex(int index, String initials) {
    switch (index) {
      case 1:
        return const NotificacionesContent();
      case 2:
        return const Center(
          key: ValueKey('reportes'),
          child: Text('Reportes', style: TextStyle(fontSize: 20)),
        );
      case 3:
        return const Center(
          key: ValueKey('registrar'),
          child: Text('Iniciar registro', style: TextStyle(fontSize: 20)),
        );
      case 0:
      default:
        return Padding(
          key: const ValueKey('home'),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 120, top: 16),
            children: [
              ProfileCard(
                userName: widget.userName,
                institutionName: widget.institutionName,
                role: widget.role,
                onAction: () async {
                  try {
                    await supabase.auth.signOut();
                  } catch (_) {}
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const SplashScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
              const SizedBox(height: 18),
              const MetricsRow(),
              const SizedBox(height: 18),
              const Text('Accesos Rápidos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              QuickAccessGrid(
                onRegister: () => setState(() => _selectedIndex = 3),
                onReports: () => setState(() => _selectedIndex = 2),
              ),
              const SizedBox(height: 18),
              NewsSection(onViewAll: () {}),
            ],
          ),
        );
    }
  }

}
