import 'package:flutter/material.dart';
import '../../service/supabase_service.dart';
import 'widgets/superadmin_header.dart';
import 'gestion_horario.dart';

class DepartamentoDetallePage extends StatefulWidget {
  final String departamentoId;
  final String departamentoNombre;

  const DepartamentoDetallePage({
    super.key,
    required this.departamentoId,
    required this.departamentoNombre,
  });

  @override
  State<DepartamentoDetallePage> createState() => _DepartamentoDetallePageState();
}

class _DepartamentoDetallePageState extends State<DepartamentoDetallePage> {
  bool _loadingHorario = true;
  Map<String, dynamic>? _horario;

  @override
  void initState() {
    super.initState();
    _fetchHorario();
  }

  Future<void> _fetchHorario() async {
    if (!mounted) return;
    setState(() => _loadingHorario = true);
    try {
      final data = await SupabaseService.instance.getHorarioPorDepartamento(widget.departamentoId);
      if (mounted) {
        setState(() {
          _horario = data;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar el horario: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingHorario = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SuperadminHeader(
              showBack: true,
              onBack: () => Navigator.of(context).pop(),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                widget.departamentoNombre,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Horario del Departamento',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.of(context).push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => GestionHorarioPage(
                                    departamentoId: widget.departamentoId,
                                    horarioInicial: _horario,
                                  ),
                                ),
                              );
                              if (result == true) {
                                _fetchHorario();
                              }
                            },
                            icon: const Icon(Icons.edit, size: 18),
                            label: Text(_horario == null ? 'Crear' : 'Editar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD92344),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _loadingHorario
                          ? const Center(child: CircularProgressIndicator())
                          : _horario == null
                              ? const Expanded(
                                  child: Center(
                                    child: Text('No hay un horario definido.'),
                                  ),
                                )
                              : Expanded(
                                  child: _buildHorarioDetails(),
                                ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHorarioDetails() {
    final dias = {
      'Lunes': _horario!['lunes'] as bool? ?? false,
      'Martes': _horario!['martes'] as bool? ?? false,
      'Miércoles': _horario!['miercoles'] as bool? ?? false,
      'Jueves': _horario!['jueves'] as bool? ?? false,
      'Viernes': _horario!['viernes'] as bool? ?? false,
      'Sábado': _horario!['sabado'] as bool? ?? false,
      'Domingo': _horario!['domingo'] as bool? ?? false,
    };

    final diasLaborables = dias.entries.where((e) => e.value).map((e) => e.key).join(', ');

    return ListView(
      children: [
        ListTile(title: const Text('Días Laborables'), subtitle: Text(diasLaborables.isNotEmpty ? diasLaborables : 'Ninguno')),
        ListTile(title: const Text('Hora de Entrada'), subtitle: Text(_horario!['hora_entrada'] ?? 'N/A')),
        ListTile(title: const Text('Hora de Salida'), subtitle: Text(_horario!['hora_salida'] ?? 'N/A')),
        ListTile(title: const Text('Tolerancia de Entrada'), subtitle: Text('${_horario!['tolerancia_entrada_minutos'] ?? 0} minutos')),
      ],
    );
  }
}
