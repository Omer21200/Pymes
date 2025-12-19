import 'package:flutter/material.dart';
import '../../../service/supabase_service.dart';
import '../../../theme.dart';

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
    if (_horario == null) {
      return Text('No hay horarios definidos para este departamento.', style: AppTextStyles.smallLabel);
    }

    final horaEntradaRaw = _horario!['hora_entrada'] as String? ?? '';
    final horaSalidaRaw = _horario!['hora_salida'] as String? ?? '';

    String _formatHora(String raw) {
      try {
        final d = DateTime.parse(raw);
        return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        if (raw.contains(':')) return raw.split(':').sublist(0,2).join(':');
        return raw.isEmpty ? '--:--' : raw;
      }
    }

    final horaEntrada = _formatHora(horaEntradaRaw);
    final horaSalida = _formatHora(horaSalidaRaw);
    final tolerancia = _horario!['tolerancia_entrada_minutos']?.toString() ?? '-';

    final dias = <String>[];
    if ((_horario!['lunes'] ?? false) == true) dias.add('Lun');
    if ((_horario!['martes'] ?? false) == true) dias.add('Mar');
    if ((_horario!['miercoles'] ?? false) == true) dias.add('Mié');
    if ((_horario!['jueves'] ?? false) == true) dias.add('Jue');
    if ((_horario!['viernes'] ?? false) == true) dias.add('Vie');
    if ((_horario!['sabado'] ?? false) == true) dias.add('Sáb');
    if ((_horario!['domingo'] ?? false) == true) dias.add('Dom');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Horario', style: AppTextStyles.smallLabel.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('$horaEntrada - $horaSalida', style: AppTextStyles.smallLabel.copyWith(color: AppColors.mutedGray)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: dias.isEmpty
                    ? Text('Días: Ninguno', style: AppTextStyles.smallLabel)
                    : Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: dias
                            .map((d) => Chip(
                                  label: Text(d, style: AppTextStyles.smallLabel.copyWith(color: Colors.white)),
                                  backgroundColor: AppColors.primary.withOpacity(0.95),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                ))
                            .toList(),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.timer, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Tolerancia: ', style: AppTextStyles.smallLabel.copyWith(fontWeight: FontWeight.w600)),
              Text('$tolerancia minutos', style: AppTextStyles.smallLabel.copyWith(color: AppColors.mutedGray)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!, style: AppTextStyles.smallLabel.copyWith(color: AppColors.brandRedAlt)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _departamento?['nombre'] ?? 'Departamento',
                  style: AppTextStyles.largeTitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if ((_departamento?['descripcion'] as String?)?.isNotEmpty ?? false) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: AppDecorations.card,
              child: Text(_departamento!['descripcion'], style: AppTextStyles.smallLabel),
            ),
            const SizedBox(height: 12),
          ],

          Text('Horarios', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 8),
          _buildHorario(),
        ],
      ),
    );
  }
}
