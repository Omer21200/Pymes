import 'package:flutter/material.dart';
import '../../superadmin/gestion_horario.dart';
import '../../../service/supabase_service.dart';
import '../widgets/admin_empresa_header.dart';

class DepartamentoDetallePage extends StatefulWidget {
  final String departamentoId;
  final String departamentoNombre;

  const DepartamentoDetallePage({
    super.key,
    required this.departamentoId,
    required this.departamentoNombre,
  });

  @override
  State<DepartamentoDetallePage> createState() =>
      _DepartamentoDetallePageState();
}

class _DepartamentoDetallePageState extends State<DepartamentoDetallePage> {
  bool _loadingHorario = true;
  Map<String, dynamic>? _horario;
  bool _isEditing = false;
  bool _isSaving = false;
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchHorario();
    _fetchDepartamentoDetails();
  }

  Future<void> _fetchDepartamentoDetails() async {
    try {
      final dep = await SupabaseService.instance.getDepartamentoById(
        widget.departamentoId,
      );
      if (mounted && dep != null) {
        setState(() {
          _nombreController.text =
              dep['nombre']?.toString() ?? widget.departamentoNombre;
          _descripcionController.text = dep['descripcion']?.toString() ?? '';
        });
      } else if (mounted && dep == null) {
        // Fallback: use widget.departamentoNombre
        setState(() => _nombreController.text = widget.departamentoNombre);
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Error cargando departamento: $e');
      }
    }
  }

  Future<void> _fetchHorario() async {
    if (!mounted) return;
    setState(() => _loadingHorario = true);
    try {
      final data = await SupabaseService.instance.getHorarioPorDepartamento(
        widget.departamentoId,
      );
      if (mounted) {
        setState(() {
          _horario = data;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar el horario: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingHorario = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminEmpresaHeader(
              nombreAdmin: null,
              nombreEmpresa: null,
              onLogout: null,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _isEditing
                              ? TextField(
                                  controller: _nombreController,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'Nombre del departamento',
                                  ),
                                )
                              : Text(
                                  _nombreController.text.isNotEmpty
                                      ? _nombreController.text
                                      : widget.departamentoNombre,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                        ),
                        const SizedBox(width: 8),
                        if (!_isEditing)
                          IconButton(
                            onPressed: () {
                              setState(() => _isEditing = true);
                            },
                            icon: const Icon(Icons.edit),
                            tooltip: 'Editar',
                          ),
                        if (_isEditing) ...[
                          IconButton(
                            onPressed: _isSaving
                                ? null
                                : () async {
                                    await _saveDepartamento();
                                  },
                            icon: const Icon(Icons.save),
                            tooltip: 'Guardar',
                          ),
                          IconButton(
                            onPressed: _isSaving
                                ? null
                                : () {
                                    _fetchDepartamentoDetails();
                                    setState(() => _isEditing = false);
                                  },
                            icon: const Icon(Icons.cancel_outlined),
                            tooltip: 'Cancelar',
                          ),
                        ],
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: () {
                            if (mounted) Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.close),
                          tooltip: 'Cerrar',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _isEditing
                        ? TextField(
                            controller: _descripcionController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Descripción',
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(
                              _descripcionController.text.isNotEmpty
                                  ? _descripcionController.text
                                  : 'Sin descripción',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                    const SizedBox(height: 16),
                    Container(
                      // Fondo suave azul inspirado en las tarjetas del dashboard
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F0FF),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        'Horario del Departamento',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Días laborables, horas de entrada y salida de este departamento.',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final result = await Navigator.of(context)
                                        .push<bool>(
                                          MaterialPageRoute(
                                            builder: (_) => GestionHorarioPage(
                                              departamentoId:
                                                  widget.departamentoId,
                                              horarioInicial: _horario,
                                              showHeader: false,
                                              adminNombre:
                                                  widget.departamentoNombre,
                                              empresaNombre: null,
                                              onLogout: null,
                                            ),
                                          ),
                                        );
                                    if (result == true) {
                                      _fetchHorario();
                                    }
                                  },
                                  icon: const Icon(Icons.edit, size: 18),
                                  label: Text(
                                    _horario == null ? 'Crear' : 'Editar',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE2183D),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_loadingHorario)
                              const Center(child: CircularProgressIndicator())
                            else if (_horario == null)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Center(
                                  child: Text(
                                    'Aún no has configurado un horario para este departamento.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                ),
                              )
                            else
                              _buildHorarioDetails(),
                          ],
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

    final diasLaborables = dias.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .join(', ');

    const titleStyle = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    );

    const valueStyle = TextStyle(fontSize: 14, color: Colors.black87);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        const Text('Días Laborables', style: titleStyle),
        const SizedBox(height: 4),
        Text(
          diasLaborables.isNotEmpty ? diasLaborables : 'Ninguno',
          style: valueStyle,
        ),
        const SizedBox(height: 24),
        const Text('Hora de Entrada', style: titleStyle),
        const SizedBox(height: 4),
        Text(_horario!['hora_entrada'] ?? 'N/A', style: valueStyle),
        const SizedBox(height: 24),
        const Text('Hora de Salida', style: titleStyle),
        const SizedBox(height: 4),
        Text(_horario!['hora_salida'] ?? 'N/A', style: valueStyle),
        const SizedBox(height: 24),
        const Text('Tolerancia de Entrada', style: titleStyle),
        const SizedBox(height: 4),
        Text(
          '${_horario!["tolerancia_entrada_minutos"] ?? 0} minutos',
          style: valueStyle,
        ),
      ],
    );
  }

  Future<void> _saveDepartamento() async {
    if (!_isEditing) return;
    setState(() => _isSaving = true);
    try {
      final nombre = _nombreController.text.trim();
      final descripcion = _descripcionController.text.trim();
      await SupabaseService.instance.updateDepartamento(
        departamentoId: widget.departamentoId,
        nombre: nombre.isEmpty ? null : nombre,
        descripcion: descripcion.isEmpty ? null : descripcion,
      );
      if (mounted) {
        setState(() {
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Departamento actualizado'),
            backgroundColor: Colors.green,
          ),
        );
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
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }
}
