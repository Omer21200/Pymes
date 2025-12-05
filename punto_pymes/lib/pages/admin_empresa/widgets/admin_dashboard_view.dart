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
      return Center(child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      ));
    }
    
    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView(
        padding: const EdgeInsets.all(0),
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Resumen de actividad del sistema',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          _StatCard(
            label: 'Empleados Activos',
            value: _summary?['empleados_activos']?.toString() ?? '0',
            icon: Icons.people_outline,
            color: Colors.pink,
          ),
          const SizedBox(height: 16),
          _StatCard(
            label: 'Registros Hoy',
            value: _summary?['registros_hoy']?.toString() ?? '0',
            icon: Icons.checklist_rtl,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          _StatCard(
            label: 'Notificaciones Enviadas',
            value: _summary?['notificaciones_enviadas']?.toString() ?? '0',
            icon: Icons.notifications_none,
            color: Colors.orange,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Últimos Registros',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to full list
                },
                child: const Text('Ver todos >'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_ultimosRegistros.isEmpty)
            const Card(
                elevation: 0,
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: Text("No hay registros de asistencia hoy.")),
                )),
          ..._ultimosRegistros.map((registro) => _RecentCheckInTile(registro: registro)),
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
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withAlpha(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(value, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
          ],
        ),
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
    final initials = nombre.split(' ').where((s) => s.isNotEmpty).map((s) => s[0]).take(2).join().toUpperCase();
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
    switch(estado) {
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
          child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(registro['departamento'] ?? 'Sin departamento'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(formattedTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(estado, style: TextStyle(color: estadoColor, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
