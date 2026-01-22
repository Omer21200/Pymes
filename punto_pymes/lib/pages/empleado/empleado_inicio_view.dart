import 'package:flutter/material.dart';
import '../../service/supabase_service.dart';
import '../../theme.dart';
import 'widgets/empleado_stats_card.dart';
import 'widgets/empleado_quick_access.dart';
import 'widgets/news_carousel.dart';
import '../../widgets/company_map_preview.dart';

class EmpleadoInicioView extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  final VoidCallback? onRegistrarAsistencia;

  const EmpleadoInicioView({
    super.key,
    this.onNavigateTab,
    this.onRegistrarAsistencia,
  });

  @override
  State<EmpleadoInicioView> createState() => _EmpleadoInicioViewState();
}

class _EmpleadoInicioViewState extends State<EmpleadoInicioView> {
  late Future<Map<String, dynamic>> _estadisticasFuture;
  late Future<List<Map<String, dynamic>>> _noticiasFuture;

  @override
  void initState() {
    super.initState();
    _estadisticasFuture = SupabaseService.instance.getEmpleadoEstadisticas();
    _noticiasFuture = SupabaseService.instance.getNoticiasUsuario();
  }

  void _navigateToRegistrar() {
    // Llamar al callback de registrar que viene del padre
    widget.onRegistrarAsistencia?.call();
  }

  void _navigateToReportes() {
    // Navegar a la pestaña de Reportes (tab 2)
    widget.onNavigateTab?.call(2);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 16, bottom: 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Noticias y Anuncios - AL INICIO
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _noticiasFuture,
            builder: (context, snapshot) {
              final noticias = snapshot.data ?? [];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: NewsCarousel(
                  noticias: noticias,
                  onNewsPressed: () {
                    // Aquí puedes agregar lógica para navegar a detalle de noticia
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 32),

          // Encabezado de bienvenida
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bienvenido', style: AppTextStyles.headline),
                const SizedBox(height: 4),
                Text('Tu espacio de empleado', style: AppTextStyles.subtitle),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // (Carrusel principal mostrado arriba) - duplicado eliminado

          // Estadísticas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FutureBuilder<Map<String, dynamic>>(
              future: _estadisticasFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Error al cargar estadísticas',
                      style: TextStyle(color: Colors.red.shade500),
                    ),
                  );
                }

                final stats = snapshot.data ?? {};

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: EmpleadoStatsCard(
                        label: 'Asistencias',
                        value: '${stats['dias_asistidos'] ?? 0}',
                        icon: Icons.check_circle,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: EmpleadoStatsCard(
                        label: 'A tiempo',
                        value: '${stats['a_tiempo'] ?? 0}',
                        icon: Icons.thumb_up,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: EmpleadoStatsCard(
                        label: 'Tardanzas',
                        value: '${stats['tardanzas'] ?? 0}',
                        icon: Icons.schedule,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Accesos rápidos
          EmpleadoQuickAccess(
            onRegistrarPressed: _navigateToRegistrar,
            onReportesPressed: _navigateToReportes,
          ),
          const SizedBox(height: 24),

          // Divider
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 20),

          // Mapa de la empresa (reemplaza la lista duplicada de noticias en la parte inferior)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: const CompanyMapPreview(showOnlyCompany: true),
          ),
        ],
      ),
    );
  }
}
