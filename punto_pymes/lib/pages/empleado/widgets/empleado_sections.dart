import 'package:flutter/material.dart';
import '../notificacion.dart';
import '../reportes.dart';
import '../empleado_inicio_view.dart';
import '../departamento/departamento_page.dart';

class EmpleadoSections extends StatefulWidget {
  final int tabIndex;
  final ValueChanged<int>? onNavigateTab;
  final VoidCallback? onRegistrarAsistencia;

  const EmpleadoSections({
    super.key,
    required this.tabIndex,
    this.onNavigateTab,
    this.onRegistrarAsistencia,
  });

  @override
  State<EmpleadoSections> createState() => _EmpleadoSectionsState();
}

class _EmpleadoSectionsState extends State<EmpleadoSections> {
  final GlobalKey _reportesKey = GlobalKey();

  void refreshReportes() {
    (_reportesKey.currentState as dynamic)?.refreshData();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.tabIndex) {
      case 0:
        return EmpleadoInicioView(
          onNavigateTab: widget.onNavigateTab,
          onRegistrarAsistencia: widget.onRegistrarAsistencia,
        );
      case 1:
        return const NotificacionView(padding: EdgeInsets.only(top: 16, bottom: 140));
      case 2:
        return ReportesPage(key: _reportesKey);
      case 3:
        return const DepartamentoPage();
      default:
        return const SizedBox.shrink();
    }
  }
}
