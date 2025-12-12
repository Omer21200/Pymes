import 'package:flutter/material.dart';
import '../../service/supabase_service.dart';
import 'widgets/superadmin_header.dart';

class GestionHorarioPage extends StatefulWidget {
  final String departamentoId;
  final Map<String, dynamic>? horarioInicial;

  const GestionHorarioPage({
    super.key,
    required this.departamentoId,
    this.horarioInicial,
  });

  @override
  State<GestionHorarioPage> createState() => _GestionHorarioPageState();
}

class _GestionHorarioPageState extends State<GestionHorarioPage> {
  bool _isSaving = false;

  // Días de la semana
  final Map<String, bool> _dias = {
    'lunes': true,
    'martes': true,
    'miercoles': true,
    'jueves': true,
    'viernes': true,
    'sabado': false,
    'domingo': false,
  };

  // Controladores de tiempo y tolerancia
  TimeOfDay _horaEntrada = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _horaSalida = const TimeOfDay(hour: 17, minute: 0);
  final _toleranciaController = TextEditingController(text: '10');

  @override
  void initState() {
    super.initState();
    if (widget.horarioInicial != null) {
      _cargarHorario(widget.horarioInicial!);
    }
  }

  void _cargarHorario(Map<String, dynamic> data) {
    setState(() {
      _dias['lunes'] = data['lunes'] ?? true;
      _dias['martes'] = data['martes'] ?? true;
      _dias['miercoles'] = data['miercoles'] ?? true;
      _dias['jueves'] = data['jueves'] ?? true;
      _dias['viernes'] = data['viernes'] ?? true;
      _dias['sabado'] = data['sabado'] ?? false;
      _dias['domingo'] = data['domingo'] ?? false;

      _horaEntrada = _parseTime(data['hora_entrada'] ?? '08:00:00');
      _horaSalida = _parseTime(data['hora_salida'] ?? '17:00:00');
      _toleranciaController.text = (data['tolerancia_entrada_minutos'] ?? 10)
          .toString();
    });
  }

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Future<void> _selectTime(
    BuildContext context, {
    required bool isEntrada,
  }) async {
    const brandRed = Color(0xFFE2183D);
    const accentBlue = Color(0xFF3F51B5);

    final ThemeData baseTheme = Theme.of(context);

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isEntrada ? _horaEntrada : _horaSalida,
      builder: (ctx, child) {
        if (child == null) return const SizedBox.shrink();

        final ColorScheme scheme = baseTheme.colorScheme.copyWith(
          primary: brandRed,
          secondary: accentBlue,
          surface: Colors.white,
        );

        return Theme(
          data: baseTheme.copyWith(
            colorScheme: scheme,
            timePickerTheme: const TimePickerThemeData(
              dialHandColor: brandRed,
              dialBackgroundColor: Color(0xFFFFF0F3),
              hourMinuteColor: Color(0xFFFFE5EC),
              hourMinuteTextColor: Colors.black87,
            ),
          ),
          child: child,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isEntrada) {
          _horaEntrada = picked;
        } else {
          _horaSalida = picked;
        }
      });
    }
  }

  Future<void> _guardarHorario() async {
    setState(() => _isSaving = true);
    try {
      final tolerancia = int.tryParse(_toleranciaController.text) ?? 10;

      await SupabaseService.instance.upsertHorarioDepartamento(
        departamentoId: widget.departamentoId,
        lunes: _dias['lunes']!,
        martes: _dias['martes']!,
        miercoles: _dias['miercoles']!,
        jueves: _dias['jueves']!,
        viernes: _dias['viernes']!,
        sabado: _dias['sabado']!,
        domingo: _dias['domingo']!,
        horaEntrada:
            '${_horaEntrada.hour.toString().padLeft(2, '0')}:${_horaEntrada.minute.toString().padLeft(2, '0')}:00',
        horaSalida:
            '${_horaSalida.hour.toString().padLeft(2, '0')}:${_horaSalida.minute.toString().padLeft(2, '0')}:00',
        tolerancia: tolerancia,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Horario guardado'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color brandRed = Color(0xFFE2183D);
    const Color accentBlue = Color(0xFF3F51B5);
    const Color successGreen = Color(0xFF4CAF50);
    const Color surfaceSoft = Color(0xFFF5F6FA);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          children: [
            SuperadminHeader(
              showBack: true,
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 4),
                    const Text(
                      'Configura el horario de trabajo para este departamento.',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 20),

                    // Card: Días laborables
                    Container(
                      decoration: BoxDecoration(
                        color: surfaceSoft,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: accentBlue.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.event_available,
                                  color: accentBlue,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Días laborables',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Selecciona los días en los que este departamento trabaja.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._dias.keys.map((dia) {
                            final label =
                                dia.substring(0, 1).toUpperCase() +
                                dia.substring(1);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      label,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    borderRadius: BorderRadius.circular(6),
                                    onTap: () {
                                      setState(
                                        () =>
                                            _dias[dia] = !(_dias[dia] ?? false),
                                      );
                                    },
                                    child: Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: (_dias[dia] ?? false)
                                              ? successGreen
                                              : Colors.black54,
                                          width: 1,
                                        ),
                                        color: (_dias[dia] ?? false)
                                            ? successGreen
                                            : Colors.transparent,
                                      ),
                                      child: (_dias[dia] ?? false)
                                          ? const Icon(
                                              Icons.check,
                                              size: 16,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Card: Horas de trabajo
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: brandRed.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.access_time,
                                  color: brandRed,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Horas de trabajo',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Define la hora de entrada y salida para este horario.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Hora de Entrada'),
                            subtitle: const Text(
                              'Hora a la que inicia la jornada.',
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: surfaceSoft,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                _horaEntrada.format(context),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            onTap: () => _selectTime(context, isEntrada: true),
                          ),
                          const Divider(height: 12),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Hora de Salida'),
                            subtitle: const Text(
                              'Hora a la que termina la jornada.',
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: surfaceSoft,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                _horaSalida.format(context),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            onTap: () => _selectTime(context, isEntrada: false),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Card: Tolerancia
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: accentBlue.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.timer_outlined,
                                  color: accentBlue,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Tolerancia de entrada',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Minutos de margen para que el empleado marque su ingreso sin considerarlo tarde.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _toleranciaController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Minutos de tolerancia',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    Center(
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _guardarHorario,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            _isSaving ? 'Guardando...' : 'Guardar horario',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
