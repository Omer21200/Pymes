import 'package:flutter/material.dart';
import '../../../service/supabase_service.dart';

class DepartamentoPage extends StatefulWidget {
  const DepartamentoPage({super.key});

  @override
  State<DepartamentoPage> createState() => _DepartamentoPageState();
}

class _DepartamentoPageState extends State<DepartamentoPage> {
  Map<String, dynamic>? _departamento;
  Map<String, dynamic>? _horario;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDepartamento();
  }

  Future<void> _loadDepartamento() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final empleado = await SupabaseService.instance.getEmpleadoActual();
      final deptoId = empleado?['empleado_raw']?['departamento_id'] as String? ?? empleado?['profile_raw']?['departamento_id'] as String?;
      if (deptoId == null) {
        setState(() {
          _error = 'No perteneces a ningún departamento.';
          _loading = false;
        });
        return;
      }

      final depto = await SupabaseService.instance.getDepartamentoById(deptoId);
      final horario = await SupabaseService.instance.getHorarioPorDepartamento(deptoId);

      setState(() {
        _departamento = depto == null ? null : Map<String, dynamic>.from(depto as Map);
        _horario = horario == null ? null : Map<String, dynamic>.from(horario as Map);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error cargando departamento: $e';
        _loading = false;
      });
    }
  }

  Widget _buildHorario() {
    if (_horario == null) return const Text('No hay horarios definidos para este departamento.');

    final horaEntrada = _horario!['hora_entrada'] as String? ?? '--:--:--';
    final horaSalida = _horario!['hora_salida'] as String? ?? '--:--:--';
    final tolerancia = _horario!['tolerancia_entrada_minutos']?.toString() ?? '-';

    final dias = <String>[];
    if (_horario!['lunes'] == true) dias.add('Lun');
    if (_horario!['martes'] == true) dias.add('Mar');
    if (_horario!['miercoles'] == true) dias.add('Mié');
    if (_horario!['jueves'] == true) dias.add('Jue');
    if (_horario!['viernes'] == true) dias.add('Vie');
    if (_horario!['sabado'] == true) dias.add('Sáb');
    if (_horario!['domingo'] == true) dias.add('Dom');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.access_time, size: 18, color: Color(0xFF333333)),
            const SizedBox(width: 8),
            Text('Horario: $horaEntrada - $horaSalida', style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.calendar_today, size: 18, color: Color(0xFF333333)),
            const SizedBox(width: 8),
            Text('Días: ${dias.isEmpty ? 'Ninguno' : dias.join(', ')}'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.timer, size: 18, color: Color(0xFF333333)),
            const SizedBox(width: 8),
            Text('Tolerancia: $tolerancia minutos'),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _departamento?['nombre'] ?? 'Departamento',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if ((_departamento?['descripcion'] as String?)?.isNotEmpty ?? false) ...[
            Text(_departamento!['descripcion']),
            const SizedBox(height: 12),
          ],
          const Text('Horarios', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _buildHorario(),
        ],
      ),
    );
  }
}
