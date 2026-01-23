import 'package:flutter/material.dart';

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

      var filtered = data;
      if (_weekdayFilter != null) {
        filtered = data.where((r) {
          final f = r['fecha']?.toString();
          final dt = f == null ? null : DateTime.tryParse(f);
          return dt?.weekday == _weekdayFilter;
        }).toList();
      }

      if (!mounted) return;
      setState(() {
        _registros = filtered;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al cargar registros: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _applyQuickRange(Duration duration) {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day);
    final start = end.subtract(duration);
    setState(() {
      _desde = start;
      _hasta = end;
    });
    _loadRegistros();
  }

  Future<void> _pickDesde() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _desde ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _desde = DateTime(picked.year, picked.month, picked.day);
      });
      await _loadRegistros();
    }
  }

  Future<void> _pickHasta() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _hasta ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _hasta = DateTime(picked.year, picked.month, picked.day);
      });
      await _loadRegistros();
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

  int _countEstado(String estadoBuscado) {
    return _registros.where((r) {
      final estado = (r['estado'] ?? '').toString().toLowerCase();
      return estado == estadoBuscado.toLowerCase();
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(0),
        child: SizedBox.shrink(),
      ),
      body: RefreshIndicator(onRefresh: _loadRegistros, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        padding: const EdgeInsets.only(top: 120),
        children: const [Center(child: CircularProgressIndicator())],
      );
    }

    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            _error!,
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _loadRegistros,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _buildHeaderCard(),
        const SizedBox(height: 12),
        _buildFilterSection(),
        const SizedBox(height: 16),
        _buildStatsRow(),
        const SizedBox(height: 16),
        _registros.isEmpty ? _buildEmptyState() : _buildRegistrosList(),
      ],
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 0,
      color: const Color(0xFFF2F6FB),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.18)),
      ),
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Registros de asistencia',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Consulta y filtra los registros de tu equipo.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Recargar',
              onPressed: _loadRegistros,
            ),
          ],
        ),
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

    Widget pill(String label, int value, Color color, IconData icon) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
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
          children: [
            Expanded(
              child: pill('Total', total, Colors.blue, Icons.list_alt_outlined),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: pill(
                'A tiempo',
                aTiempo,
                Colors.green,
                Icons.check_circle_outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: pill('Tarde', tarde, Colors.orange, Icons.access_time),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: pill('Otros', otros, Colors.grey, Icons.info_outline),
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
        final color = _estadoColor(estado);

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          color: const Color(0xFFF2F6FB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.withValues(alpha: 0.18)),
          ),
          shadowColor: Colors.black.withValues(alpha: 0.06),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showRegistroDetails(r),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: color.withValues(alpha: 0.12),
                        child: Text(
                          empleado.isNotEmpty ? empleado[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              empleado,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            if (dep.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  dep,
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          estado,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.black54,
                      ),
                      Text(
                        fecha,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.black54,
                      ),
                      Text('Entrada $horaEntrada'),
                      const Text('•'),
                      Text('Salida $horaSalida'),
                    ],
                  ),
                  if (creado.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 16,
                          color: Colors.black38,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Creado $creado',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
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
    final observacion = r['observacion']?.toString() ?? 'Sin observacion';
    final dep = r['departamento']?.toString() ?? 'Sin departamento';

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Detalle del registro',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Chip(
                    label: Text(estado),
                    backgroundColor: _estadoColor(
                      estado,
                    ).withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: _estadoColor(estado),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _detailRow('Empleado', empleado),
              _detailRow('Departamento', dep),
              _detailRow('Fecha', fecha),
              _detailRow('Entrada', entrada),
              _detailRow('Salida', salida),
              _detailRow('Observacion', observacion),
              _detailRow('Creado', _shortTime(r['created_at']?.toString())),
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
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
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

  bool _esHoy() {
    final today = DateTime.now();
    final hoy = DateTime(today.year, today.month, today.day);
    return _desde != null && _hasta != null && _desde == hoy && _hasta == hoy;
  }

  bool _esRangoDias(int dias) {
    if (_desde == null || _hasta == null) return false;
    final end = DateTime.now();
    final endDay = DateTime(end.year, end.month, end.day);
    final startDay = endDay.subtract(Duration(days: dias - 1));
    return _desde == startDay && _hasta == endDay;
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
}
