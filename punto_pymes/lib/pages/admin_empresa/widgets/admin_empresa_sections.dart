import 'package:flutter/material.dart';
import '../noticias/noticias_admin_list_page.dart';
import 'admin_dashboard_view.dart';
import '../departamentos/departamentos_admin_list_page.dart';

class AdminEmpresaSections extends StatelessWidget {
  final int tabIndex;
  const AdminEmpresaSections({super.key, required this.tabIndex});

  @override
  Widget build(BuildContext context) {
    Widget content;

    switch (tabIndex) {
      case 0: // Inicio (Dashboard)
        content = const AdminDashboardView();
        break;
      case 1: // Noticias
        content = const NoticiasAdminListPage();
        break;
      case 2: // Departamentos
        content = const DepartamentosAdminListPage();
        break;
      case 3: // Reportes
        content = const Center(child: Text('Sección de Reportes')); // Placeholder
        break;
      default:
        content = const Center(child: Text('Sección no encontrada'));
    }

    // Ya no es necesario el Column > Expanded porque el contenido principal ya es un ListView.
    return content;
  }
}
