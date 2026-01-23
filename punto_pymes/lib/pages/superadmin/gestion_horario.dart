import 'package:flutter/material.dart';
import '../../service/supabase_service.dart';
import '../admin_empresa/widgets/admin_empresa_header.dart';
import 'widgets/superadmin_header.dart';

class GestionHorarioPage extends StatefulWidget {
  final String departamentoId;
  final Map<String, dynamic>? horarioInicial;
  final bool showHeader;
  final String? adminNombre;
  final String? empresaNombre;
  final VoidCallback? onLogout;

  const GestionHorarioPage({
    super.key,
    required this.departamentoId,
    this.horarioInicial,
    this.showHeader = true,
    this.adminNombre,
    this.empresaNombre,
    this.onLogout,
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
  TimeOfDay? _horaSalidaAlm;
  TimeOfDay? _horaRegresoAlm;
  final _toleranciaController = TextEditingController(text: '10');

  @override
  void initState() {
    super.initState();
    // If the caller passed an initial horario, load it immediately for snappy UI;
    // then always fetch the latest from the server to ensure we reflect persisted values
    // (prevents accidental overwrites when the passed object is stale).
    if (widget.horarioInicial != null) {
      _cargarHorario(widget.horarioInicial!);
    }
    _refreshHorarioFromServer();
  }

  Future<void> _refreshHorarioFromServer() async {
    try {
      final server = await SupabaseService.instance.getHorarioPorDepartamento(
        widget.departamentoId,
      );
      if (server != null) {
        _cargarHorario(server);
      }
    } catch (e) {
      // ignore — keep whatever is currently displayed; parent will show errors when appropriate
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
      // Load times safely if present and valid
      String? he = data['hora_entrada'] as String?;
      String? hs = data['hora_salida'] as String?;
      String? hSalidaAlm = data['hora_salida_almuerzo'] as String?;
      String? hRegresoAlm = data['hora_regreso_almuerzo'] as String?;

      final timePattern = RegExp(r'^\d{2}:\d{2}:\d{2}');
      if (he != null && he.isNotEmpty && timePattern.hasMatch(he)) {
        _horaEntrada = _parseTime(he);
      }
      if (hs != null && hs.isNotEmpty && timePattern.hasMatch(hs)) {
        _horaSalida = _parseTime(hs);
      }
      if (hSalidaAlm != null &&
          hSalidaAlm.isNotEmpty &&
          timePattern.hasMatch(hSalidaAlm)) {
        _horaSalidaAlm = _parseTime(hSalidaAlm);
      } else {
        _horaSalidaAlm = null;
      }
      if (hRegresoAlm != null &&
          hRegresoAlm.isNotEmpty &&
          timePattern.hasMatch(hRegresoAlm)) {
        _horaRegresoAlm = _parseTime(hRegresoAlm);
      } else {
        _horaRegresoAlm = null;
      }

      // Tolerancia
      final tol = data['tolerancia_entrada_minutos'];
      _toleranciaController.text = (tol is int)
          ? tol.toString()
          : (int.tryParse('${tol ?? 10}')?.toString() ?? '10');
    });
  }

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  int _timeOfDayToMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  TimeOfDay _minutesToTimeOfDay(int minutes) {
    final m = minutes.clamp(0, 23 * 60 + 59);
    return TimeOfDay(hour: m ~/ 60, minute: m % 60);
  }

  Future<void> _selectTime(
    BuildContext context, {
    String field =
        'entrada', // 'entrada' | 'salida' | 'salida_alm' | 'regreso_alm'
  }) async {
    const brandRed = Color(0xFFE2183D);
    const accentBlue = Color(0xFF3F51B5);

    final ThemeData baseTheme = Theme.of(context);

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: field == 'entrada'
          ? _horaEntrada
          : field == 'salida'
          ? _horaSalida
          : field == 'salida_alm'
          ? (_horaSalidaAlm ?? TimeOfDay(hour: 12, minute: 0))
          : (_horaRegresoAlm ?? TimeOfDay(hour: 13, minute: 0)),
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
        switch (field) {
          case 'entrada':
            _horaEntrada = picked;
            break;
          case 'salida':
            _horaSalida = picked;
            break;
          case 'salida_alm':
            _horaSalidaAlm = picked;
            break;
          case 'regreso_alm':
            _horaRegresoAlm = picked;
            break;
        }
      });

      // If user selected a day-end that conflicts with existing lunch times, clear them
      if (field == 'salida' && _horaSalidaAlm != null) {
        final salidaMin = _timeOfDayToMinutes(_horaSalida);
        final salidaAlmMin = _timeOfDayToMinutes(_horaSalidaAlm!);
        if (salidaAlmMin >= salidaMin) {
          setState(() {
            _horaSalidaAlm = null;
            _horaRegresoAlm = null;
          });
          if (mounted) {
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Se quitó la salida/regreso de comida porque coincide con la hora de salida.',
                ),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }

      // If user selected a lunch start that is at/after day-end, clear it and notify
      if (field == 'salida_alm' && _horaSalidaAlm != null) {
        final salidaMin = _timeOfDayToMinutes(_horaSalida);
        final salidaAlmMin = _timeOfDayToMinutes(_horaSalidaAlm!);
        if (salidaAlmMin >= salidaMin) {
          setState(() {
            _horaSalidaAlm = null;
            _horaRegresoAlm = null;
          });
          if (mounted) {
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'La "Salida a comer" no puede ser igual o posterior a la hora de salida; se ha limpiado.',
                ),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _guardarHorario() async {
    setState(() => _isSaving = true);
    try {
      final tolerancia = int.tryParse(_toleranciaController.text) ?? 10;

      // Validate lunch/time conflicts before saving
      _timeOfDayToMinutes(_horaEntrada);
      final salidaMin = _timeOfDayToMinutes(_horaSalida);
      final salidaAlmMin = _horaSalidaAlm != null
          ? _timeOfDayToMinutes(_horaSalidaAlm!)
          : null;
      final regresoAlmMin = _horaRegresoAlm != null
          ? _timeOfDayToMinutes(_horaRegresoAlm!)
          : null;

      // If lunch start is at or after end of day, prompt user for action
      if (salidaAlmMin != null && salidaAlmMin >= salidaMin) {
        final choice = await showDialog<int>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Conflicto de horario'),
            content: const Text(
              'La "Salida a comer" seleccionada ocurre al mismo tiempo o después de la "Hora de Salida" del día. ¿Qué deseas hacer?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(0),
                child: const Text('Quitar salida a comer'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(1),
                child: const Text('Ajustar hora de salida'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(2),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        );

        if (choice == 0) {
          setState(() {
            _horaSalidaAlm = null;
            _horaRegresoAlm = null;
          });
        } else if (choice == 1) {
          // If we have a regreso time, set salida after it; otherwise add 60 minutes after lunch start
          final newSalidaMin = (regresoAlmMin ?? (salidaAlmMin + 60));
          setState(() {
            _horaSalida = _minutesToTimeOfDay(newSalidaMin);
          });
        } else {
          // Cancel save
          if (mounted) setState(() => _isSaving = false);
          return;
        }
      }

      // Ensure regreso (return) is after salida_alm and not after end of day
      if (regresoAlmMin != null && salidaAlmMin != null) {
        if (regresoAlmMin <= salidaAlmMin) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'La hora de regreso debe ser posterior a la hora de salida a comer.',
                ),
                backgroundColor: Colors.red,
              ),
            );
            setState(() => _isSaving = false);
          }
          return;
        }
        if (regresoAlmMin > salidaMin) {
          final choice2 = await showDialog<int>(
            // ignore: use_build_context_synchronously
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Conflicto de horario'),
              content: const Text(
                'La hora de regreso de comer está después de la hora de salida del día. Puedes ajustar la hora de salida o quitar la hora de regreso.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(0),
                  child: const Text('Quitar regreso'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(1),
                  child: const Text('Ajustar hora de salida'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(2),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          );

          if (choice2 == 0) {
            setState(() => _horaRegresoAlm = null);
          } else if (choice2 == 1) {
            setState(() => _horaSalida = _minutesToTimeOfDay(regresoAlmMin));
          } else {
            if (mounted) setState(() => _isSaving = false);
            return;
          }
        }
      }

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
        horaSalidaAlmuerzo: _horaSalidaAlm != null
            ? '${_horaSalidaAlm!.hour.toString().padLeft(2, '0')}:${_horaSalidaAlm!.minute.toString().padLeft(2, '0')}:00'
            : null,
        horaRegresoAlmuerzo: _horaRegresoAlm != null
            ? '${_horaRegresoAlm!.hour.toString().padLeft(2, '0')}:${_horaRegresoAlm!.minute.toString().padLeft(2, '0')}:00'
            : null,
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
            if (widget.showHeader)
              SuperadminHeader(
                showBack: true,
                onBack: () => Navigator.of(context).pop(),
              )
            else
              AdminEmpresaHeader(
                nombreAdmin: widget.adminNombre ?? 'Admin Empresa',
                nombreEmpresa: widget.empresaNombre ?? 'Empresa',
                onLogout: widget.onLogout,
                showBack: false,
                onBack: null,
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!widget.showHeader)
                      Row(
                        children: [
                          Material(
                            color: const Color(0xFFE2183D),
                            shape: const CircleBorder(),
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                              tooltip: 'Regresar',
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Configura el horario de trabajo para este departamento.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    else
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
                            onTap: () => _selectTime(context, field: 'entrada'),
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
                            onTap: () => _selectTime(context, field: 'salida'),
                          ),
                          const Divider(height: 18),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Salida a comer'),
                            subtitle: const Text(
                              'Hora de inicio del descanso de comida.',
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
                                _horaSalidaAlm?.format(context) ?? '—',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            onTap: () =>
                                _selectTime(context, field: 'salida_alm'),
                          ),
                          const Divider(height: 12),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Regreso de comer'),
                            subtitle: const Text(
                              'Hora en la que finaliza el descanso de comida.',
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
                                _horaRegresoAlm?.format(context) ?? '—',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            onTap: () =>
                                _selectTime(context, field: 'regreso_alm'),
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
