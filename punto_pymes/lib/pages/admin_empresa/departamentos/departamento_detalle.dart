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
    const Color brandRed = Color(0xFFE2183D);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _iconChip(
                          icon: Icons.arrow_back,
                          tooltip: 'Regresar',
                          bgColor: Colors.grey.withValues(alpha: 0.12),
                          iconColor: Colors.grey.shade800,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _isEditing
                              ? TextField(
                                  controller: _nombreController,
                                  decoration: _styledInputDecoration(
                                    label: 'Nombre del departamento',
                                    accent: brandRed,
                                  ),
                                )
                              : Text(
                                  _nombreController.text.isNotEmpty
                                      ? _nombreController.text
                                      : widget.departamentoNombre,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 10),
                        if (!_isEditing)
                          _iconChip(
                            icon: Icons.edit,
                            tooltip: 'Editar',
                            bgColor: brandRed,
                            iconColor: Colors.white,
                            onTap: () {
                              setState(() => _isEditing = true);
                            },
                          ),
                        if (_isEditing) ...[
                          _iconChip(
                            icon: _isSaving ? Icons.hourglass_top : Icons.save,
                            tooltip: 'Guardar',
                            bgColor: brandRed.withValues(alpha: 0.1),
                            iconColor: brandRed,
                            onTap: _isSaving
                                ? null
                                : () async {
                                    await _saveDepartamento();
                                  },
                          ),
                          const SizedBox(width: 8),
                          _iconChip(
                            icon: Icons.close,
                            tooltip: 'Cancelar edición',
                            bgColor: Colors.grey.withValues(alpha: 0.12),
                            iconColor: Colors.grey.shade800,
                            onTap: _isSaving
                                ? null
                                : () {
                                    _fetchDepartamentoDetails();
                                    setState(() => _isEditing = false);
                                  },
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    _isEditing
                        ? TextField(
                            controller: _descripcionController,
                            maxLines: 3,
                            decoration: _styledInputDecoration(
                              label: 'Descripción',
                              accent: brandRed,
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
                      // Fondo azul muy suave para evitar saturación visual
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F7FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFCED6F3).withValues(alpha: 0.7),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
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
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFE2183D,
                                    ).withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.access_time,
                                    color: Color(0xFFE2183D),
                                  ),
                                ),
                                const SizedBox(width: 12),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow(
          title: 'Días Laborables',
          subtitle: 'Días activos para asistencia.',
          value: diasLaborables.isNotEmpty ? diasLaborables : 'Ninguno',
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, color: Color(0xFFE3E6EE)),
        const SizedBox(height: 12),
        _infoRow(
          title: 'Hora de Entrada',
          subtitle: 'Hora a la que inicia la jornada.',
          valueChip: _horario!['hora_entrada'] ?? 'N/A',
        ),
        const SizedBox(height: 12),
        _infoRow(
          title: 'Hora de Salida',
          subtitle: 'Hora a la que termina la jornada.',
          valueChip: _horario!['hora_salida'] ?? 'N/A',
        ),
        const SizedBox(height: 12),
        _infoRow(
          title: 'Tolerancia de Entrada',
          subtitle: 'Minutos ?e gracia para marcar.',
          valueChip: '${_horario!["tolerancia_entrada_minutos"] ?? 0} minutos',
        ),
      ],
    );
  }

  Widget _infoRow({
    required String title,
    required String subtitle,
    String? value,
    String? valueChip,
  }) {
    final bool stackedValue = value != null && valueChip == null;

    if (stackedValue) {
      // Usar layout vertical cuando queremos que el valor aparezca debajo del subtítulo
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        if (value != null)
          Flexible(
            fit: FlexFit.loose,
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        if (valueChip != null)
          Flexible(
            fit: FlexFit.loose,
            child: Align(
              alignment: Alignment.centerRight,
              child: _valueChip(valueChip),
            ),
          ),
      ],
    );
  }

  Widget _valueChip(String text) {
    return Container(
      margin: const EdgeInsets.only(left: 8, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFCED6F3).withValues(alpha: 0.7),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: Color(0xFF3C4259),
        ),
        overflow: TextOverflow.ellipsis,
      ),
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

  InputDecoration _styledInputDecoration({
    required String label,
    required Color accent,
  }) {
    const Color softFill = Color(0xFFFDFDFE);
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: softFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: accent, width: 1.6),
      ),
      labelStyle: const TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.w700,
      ),
      hintStyle: const TextStyle(color: Colors.black45),
    );
  }

  Widget _iconChip({
    required IconData icon,
    required String tooltip,
    required Color bgColor,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
      ),
    );
  }
}
