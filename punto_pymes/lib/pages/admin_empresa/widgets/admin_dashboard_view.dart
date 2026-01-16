import 'package:flutter/material.dart';
import '../../../service/supabase_service.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  Map<String, dynamic>? _summary;
  List<Map<String, dynamic>> _ultimosRegistros = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch both pieces of data in parallel for efficiency
      final results = await Future.wait([
        SupabaseService.instance.getAdminDashboardSummary(),
        SupabaseService.instance.getUltimosRegistros(),
      ]);

      if (!mounted) return;

      setState(() {
        _summary = results[0] as Map<String, dynamic>;
        _ultimosRegistros = results[1] as List<Map<String, dynamic>>;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Error al cargar el dashboard:\n${e.toString()}";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView(
        padding: const EdgeInsets.all(0),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 0.0),
            child: Text(
              'Inicio',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 16.0),
            child: Text(
              'Resumen general de la actividad y datos clave de tu empresa.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _StatCard(
                label: 'Empleados Activos',
                value: _summary?['empleados_activos']?.toString() ?? '0',
                icon: Icons.people_outline,
                color: Colors.pink,
              ),
              _StatCard(
                label: 'Registros Hoy',
                value: _summary?['registros_hoy']?.toString() ?? '0',
                icon: Icons.checklist_rtl,
                color: Colors.blue,
              ),
              _StatCard(
                label: 'Notificaciones Enviadas',
                value: _summary?['notificaciones_enviadas']?.toString() ?? '0',
                icon: Icons.notifications_none,
                color: Colors.orange,
              ),
              _StatCard(
                label: 'Tareas Pendientes',
                value: _summary?['tareas_pendientes']?.toString() ?? '0',
                icon: Icons.assignment_outlined,
                color: const Color(0xFFD32F2F),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Cabecera: Título y "Ver todos"
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4.0,
                  vertical: 10.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Últimos Registros",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2D2D), // Negro suave
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Tu lógica para ver todos
                      },
                      child: const Text(
                        "Ver todos >",
                        style: TextStyle(
                          color: Color(0xFF8B3A3A), // Rojo/Marrón oscuro
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              // 2. Contenido: Lista o Empty State
              if (_ultimosRegistros.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 40,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white, // Fondo BLANCO
                    borderRadius: BorderRadius.circular(
                      24,
                    ), // Bordes bien redondeados
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.04 * 255).round()),
                        // Sombra muy sutil
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icono temporal que simula el diseño
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 80,
                            color: Color(0xFFD32F2F).withAlpha((0.8 * 255).round()),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.access_time_filled,
                              size: 30,
                              color: Color(0xFFD32F2F),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 25,
                      ), // Espacio entre imagen y texto
                      const Text(
                        "Sin registros hoy",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A), // Texto oscuro fuerte
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "No se ha registrado actividad de asistencia",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF757575), // Gris neutro
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: _ultimosRegistros
                      .map((registro) => _RecentCheckInTile(registro: registro))
                      .toList(),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// Helper widget for stat cards
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Crear degradado basado en el color
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [color.withAlpha((0.8 * 255).round()), color],
    );

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha((0.25 * 255).round()),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 13.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                  color: Colors.white.withAlpha((0.2 * 255).round()),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// Helper widget for recent check-in list items
class _RecentCheckInTile extends StatelessWidget {
  final Map<String, dynamic> registro;
  const _RecentCheckInTile({required this.registro});

  @override
  Widget build(BuildContext context) {
    final nombre = registro['empleado_nombre'] as String? ?? 'N/A';
    final initials = nombre
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0])
        .take(2)
        .join()
        .toUpperCase();
    final horaEntrada = registro['hora_entrada'] as String? ?? '--:--:--';
    // Format time to HH:mm AM/PM if possible
    String formattedTime;
    try {
      final timeParts = horaEntrada.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      formattedTime = TimeOfDay(hour: hour, minute: minute).format(context);
    } catch (_) {
      formattedTime = horaEntrada;
    }

    final estado = registro['estado_entrada'] as String? ?? 'Pendiente';

    Color estadoColor;
    switch (estado) {
      case 'A tiempo':
        estadoColor = Colors.green;
        break;
      case 'Tarde':
        estadoColor = Colors.orange;
        break;
      default:
        estadoColor = Colors.grey;
    }

    return Card(
      elevation: 0,
      color: Colors.transparent, // Transparent to match the background
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          nombre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(registro['departamento'] ?? 'Sin departamento'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formattedTime,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              estado,
              style: TextStyle(
                color: estadoColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
