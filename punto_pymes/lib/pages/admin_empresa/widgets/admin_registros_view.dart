import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'dart:convert';
import 'dart:async';
import 'dart:math';

import '../../../service/supabase_service.dart';

class AdminRegistrosView extends StatefulWidget {
  const AdminRegistrosView({super.key});

  @override
  State<AdminRegistrosView> createState() => _AdminRegistrosViewState();
}

class _AdminRegistrosViewState extends State<AdminRegistrosView> {
  bool _loading = true;
  String? _error;
  DateTime? _desde;
  DateTime? _hasta;
  int? _weekdayFilter;
  List<Map<String, dynamic>> _registros = [];
  gmaps.GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _loadRegistros();
  }

  Future<void> _loadRegistros() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await SupabaseService.instance.getRegistrosEmpresa(
        desde: _desde,
        hasta: _hasta,
      );
      if (!mounted) return;
      setState(() {
        _registros = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _desde = null;
      _hasta = null;
      _weekdayFilter = null;
    });
    _loadRegistros();
  }

  Future<void> _pickDesde() async {
    final now = DateTime.now();
    final initialDate = _desde ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );

    if (picked != null) {
      setState(() {
        _desde = picked;
        _hasta = picked;
      });
      await _loadRegistros();
    }
  }

  int _countEstado(String estado) {
    final needle = estado.toLowerCase();
    return _registros
        .where((r) => (r['estado']?.toString().toLowerCase() ?? '') == needle)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_loading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ocurrio un error al cargar los registros.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loadRegistros,
            child: const Text('Reintentar'),
          ),
        ],
      );
    } else if (_registros.isEmpty) {
      content = _buildEmptyState();
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsRow(),
          const SizedBox(height: 14),
          _buildRegistrosList(),
        ],
      );
    }

    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(0),
        child: SizedBox.shrink(),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadRegistros,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                _buildFilterSection(),
                const SizedBox(height: 16),
                content,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.only(left: 4, right: 4, top: 4, bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Registros',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Aqui se muestran los registros de asistencia de tu equipo.',
            style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    final dias = [
      {'label': 'Lunes', 'weekday': 1},
      {'label': 'Martes', 'weekday': 2},
      {'label': 'Miercoles', 'weekday': 3},
      {'label': 'Jueves', 'weekday': 4},
      {'label': 'Viernes', 'weekday': 5},
      {'label': 'Sabado', 'weekday': 6},
    ];
    const accent = Color(0xFFB55D5D);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Filtros',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed:
                  (_desde == null && _hasta == null && _weekdayFilter == null)
                  ? null
                  : _clearFilters,
              icon: const Icon(Icons.clear),
              label: const Text('Limpiar'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: dias.map((d) {
            final selected = _weekdayFilter == d['weekday'];
            return ChoiceChip(
              label: Text(d['label'] as String),
              selected: selected,
              backgroundColor: Colors.white,
              selectedColor: accent.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: selected ? accent : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide(
                color: selected
                    ? accent.withValues(alpha: 0.4)
                    : Colors.grey.withValues(alpha: 0.5),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              onSelected: (_) {
                setState(() {
                  _weekdayFilter = _weekdayFilter == d['weekday']
                      ? null
                      : d['weekday'] as int;
                });
                _loadRegistros();
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: _pickDesde,
          icon: Icon(Icons.event, color: accent),
          label: Text(
            _desde == null
                ? 'Elegir dia'
                : _formatDate(_desde!.toIso8601String()),
            style: TextStyle(color: accent, fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            side: BorderSide(color: accent.withValues(alpha: 0.5), width: 1.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    final total = _registros.length;
    final aTiempo = _countEstado('a tiempo');
    final tarde = _countEstado('tarde');
    final otros = total - aTiempo - tarde;

    // Color tokens inspired by provided designs
    const totalColor = Color(0xFF2F9BFF);
    const totalBg = Color(0xFFE8F5FF);
    const aTiempoColor = Color(0xFF2DB26A);
    const aTiempoBg = Color(0xFFEFF9F1);
    const tardeColor = Color(0xFFF39C12);
    const tardeBg = Color(0xFFFFF6ED);
    const otrosColor = Color(0xFF8E959A);
    const otrosBg = Color(0xFFF5F7F9);

    Widget pill(
      String label,
      int value,
      Color color,
      Color bgColor,
      IconData icon,
    ) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Text(
              value.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: pill(
                'Total',
                total,
                totalColor,
                totalBg,
                Icons.list_alt_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              fit: FlexFit.loose,
              child: pill(
                'A tiempo',
                aTiempo,
                aTiempoColor,
                aTiempoBg,
                Icons.check_circle_outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: pill(
                'Tarde',
                tarde,
                tardeColor,
                tardeBg,
                Icons.access_time,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              fit: FlexFit.loose,
              child: pill(
                'Otros',
                otros,
                otrosColor,
                otrosBg,
                Icons.info_outline,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRegistrosList() {
    return ListView.builder(
      itemCount: _registros.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final r = _registros[index];
        final empleado = r['empleado_nombre']?.toString() ?? 'Sin nombre';
        final dep = r['departamento']?.toString() ?? '';
        final fecha = _formatDate(r['fecha']?.toString());
        final horaEntrada = _formatTime(r['hora_entrada']?.toString());
        final horaSalida = _formatTime(r['hora_salida']?.toString());
        final estado = r['estado']?.toString() ?? 'Pendiente';
        final creado = _shortTime(r['created_at']?.toString());
        // Modern card: left accent, soft shadow, compact layout, responsive text
        final accent = _estadoColor(estado);
        return Material(
          color: Colors.white,
          elevation: 0,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _showRegistroDetails(r),
              child: Row(
                children: [
                  // colored accent bar
                  Container(
                    width: 6,
                    height: 92,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(14),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: accent.withValues(alpha: 0.14),
                                child: Text(
                                  empleado.isNotEmpty
                                      ? empleado[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: accent,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            empleado,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // small status pill
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: accent.withValues(
                                              alpha: 0.14,
                                            ),
                                            border: Border.all(
                                              color: accent.withValues(
                                                alpha: 0.2,
                                              ),
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            estado,
                                            style: TextStyle(
                                              color: accent,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (dep.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                          dep,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  fecha,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Entrada $horaEntrada',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                '•',
                                style: TextStyle(color: Colors.black38),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Salida $horaSalida',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (creado.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 13,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Creado $creado',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 20,
                                  color: Colors.black38,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.assignment_turned_in_outlined,
            size: 60,
            color: Colors.grey,
          ),
          SizedBox(height: 12),
          Text(
            'No hay registros para mostrar',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6),
          Text(
            'Prueba ajustando el rango de fechas o vuelve a intentarlo mas tarde.',
            style: TextStyle(color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _showRegistroDetails(Map<String, dynamic> r) async {
    final empleado = r['empleado_nombre']?.toString() ?? 'Sin nombre';
    final fecha = _formatDate(r['fecha']?.toString());
    final entrada = _formatTime(r['hora_entrada']?.toString());
    final salida = _formatTime(r['hora_salida']?.toString());
    final estado = r['estado']?.toString() ?? 'Pendiente';
    String observacion = _normalizeObservacionValue(r['observacion']);
    final dep = r['departamento']?.toString() ?? 'Sin departamento';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        const headerBg = Colors.white;
        const accent = Color(0xFF4650DD);
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> editObservacion() async {
              final id = r['id']?.toString();
              if (id == null || id.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No se pudo editar: id faltante'),
                  ),
                );
                return;
              }

              final controller = TextEditingController(
                text: observacion == 'Sin observacion' ? '' : observacion,
              );
              final newValue = await showDialog<String>(
                context: context,
                builder: (ctx) {
                  return AlertDialog(
                    title: const Text('Editar observacion'),
                    content: TextField(
                      controller: controller,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Escribe la observacion',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () =>
                            Navigator.of(ctx).pop(controller.text.trim()),
                        child: const Text('Guardar'),
                      ),
                    ],
                  );
                },
              );

              if (newValue == null) return;
              final cleaned = newValue.trim();
              if (cleaned.isEmpty) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Escribe una observacion antes de guardar'),
                    ),
                  );
                }
                return;
              }
              final ok = await SupabaseService.instance
                  .updateObservacionAsistencia(
                    id: id,
                    observacion: cleaned,
                    empleadoId: r['empleado_id']?.toString(),
                  );
              if (!context.mounted) return;
              if (!ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No se pudo guardar la observacion'),
                  ),
                );
                return;
              }

              setModalState(() {
                observacion = _normalizeObservacionValue(cleaned);
                r['observacion'] = cleaned;
              });
              await _loadRegistros();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Observacion actualizada')),
              );
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomInset),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.white, Color(0xFFF8F9FB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0xFFE5E7EB)),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 14,
                          ),
                          decoration: BoxDecoration(
                            color: headerBg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              const Expanded(
                                child: Text(
                                  'Detalle del registro',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                fit: FlexFit.loose,
                                child: Chip(
                                  label: Text(
                                    estado,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  backgroundColor: _estadoColor(
                                    estado,
                                  ).withValues(alpha: 0.15),
                                  labelStyle: TextStyle(
                                    color: _estadoColor(estado),
                                    fontWeight: FontWeight.w700,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _detailRow('Empleado', empleado, accent: accent),
                        _detailRow('Departamento', dep, accent: accent),
                        _detailRow('Fecha', fecha, accent: accent),
                        _detailRow('Entrada', entrada, accent: accent),
                        _detailRow('Salida', salida, accent: accent),
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.15),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1A000000),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Observacion',
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      (observacion.isEmpty ||
                                              observacion == 'Sin observacion')
                                          ? 'Sin observacion'
                                          : observacion,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color:
                                            (observacion.isEmpty ||
                                                observacion ==
                                                    'Sin observacion')
                                            ? Colors.black45
                                            : Colors.black87,
                                        height: 1.28,
                                      ),
                                      textHeightBehavior:
                                          const TextHeightBehavior(
                                            applyHeightToFirstAscent: false,
                                          ),
                                      softWrap: true,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                height: 38,
                                width: 38,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    shape: const CircleBorder(),
                                    side: BorderSide(
                                      color: accent.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  onPressed: editObservacion,
                                  child: Icon(
                                    Icons.edit,
                                    size: 18,
                                    color: accent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _detailRow(
                          'Creado',
                          _shortTime(r['created_at']?.toString()),
                          accent: accent,
                        ),
                        const SizedBox(height: 12),
                        // Map section (company polygon + markers)
                        _buildMapSection(r),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cerrar'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(
    String label,
    String value, {
    Color accent = Colors.blueGrey,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.12)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Color _estadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'a tiempo':
        return Colors.green;
      case 'tarde':
        return Colors.orange;
      case 'ausente':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '--';
    try {
      final dt = DateTime.parse(iso);
      final d = dt.toLocal();
      final m = d.month.toString().padLeft(2, '0');
      final day = d.day.toString().padLeft(2, '0');
      return '${d.year}-$m-$day';
    } catch (_) {
      return iso.split('T').first;
    }
  }

  String _formatTime(String? value) {
    if (value == null || value.isEmpty) return '--:--';
    final parts = value.split(':');
    if (parts.length < 2) return value;
    final h = parts[0].padLeft(2, '0');
    final m = parts[1].padLeft(2, '0');
    return '$h:$m';
  }

  String _shortTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final date = _formatDate(dt.toIso8601String());
      final time = _formatTime(dt.toIso8601String().split('T').last);
      return '$date $time';
    } catch (_) {
      return iso;
    }
  }

  String _normalizeObservacionValue(dynamic raw) {
    if (raw == null) return 'Sin observacion';
    final s = raw.toString().trim();
    if (s.isEmpty || s.toLowerCase() == 'null') return 'Sin observacion';
    return s;
  }

  Widget _buildMapSection(Map<String, dynamic> r) {
    double? tryParse(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v.trim().replaceAll(',', '.'));
      return null;
    }

    List<gmaps.LatLng> circlePoints(
      double lat,
      double lng,
      double radiusMeters, {
      int segments = 36,
    }) {
      final pts = <gmaps.LatLng>[];
      final latRad = lat * pi / 180.0;
      final metersPerDegLat = 111320.0;
      final metersPerDegLng = 111320.0 * cos(latRad);
      for (var i = 0; i < segments; i++) {
        final ang = 2 * pi * i / segments;
        final dLat = (radiusMeters * sin(ang)) / metersPerDegLat;
        final dLng = (radiusMeters * cos(ang)) / metersPerDegLng;
        pts.add(gmaps.LatLng(lat + dLat, lng + dLng));
      }
      return pts;
    }

    // possible key variants for employee/company coordinates
    final empLatKeys = ['empleado_lat', 'latitud', 'lat', 'latitude', 'y'];
    final empLngKeys = ['empleado_lng', 'longitud', 'lng', 'longitude', 'x'];
    final compLatKeys = [
      'empresa_lat',
      'empresa_latitud',
      'company_lat',
      'company_latitude',
    ];
    final compLngKeys = [
      'empresa_lng',
      'empresa_longitud',
      'company_lng',
      'company_longitude',
    ];

    double? empLat, empLng, compLat, compLng;
    for (final k in empLatKeys) {
      if (r.containsKey(k) && empLat == null) empLat = tryParse(r[k]);
    }
    for (final k in empLngKeys) {
      if (r.containsKey(k) && empLng == null) empLng = tryParse(r[k]);
    }
    for (final k in compLatKeys) {
      if (r.containsKey(k) && compLat == null) compLat = tryParse(r[k]);
    }
    for (final k in compLngKeys) {
      if (r.containsKey(k) && compLng == null) compLng = tryParse(r[k]);
    }

    // Prefer direct empleado lat/lng fields if present (some registros put them at top-level)
    if ((empLat == null || empLng == null) &&
        (r.containsKey('latitud') ||
            r.containsKey('longitud') ||
            r.containsKey('lat') ||
            r.containsKey('lng'))) {
      empLat ??= tryParse(r['latitud'] ?? r['lat'] ?? r['latitude']);
      empLng ??= tryParse(r['longitud'] ?? r['lng'] ?? r['longitude']);
    }

    // Also check nested employee maps (some registros store empleado info inside 'empleado' or 'empleado_raw')
    final nestedKeys = [
      'empleado',
      'empleado_raw',
      'empleado_data',
      'user',
      'usuario',
      'profile',
    ];
    for (final nk in nestedKeys) {
      if (empLat != null && empLng != null) break;
      final nested = r[nk];
      if (nested is Map<String, dynamic>) {
        empLat ??= tryParse(
          nested['latitud'] ?? nested['lat'] ?? nested['latitude'],
        );
        empLng ??= tryParse(
          nested['longitud'] ?? nested['lng'] ?? nested['longitude'],
        );
      }
    }

    // Also try common nested location objects
    if ((empLat == null || empLng == null) && r.containsKey('location')) {
      final loc = r['location'];
      if (loc is Map<String, dynamic>) {
        empLat ??= tryParse(loc['lat'] ?? loc['latitude']);
        empLng ??= tryParse(loc['lng'] ?? loc['longitude']);
      }
    }

    // Debug print parsed employee coords
    try {
      debugPrint(
        'Registro parsed coords empLat=$empLat empLng=$empLng id=${r['id'] ?? r['empleado_id'] ?? ''}',
      );
    } catch (_) {}

    final List<gmaps.LatLng> polyPts = [];
    try {
      final polyCandidate =
          r['empresa_polygon'] ??
          r['poligono'] ??
          r['empresa_poligono'] ??
          r['polygon'];
      if (polyCandidate is String) {
        final decoded = polyCandidate.isNotEmpty
            ? jsonDecode(polyCandidate)
            : null;
        if (decoded is List) {
          for (final p in decoded) {
            if (p is Map &&
                (p['lat'] != null || p['latitude'] != null) &&
                (p['lng'] != null || p['longitude'] != null)) {
              final la = tryParse(p['lat'] ?? p['latitude']);
              final ln = tryParse(p['lng'] ?? p['longitude']);
              if (la != null && ln != null) polyPts.add(gmaps.LatLng(la, ln));
            }
          }
        }
      } else if (polyCandidate is List) {
        for (final p in polyCandidate) {
          if (p is Map) {
            final la = tryParse(p['lat'] ?? p['latitude'] ?? p['latitud']);
            final ln = tryParse(p['lng'] ?? p['longitude'] ?? p['longitud']);
            if (la != null && ln != null) polyPts.add(gmaps.LatLng(la, ln));
          }
        }
      }
    } catch (_) {}

    final gmaps.LatLng? empPoint = (empLat != null && empLng != null)
        ? gmaps.LatLng(empLat, empLng)
        : null;
    final gmaps.LatLng? compPoint = (compLat != null && compLng != null)
        ? gmaps.LatLng(compLat, compLng)
        : null;

    // If no polygon and no company coords, try fetching company info from service
    Future<Map<String, dynamic>?> maybeFetchEmpresa() async {
      try {
        // Prefer empresa_id from registro if present
        final eid = r['empresa_id']?.toString() ?? r['empresa']?.toString();
        if (eid != null && eid.isNotEmpty) {
          final ed = await SupabaseService.instance.getEmpresaById(eid);
          return ed;
        }
        // Fallback: try to get current empleado -> empresa id
        final me = await SupabaseService.instance.getEmpleadoActual();
        final empresaId = me?['empresa_id']?.toString();
        if (empresaId != null) {
          return await SupabaseService.instance.getEmpresaById(empresaId);
        }
      } catch (_) {}
      return null;
    }

    if (polyPts.isEmpty) {
      // Try to fetch empresa to at least show company polygon/coords when there's no polygon
      return FutureBuilder<Map<String, dynamic>?>(
        future: maybeFetchEmpresa(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final empresa = snap.data;
          double? clat = compLat, clng = compLng;
          final List<gmaps.LatLng> fromEmpresaPoly = [];
          if (empresa != null) {
            clat ??= tryParse(
              empresa['latitud'] ?? empresa['lat'] ?? empresa['latitude'],
            );
            clng ??= tryParse(
              empresa['longitud'] ?? empresa['lng'] ?? empresa['longitude'],
            );
            final poly =
                empresa['polygon'] ??
                empresa['poligono'] ??
                empresa['empresa_polygon'];
            if (poly is String) {
              try {
                final decoded = jsonDecode(poly);
                if (decoded is List) {
                  for (final p in decoded) {
                    final la = tryParse(
                      p['lat'] ?? p['latitude'] ?? p['latitud'],
                    );
                    final ln = tryParse(
                      p['lng'] ?? p['longitude'] ?? p['longitud'],
                    );
                    if (la != null && ln != null) {
                      fromEmpresaPoly.add(gmaps.LatLng(la, ln));
                    }
                  }
                }
              } catch (_) {}
            } else if (poly is List) {
              for (final p in poly) {
                final la = tryParse(p['lat'] ?? p['latitude'] ?? p['latitud']);
                final ln = tryParse(
                  p['lng'] ?? p['longitude'] ?? p['longitud'],
                );
                if (la != null && ln != null) {
                  fromEmpresaPoly.add(gmaps.LatLng(la, ln));
                }
              }
            }
          }

          final center =
              empPoint ??
              (clat != null && clng != null
                  ? gmaps.LatLng(clat, clng)
                  : (fromEmpresaPoly.isNotEmpty
                        ? fromEmpresaPoly.first
                        : const gmaps.LatLng(0, 0)));
          final markers = <gmaps.Marker>{
            if (clat != null && clng != null)
              gmaps.Marker(
                markerId: const gmaps.MarkerId('company'),
                position: gmaps.LatLng(clat, clng),
                icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
                  gmaps.BitmapDescriptor.hueRed,
                ),
              ),
            if (empPoint != null)
              gmaps.Marker(
                markerId: const gmaps.MarkerId('employee'),
                position: empPoint,
                icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
                  gmaps.BitmapDescriptor.hueAzure,
                ),
              ),
          };
          // If empresa doesn't have an explicit polygon but has center + radius, build a circular polygon
          if (fromEmpresaPoly.isEmpty && clat != null && clng != null) {
            final rr = tryParse(
              empresa?['radius_m'] ??
                  empresa?['radius'] ??
                  empresa?['radius_meters'],
            );
            if (rr != null && rr > 0) {
              fromEmpresaPoly.addAll(circlePoints(clat, clng, rr));
            }
          }
          final polygons = <gmaps.Polygon>{
            if (fromEmpresaPoly.isNotEmpty)
              gmaps.Polygon(
                polygonId: const gmaps.PolygonId('empresa_poly'),
                points: fromEmpresaPoly,
                fillColor: Colors.blue.withValues(alpha: 0.08),
                strokeWidth: 2,
                strokeColor: Colors.blue.withValues(alpha: 0.9),
              ),
          };

          final initial = gmaps.CameraPosition(target: center, zoom: 14);
          final mapWidget = SizedBox(
            height: 220,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  gmaps.GoogleMap(
                    initialCameraPosition: initial,
                    markers: markers,
                    polygons: polygons,
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    onMapCreated: (ctrl) async {
                      _mapController = ctrl;
                      final ctl = ctrl;
                      final allPoints = <gmaps.LatLng>[];
                      if (empPoint != null) {
                        allPoints.add(empPoint);
                      }
                      if (clat != null && clng != null) {
                        allPoints.add(gmaps.LatLng(clat, clng));
                      }
                      allPoints.addAll(fromEmpresaPoly);
                      if (allPoints.length >= 2) {
                        final minLat = allPoints
                            .map((p) => p.latitude)
                            .reduce(min);
                        final maxLat = allPoints
                            .map((p) => p.latitude)
                            .reduce(max);
                        final minLng = allPoints
                            .map((p) => p.longitude)
                            .reduce(min);
                        final maxLng = allPoints
                            .map((p) => p.longitude)
                            .reduce(max);
                        final bounds = gmaps.LatLngBounds(
                          southwest: gmaps.LatLng(minLat, minLng),
                          northeast: gmaps.LatLng(maxLat, maxLng),
                        );
                        try {
                          await ctl.animateCamera(
                            gmaps.CameraUpdate.newLatLngBounds(bounds, 50),
                          );
                        } catch (_) {}
                      } else if (allPoints.length == 1) {
                        try {
                          await ctl.animateCamera(
                            gmaps.CameraUpdate.newLatLngZoom(
                              allPoints.first,
                              16,
                            ),
                          );
                        } catch (_) {}
                      }
                    },
                    gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                      Factory<OneSequenceGestureRecognizer>(
                        () => EagerGestureRecognizer(),
                      ),
                    },
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  Icons.my_location,
                                  color: Theme.of(context).primaryColor,
                                ),
                                onPressed: () {
                                  final target =
                                      empPoint ??
                                      (clat != null && clng != null
                                          ? gmaps.LatLng(clat, clng)
                                          : null) ??
                                      (fromEmpresaPoly.isNotEmpty
                                          ? fromEmpresaPoly.first
                                          : null);
                                  if (target != null &&
                                      _mapController != null) {
                                    _mapController!.animateCamera(
                                      gmaps.CameraUpdate.newLatLngZoom(
                                        target,
                                        16,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  Icons.add,
                                  size: 20,
                                  color: Theme.of(context).primaryColor,
                                ),
                                onPressed: () {
                                  if (_mapController != null) {
                                    _mapController!.animateCamera(
                                      gmaps.CameraUpdate.zoomIn(),
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  Icons.remove,
                                  size: 20,
                                  color: Theme.of(context).primaryColor,
                                ),
                                onPressed: () {
                                  if (_mapController != null) {
                                    _mapController!.animateCamera(
                                      gmaps.CameraUpdate.zoomOut(),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );

          return mapWidget;
        },
      );
    }

    final center =
        empPoint ??
        compPoint ??
        (polyPts.isNotEmpty ? polyPts.first : const gmaps.LatLng(0, 0));
    final markers = <gmaps.Marker>{
      if (compPoint != null)
        gmaps.Marker(
          markerId: const gmaps.MarkerId('company'),
          position: compPoint,
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueRed,
          ),
        ),
      if (empPoint != null)
        gmaps.Marker(
          markerId: const gmaps.MarkerId('employee'),
          position: empPoint,
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueAzure,
          ),
        ),
    };
    final polygons = <gmaps.Polygon>{
      if (polyPts.isNotEmpty)
        gmaps.Polygon(
          polygonId: const gmaps.PolygonId('empresa_poly'),
          points: polyPts,
          fillColor: Colors.blue.withValues(alpha: 0.08),
          strokeWidth: 2,
          strokeColor: Colors.blue.withValues(alpha: 0.9),
        ),
    };

    final initial = gmaps.CameraPosition(target: center, zoom: 14);
    final mapWidget = SizedBox(
      height: 220,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            gmaps.GoogleMap(
              initialCameraPosition: initial,
              markers: markers,
              polygons: polygons,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              onMapCreated: (ctrl) async {
                _mapController = ctrl;
                final ctl = ctrl;
                final allPoints = <gmaps.LatLng>[];
                if (empPoint != null) {
                  allPoints.add(empPoint);
                }
                if (compPoint != null) {
                  allPoints.add(compPoint);
                }
                allPoints.addAll(polyPts);
                if (allPoints.length >= 2) {
                  final minLat = allPoints.map((p) => p.latitude).reduce(min);
                  final maxLat = allPoints.map((p) => p.latitude).reduce(max);
                  final minLng = allPoints.map((p) => p.longitude).reduce(min);
                  final maxLng = allPoints.map((p) => p.longitude).reduce(max);
                  final bounds = gmaps.LatLngBounds(
                    southwest: gmaps.LatLng(minLat, minLng),
                    northeast: gmaps.LatLng(maxLat, maxLng),
                  );
                  try {
                    await ctl.animateCamera(
                      gmaps.CameraUpdate.newLatLngBounds(bounds, 50),
                    );
                  } catch (_) {}
                } else if (allPoints.length == 1) {
                  try {
                    await ctl.animateCamera(
                      gmaps.CameraUpdate.newLatLngZoom(allPoints.first, 16),
                    );
                  } catch (_) {}
                }
              },
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<OneSequenceGestureRecognizer>(
                  () => EagerGestureRecognizer(),
                ),
              },
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 6),
                          ],
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.my_location,
                            color: Theme.of(context).primaryColor,
                          ),
                          onPressed: () {
                            final target =
                                empPoint ??
                                compPoint ??
                                (polyPts.isNotEmpty ? polyPts.first : null);
                            if (target != null && _mapController != null) {
                              _mapController!.animateCamera(
                                gmaps.CameraUpdate.newLatLngZoom(target, 16),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 6),
                          ],
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.add,
                            size: 20,
                            color: Theme.of(context).primaryColor,
                          ),
                          onPressed: () {
                            if (_mapController != null) {
                              _mapController!.animateCamera(
                                gmaps.CameraUpdate.zoomIn(),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 6),
                          ],
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.remove,
                            size: 20,
                            color: Theme.of(context).primaryColor,
                          ),
                          onPressed: () {
                            if (_mapController != null) {
                              _mapController!.animateCamera(
                                gmaps.CameraUpdate.zoomOut(),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return mapWidget;
  }
}
