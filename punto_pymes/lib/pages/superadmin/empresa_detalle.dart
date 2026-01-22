import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:intl/intl.dart';
import '../../service/supabase_service.dart';
import '../../theme.dart';
import 'creacion_departamentos.dart';

class EmpresaDetallePage extends StatefulWidget {
  final String empresaId;
  final Map<String, dynamic>? initialEmpresa;

  const EmpresaDetallePage({
    super.key,
    required this.empresaId,
    this.initialEmpresa,
  });

  @override
  State<EmpresaDetallePage> createState() => _EmpresaDetallePageState();
}

class _EmpresaDetallePageState extends State<EmpresaDetallePage> {
  Map<String, dynamic>? _empresa;
  bool _loading = true;
  double? _lat;
  double? _lng;
  gmaps.GoogleMapController? _mapController;
  double _zoom = 15.0;
  // Inline edit state
  bool _editing = false;
  TextEditingController? _nombreCtrl;
  TextEditingController? _rucCtrl;
  TextEditingController? _telefonoCtrl;
  TextEditingController? _correoCtrl;
  TextEditingController? _direccionCtrl;
  TextEditingController? _radiusCtrl;
  double? _previewRadius;
  double? _editLat;
  double? _editLng;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmpresa != null) {
      _empresa = widget.initialEmpresa;
      _lat = _toDouble(_empresa?['latitud']);
      _lng = _toDouble(_empresa?['longitud']);
      _loading = false;
    }
    _fetch();
  }

  Future<void> _openEditNameDialog() async {
    if (_empresa == null) return;
    final nombreCtrl = TextEditingController(
      text: _empresa?['nombre']?.toString() ?? '',
    );
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Editar nombre'),
          content: TextField(
            controller: nombreCtrl,
            decoration: const InputDecoration(labelText: 'Nombre'),
          ),
          actions: [
            TextButton(
              onPressed: () => navigator.pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = nombreCtrl.text.trim();
                try {
                  final String? nombreParaGuardar = newName.isNotEmpty
                      ? newName
                      : null;
                  final updated = await SupabaseService.instance.updateEmpresa(
                    empresaId: widget.empresaId,
                    nombre: nombreParaGuardar,
                  );
                  if (!mounted) return;
                  setState(() {
                    _empresa = updated;
                  });
                  navigator.pop();
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error al guardar: $e')),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    nombreCtrl.dispose();
  }

  void _startEditing() {
    if (_empresa == null) return;
    setState(() {
      _editing = true;
      _nombreCtrl = TextEditingController(
        text: _empresa?['nombre']?.toString() ?? '',
      );
      _rucCtrl = TextEditingController(
        text: _empresa?['ruc']?.toString() ?? '',
      );
      _telefonoCtrl = TextEditingController(
        text: _empresa?['telefono']?.toString() ?? '',
      );
      _correoCtrl = TextEditingController(
        text: _empresa?['correo']?.toString() ?? '',
      );
      _direccionCtrl = TextEditingController(
        text: _empresa?['direccion']?.toString() ?? '',
      );
      _editLat = _lat;
      _editLng = _lng;
      // radius: try to read stored value (don't default here)
      double? readRadius() {
        final radiusCandidates = [
          'radius_m',
          'allowed_radius_m',
          'radio',
          'geofence_radius',
          'rango',
          'radius',
        ];
        for (final k in radiusCandidates) {
          final rv = _empresa?[k];
          if (rv != null) {
            if (rv is num) return rv.toDouble();
            final parsed = double.tryParse(rv.toString());
            if (parsed != null) return parsed;
          }
        }
        return null;
      }

      final r = readRadius();
      _radiusCtrl = TextEditingController(
        text: r != null ? r.toStringAsFixed(0) : '',
      );
      _previewRadius = r;
      _radiusCtrl!.addListener(_updatePreviewRadiusFromController);
    });
  }

  void _cancelEditing() {
    setState(() {
      _editing = false;
    });
    _nombreCtrl?.dispose();
    _rucCtrl?.dispose();
    _telefonoCtrl?.dispose();
    _correoCtrl?.dispose();
    _direccionCtrl?.dispose();
    if (_radiusCtrl != null) {
      _radiusCtrl!.removeListener(_updatePreviewRadiusFromController);
      _radiusCtrl!.dispose();
    }
    _nombreCtrl = null;
    _rucCtrl = null;
    _telefonoCtrl = null;
    _correoCtrl = null;
    _direccionCtrl = null;
    _editLat = null;
    _editLng = null;
    _radiusCtrl = null;
    _previewRadius = null;
  }

  Future<void> _saveEditing() async {
    if (!_editing) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final updated = await SupabaseService.instance.updateEmpresa(
        empresaId: widget.empresaId,
        nombre: (_nombreCtrl != null && _nombreCtrl!.text.trim().isNotEmpty)
            ? _nombreCtrl!.text.trim()
            : null,
        ruc: (_rucCtrl != null && _rucCtrl!.text.trim().isNotEmpty)
            ? _rucCtrl!.text.trim()
            : null,
        telefono:
            (_telefonoCtrl != null && _telefonoCtrl!.text.trim().isNotEmpty)
            ? _telefonoCtrl!.text.trim()
            : null,
        correo: (_correoCtrl != null && _correoCtrl!.text.trim().isNotEmpty)
            ? _correoCtrl!.text.trim()
            : null,
        direccion:
            (_direccionCtrl != null && _direccionCtrl!.text.trim().isNotEmpty)
            ? _direccionCtrl!.text.trim()
            : null,
        latitud: _editLat,
        longitud: _editLng,
        radiusMeters:
            (_radiusCtrl != null && _radiusCtrl!.text.trim().isNotEmpty)
            ? double.tryParse(_radiusCtrl!.text.trim())
            : null,
      );
      if (!mounted) return;
      setState(() {
        _empresa = updated;
        _lat = _toDouble(updated['latitud']);
        _lng = _toDouble(updated['longitud']);
        _editing = false;
      });
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    } finally {
      _nombreCtrl?.dispose();
      _rucCtrl?.dispose();
      _telefonoCtrl?.dispose();
      _correoCtrl?.dispose();
      _direccionCtrl?.dispose();
      _radiusCtrl?.dispose();
      _nombreCtrl = null;
      _rucCtrl = null;
      _telefonoCtrl = null;
      _correoCtrl = null;
      _direccionCtrl = null;
      _editLat = null;
      _editLng = null;
      _radiusCtrl = null;
    }
  }

  double? _toDouble(Object? v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  void _updatePreviewRadiusFromController() {
    if (_radiusCtrl == null) return;
    final txt = _radiusCtrl!.text.trim();
    final parsed = txt.isNotEmpty ? double.tryParse(txt) : null;
    if (parsed != _previewRadius) {
      setState(() {
        _previewRadius = parsed;
      });
    }
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final data = await SupabaseService.instance.getEmpresaById(
        widget.empresaId,
      );
      if (data != null) {
        _empresa = data;
        _lat = _toDouble(data['latitud']);
        _lng = _toDouble(data['longitud']);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  double _determineCompanyRadiusMeters() {
    double radiusMeters = 50.0;
    if (_empresa != null) {
      final radiusCandidates = [
        'allowed_radius_m',
        'radius_m',
        'radio',
        'geofence_radius',
        'rango',
        'radius',
      ];
      for (final k in radiusCandidates) {
        final rv = _empresa?[k];
        if (rv != null) {
          final parsed = rv is num
              ? rv.toDouble()
              : double.tryParse(rv.toString());
          if (parsed != null && parsed > 0) {
            radiusMeters = parsed;
            break;
          }
        }
      }
    }
    return radiusMeters;
  }

  double? _getStoredRadius() {
    if (_empresa == null) return null;
    final radiusCandidates = [
      'allowed_radius_m',
      'radius_m',
      'radio',
      'geofence_radius',
      'rango',
      'radius',
    ];
    for (final k in radiusCandidates) {
      final rv = _empresa?[k];
      if (rv == null) continue;
      if (rv is num) return rv.toDouble();
      final parsed = double.tryParse(rv.toString());
      if (parsed != null) return parsed;
    }
    return null;
  }

  void _centerMap() {
    if (_mapController == null || _lat == null || _lng == null) return;
    try {
      _mapController!.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(gmaps.LatLng(_lat!, _lng!), _zoom),
      );
    } catch (_) {}
  }

  Widget _detailRow(
    String label,
    Object? value, {
    Widget? trailing,
    IconData? icon,
  }) {
    final text = value?.toString() ?? '—';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppColors.mutedGray),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.mutedGray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  text,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing],
        ],
      ),
    );
  }

  Widget _editableRow(
    String label,
    TextEditingController controller, {
    IconData? icon,
    String? hint,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppColors.mutedGray),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.mutedGray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(hintText: hint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleMapButton({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(8),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 2,
        minimumSize: const Size(40, 40),
      ),
      child: Icon(icon, size: 20),
    );
  }

  String _formatCreated(Object? created) {
    if (created == null) return '—';
    try {
      // Accept strings like '2026-01-19 04:14:41.068034' or ISO formats
      final s = created.toString();
      DateTime dt;
      if (s.contains(' ')) {
        dt = DateTime.parse(s.replaceFirst(' ', 'T'));
      } else {
        dt = DateTime.parse(s);
      }
      return DateFormat('dd/MM/yyyy HH:mm').format(dt.toLocal());
    } catch (_) {
      return created.toString();
    }
  }

  @override
  void dispose() {
    _nombreCtrl?.dispose();
    _rucCtrl?.dispose();
    _telefonoCtrl?.dispose();
    _correoCtrl?.dispose();
    _direccionCtrl?.dispose();
    _radiusCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Detalle de Empresa'),
        backgroundColor: AppColors.primary,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _empresa?['nombre']?.toString() ?? 'Empresa',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _openEditNameDialog,
                          icon: const Icon(Icons.edit),
                          tooltip: 'Editar nombre',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Prominent access code card — shown first and visually distinct
                    _accessCodeCard(),
                    const SizedBox(height: 8),
                    // Superadmin: quick action to create a departamento for this empresa
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            final navigator = Navigator.of(context);
                            final messenger = ScaffoldMessenger.of(context);
                            final res = await navigator.push<bool>(
                              MaterialPageRoute(
                                builder: (_) => CreacionDepartamentos(
                                  empresaId: widget.empresaId,
                                ),
                              ),
                            );
                            if (res == true) {
                              await _fetch();
                              if (!mounted) return;
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Departamento creado'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.add_business),
                          label: const Text('Crear departamento'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),
                    Card(
                      color: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_empresa?['empresa_foto_url'] != null) ...[
                              InkWell(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => Dialog(
                                      insetPadding: const EdgeInsets.all(8),
                                      child: InteractiveViewer(
                                        child: Image.network(
                                          _empresa!['empresa_foto_url'],
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    _empresa!['empresa_foto_url'],
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Details list (styled like a form with icons)
                            // Editable details: switch between read-only and inline fields
                            if (_editing) ...[
                              _editableRow(
                                'RUC',
                                _rucCtrl!,
                                icon: Icons.receipt_long,
                              ),
                              _editableRow(
                                'Teléfono',
                                _telefonoCtrl!,
                                icon: Icons.phone,
                              ),
                              _editableRow(
                                'Email',
                                _correoCtrl!,
                                icon: Icons.email,
                              ),
                              _editableRow(
                                'Dirección',
                                _direccionCtrl!,
                                icon: Icons.location_on,
                              ),
                              _editableRow(
                                'Radio (m)',
                                _radiusCtrl!,
                                icon: Icons.my_location,
                                hint: 'Ej. 50',
                              ),
                            ] else ...[
                              _detailRow(
                                'RUC',
                                _empresa?['ruc'] ?? _empresa?['ruc_empresa'],
                                icon: Icons.receipt_long,
                              ),
                              _detailRow(
                                'Teléfono',
                                _empresa?['telefono'],
                                icon: Icons.phone,
                              ),
                              _detailRow(
                                'Email',
                                _empresa?['correo'] ?? _empresa?['email'],
                                icon: Icons.email,
                              ),
                              _detailRow(
                                'Dirección',
                                _empresa?['direccion'],
                                icon: Icons.location_on,
                              ),
                              _detailRow(
                                'Radio (m)',
                                (_getStoredRadius() != null)
                                    ? '${_getStoredRadius()!.toStringAsFixed(0)} m'
                                    : '—',
                                icon: Icons.my_location,
                              ),
                            ],
                            // Lat/Lng hidden here (map shows coordinates)
                            _detailRow(
                              'Creado',
                              _formatCreated(
                                _empresa?['created_at'] ??
                                    _empresa?['createdAt'],
                              ),
                              icon: Icons.calendar_today,
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 260,
                              child:
                                  (_editing
                                      ? (_editLat != null && _editLng != null)
                                      : (_lat != null && _lng != null))
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Stack(
                                        children: [
                                          SizedBox.expand(
                                            child: gmaps.GoogleMap(
                                              initialCameraPosition:
                                                  gmaps.CameraPosition(
                                                    target: gmaps.LatLng(
                                                      _editing
                                                          ? (_editLat ??
                                                                -2.8895)
                                                          : (_lat ?? -2.8895),
                                                      _editing
                                                          ? (_editLng ??
                                                                -79.0086)
                                                          : (_lng ?? -79.0086),
                                                    ),
                                                    zoom: _zoom,
                                                  ),
                                              gestureRecognizers:
                                                  <
                                                    Factory<
                                                      OneSequenceGestureRecognizer
                                                    >
                                                  >{
                                                    Factory<
                                                      OneSequenceGestureRecognizer
                                                    >(
                                                      () =>
                                                          EagerGestureRecognizer(),
                                                    ),
                                                  },
                                              markers: {
                                                gmaps.Marker(
                                                  markerId:
                                                      const gmaps.MarkerId(
                                                        'company',
                                                      ),
                                                  position: gmaps.LatLng(
                                                    _editing
                                                        ? (_editLat ?? -2.8895)
                                                        : (_lat ?? -2.8895),
                                                    _editing
                                                        ? (_editLng ?? -79.0086)
                                                        : (_lng ?? -79.0086),
                                                  ),
                                                  draggable: _editing,
                                                  icon:
                                                      gmaps
                                                          .BitmapDescriptor.defaultMarkerWithHue(
                                                        gmaps
                                                            .BitmapDescriptor
                                                            .hueRed,
                                                      ),
                                                  onDragEnd: (p) {
                                                    if (!_editing) return;
                                                    setState(() {
                                                      _editLat = p.latitude;
                                                      _editLng = p.longitude;
                                                    });
                                                  },
                                                ),
                                              },
                                              circles: {
                                                gmaps.Circle(
                                                  circleId:
                                                      const gmaps.CircleId(
                                                        'company_radius',
                                                      ),
                                                  center: gmaps.LatLng(
                                                    _editing
                                                        ? (_editLat ??
                                                              _lat ??
                                                              0)
                                                        : (_lat ?? 0),
                                                    _editing
                                                        ? (_editLng ??
                                                              _lng ??
                                                              0)
                                                        : (_lng ?? 0),
                                                  ),
                                                  radius: _editing
                                                      ? (_previewRadius ??
                                                            _determineCompanyRadiusMeters())
                                                      : _determineCompanyRadiusMeters(),
                                                  fillColor:
                                                      const Color.fromRGBO(
                                                        33,
                                                        150,
                                                        243,
                                                        0.12,
                                                      ),
                                                  strokeColor:
                                                      const Color.fromRGBO(
                                                        33,
                                                        150,
                                                        243,
                                                        0.8,
                                                      ),
                                                  strokeWidth: 1,
                                                ),
                                              },
                                              onMapCreated: (c) =>
                                                  _mapController = c,
                                              onTap: (pos) {
                                                if (!_editing) return;
                                                setState(() {
                                                  _editLat = pos.latitude;
                                                  _editLng = pos.longitude;
                                                });
                                              },
                                              myLocationButtonEnabled: false,
                                              zoomControlsEnabled: false,
                                            ),
                                          ),
                                          Positioned(
                                            right: 8,
                                            top: 8,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                _circleMapButton(
                                                  icon: Icons.my_location,
                                                  onPressed: _centerMap,
                                                  tooltip: 'Centrar',
                                                ),
                                                const SizedBox(height: 8),
                                                _circleMapButton(
                                                  icon: Icons.add,
                                                  onPressed: () async {
                                                    try {
                                                      final targetLat = _editing
                                                          ? _editLat
                                                          : _lat;
                                                      final targetLng = _editing
                                                          ? _editLng
                                                          : _lng;
                                                      if (targetLat == null ||
                                                          targetLng == null)
                                                        return;
                                                      _zoom = (_zoom + 1).clamp(
                                                        2.0,
                                                        21.0,
                                                      );
                                                      await _mapController
                                                          ?.animateCamera(
                                                            gmaps
                                                                .CameraUpdate.newLatLngZoom(
                                                              gmaps.LatLng(
                                                                targetLat,
                                                                targetLng,
                                                              ),
                                                              _zoom,
                                                            ),
                                                          );
                                                    } catch (_) {}
                                                  },
                                                  tooltip: 'Aumentar zoom',
                                                ),
                                                const SizedBox(height: 8),
                                                _circleMapButton(
                                                  icon: Icons.remove,
                                                  onPressed: () async {
                                                    try {
                                                      final targetLat = _editing
                                                          ? _editLat
                                                          : _lat;
                                                      final targetLng = _editing
                                                          ? _editLng
                                                          : _lng;
                                                      if (targetLat == null ||
                                                          targetLng == null)
                                                        return;
                                                      _zoom = (_zoom - 1).clamp(
                                                        2.0,
                                                        21.0,
                                                      );
                                                      await _mapController
                                                          ?.animateCamera(
                                                            gmaps
                                                                .CameraUpdate.newLatLngZoom(
                                                              gmaps.LatLng(
                                                                targetLat,
                                                                targetLng,
                                                              ),
                                                              _zoom,
                                                            ),
                                                          );
                                                    } catch (_) {}
                                                  },
                                                  tooltip: 'Disminuir zoom',
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        'No hay coordenadas',
                                        style: AppTextStyles.smallLabel
                                            .copyWith(
                                              color: AppColors.mutedGray,
                                            ),
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Spacer(),
                                if (!_editing) ...[
                                  ElevatedButton.icon(
                                    onPressed: _startEditing,
                                    icon: const Icon(Icons.edit),
                                    label: const Text('Editar'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ] else ...[
                                  OutlinedButton(
                                    onPressed: _cancelEditing,
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Cancelar'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: _saveEditing,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Guardar'),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _accessCodeCard() {
    final code =
        _empresa?['codigo_acceso_empleado'] ??
        _empresa?['codigoAcceso'] ??
        _empresa?['codigo_acceso'];
    if (code == null) return const SizedBox.shrink();
    final text = code.toString();
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Código de acceso',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            // copy button removed per UX request
          ],
        ),
      ),
    );
  }
}
