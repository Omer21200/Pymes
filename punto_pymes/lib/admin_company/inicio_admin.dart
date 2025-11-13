import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/metric_card.dart';
import '../widgets/registro_item.dart';

class InicioAdmin extends StatefulWidget {
  final String userId;
  final String? companyName;
  const InicioAdmin({required this.userId, this.companyName, super.key});

  @override
  State<InicioAdmin> createState() => _InicioAdminState();
}

class _InicioAdminState extends State<InicioAdmin> {
  int empleadosActivos = 0;
  int registrosHoy = 0;
  int notificacionesEnviadas = 0;
  List<Map<String, dynamic>> ultimosRegistros = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() => _loading = true);
    try {
      String? empresaId;
      if (widget.companyName != null && widget.companyName!.isNotEmpty) {
        final ent = await Supabase.instance.client.from('empresas').select('id').eq('nombre', widget.companyName!).maybeSingle();
        if (ent != null && ent['id'] != null) empresaId = ent['id'].toString();
      }

      // Empleados activos
      if (empresaId != null) {
        final empleados = await Supabase.instance.client.from('usuarios').select('id').eq('empresa_id', empresaId).eq('rol', 'empleado') as List<dynamic>? ?? [];
        empleadosActivos = empleados.length;

        // Registros hoy
        final todayStart = DateTime.now().toUtc();
        final startIso = DateTime.utc(todayStart.year, todayStart.month, todayStart.day).toIso8601String();
        try {
          final regs = await Supabase.instance.client.from('registros_asistencia').select().eq('empresa_id', empresaId).gte('capturado_en', startIso) as List<dynamic>? ?? [];
          registrosHoy = regs.length;
        } catch (_) {
          registrosHoy = 0;
        }

        // Notificaciones
        final nots = await Supabase.instance.client.from('notificaciones').select().eq('empresa_id', empresaId) as List<dynamic>? ?? [];
        notificacionesEnviadas = nots.length;

        // Últimos registros (limit 5)
        final recent = await Supabase.instance.client.from('registros_asistencia').select('id,usuario_id,capturado_en,foto_url').eq('empresa_id', empresaId).order('capturado_en', ascending: false).limit(5) as List<dynamic>? ?? [];
        ultimosRegistros = recent.map((r) => {
          'id': r['id'],
          'usuario_id': r['usuario_id'],
          'capturado_en': r['capturado_en'],
          'foto_url': r['foto_url'],
        }).toList();
      } else {
        empleadosActivos = 0;
        registrosHoy = 0;
        notificacionesEnviadas = 0;
        ultimosRegistros = [];
      }
    } catch (e) {
      debugPrint('Error cargando métricas inicio admin: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // MetricCard moved to `lib/widgets/metric_card.dart`

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // header red
        Container(
          width: double.infinity,
          color: const Color(0xFFD92344),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white24,
                child: Text(
                  widget.companyName != null && widget.companyName!.isNotEmpty ? widget.companyName!.substring(0, 1).toUpperCase() : 'A',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Admin ${widget.companyName ?? ''}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Administrador - ${widget.companyName ?? ''}', style: const TextStyle(color: Colors.white70)),
                ]),
              ),
              IconButton(onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/access-selection', (r) => false);
              }, icon: const Icon(Icons.logout, color: Colors.white)),
            ],
          ),
        ),

        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const SizedBox(height: 8),
                    Text('Dashboard', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 6),
                    const Text('Resumen de actividad del sistema', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 12),
                    MetricCard(title: 'Empleados Activos', value: empleadosActivos.toString(), icon: Icons.group, bg: const Color(0xFFFFEAEA)),
                    const SizedBox(height: 8),
                    MetricCard(title: 'Registros Hoy', value: registrosHoy.toString(), icon: Icons.event_available, bg: const Color(0xFFEAF6FF)),
                    const SizedBox(height: 8),
                    MetricCard(title: 'Notificaciones Enviadas', value: notificacionesEnviadas.toString(), icon: Icons.notifications, bg: const Color(0xFFFFEAEA)),
                    const SizedBox(height: 16),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Últimos Registros', style: TextStyle(fontWeight: FontWeight.w600)),
                      TextButton(onPressed: () {}, child: const Text('Ver todos'))
                    ]),
                    const SizedBox(height: 8),
                    ...ultimosRegistros.map((r) {
                      final ts = r['capturado_en']?.toString() ?? '';
                      return RegistroItem(usuarioId: r['usuario_id']?.toString() ?? 'Usuario', timestamp: ts, fotoUrl: r['foto_url']?.toString());
                    }).toList(),
                  ]),
                ),
        ),
      ],
    );
  }
}
