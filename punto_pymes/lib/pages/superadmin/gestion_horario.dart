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
      _toleranciaController.text = (data['tolerancia_entrada_minutos'] ?? 10).toString();
    });
  }

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Future<void> _selectTime(BuildContext context, {required bool isEntrada}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isEntrada ? _horaEntrada : _horaSalida,
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
        horaEntrada: '${_horaEntrada.hour.toString().padLeft(2, '0')}:${_horaEntrada.minute.toString().padLeft(2, '0')}:00',
        horaSalida: '${_horaSalida.hour.toString().padLeft(2, '0')}:${_horaSalida.minute.toString().padLeft(2, '0')}:00',
        tolerancia: tolerancia,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Horario guardado'), backgroundColor: Colors.green));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SuperadminHeader(showBack: true, onBack: () => Navigator.of(context).pop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Días Laborables', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ..._dias.keys.map((dia) => CheckboxListTile(
                          title: Text(dia.substring(0, 1).toUpperCase() + dia.substring(1)),
                          value: _dias[dia],
                          onChanged: (bool? value) {
                            setState(() => _dias[dia] = value!);
                          },
                        )),
                    const SizedBox(height: 20),
                    const Text('Horas de Trabajo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ListTile(
                      title: const Text('Hora de Entrada'),
                      trailing: Text(_horaEntrada.format(context)),
                      onTap: () => _selectTime(context, isEntrada: true),
                    ),
                    ListTile(
                      title: const Text('Hora de Salida'),
                      trailing: Text(_horaSalida.format(context)),
                      onTap: () => _selectTime(context, isEntrada: false),
                    ),
                    const SizedBox(height: 20),
                    const Text('Tolerancia', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    TextField(
                      controller: _toleranciaController,
                      decoration: const InputDecoration(labelText: 'Minutos de tolerancia para la entrada'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _guardarHorario,
                      child: _isSaving ? const CircularProgressIndicator() : const Text('Guardar Horario'),
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
