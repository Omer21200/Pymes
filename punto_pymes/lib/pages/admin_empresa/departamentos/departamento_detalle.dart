import 'package:flutter/material.dart';
import '../../superadmin/gestion_horario.dart';
import '../../../service/supabase_service.dart';
import '../widgets/admin_empresa_header.dart';

class DepartamentoDetallePage extends StatefulWidget {
  final String departamentoId;
  final String departamentoNombre;

  const DepartamentoDetallePage({super.key, required this.departamentoId, required this.departamentoNombre});

  @override
  State<DepartamentoDetallePage> createState() => _DepartamentoDetallePageState();
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
      final dep = await SupabaseService.instance.getDepartamentoById(widget.departamentoId);
      if (mounted && dep != null) {
        setState(() {
          _nombreController.text = dep['nombre']?.toString() ?? widget.departamentoNombre;
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
      final data = await SupabaseService.instance.getHorarioPorDepartamento(widget.departamentoId);
      if (mounted) {
        setState(() {
          _horario = data;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar el horario: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loadingHorario = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminEmpresaHeader(nombreAdmin: null, nombreEmpresa: null, onLogout: null),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _isEditing
                            ? TextField(
                                controller: _nombreController,
                                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Nombre del departamento'),
                              )
                            : Text(
                                _nombreController.text.isNotEmpty ? _nombreController.text : widget.departamentoNombre,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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
                                  // Guardar cambios
                                  await _saveDepartamento();
                                },
                          icon: const Icon(Icons.save),
                          tooltip: 'Guardar',
                        ),
                        IconButton(
                          onPressed: _isSaving
                              ? null
                              : () {
                                  // Cancelar edición: recargar valores originales
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
                          decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Descripción'),
                        )
                      : Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            _descripcionController.text.isNotEmpty ? _descripcionController.text : 'Sin descripción',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                ],
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Departamento actualizado'), backgroundColor: Colors.green));
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
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }
}
