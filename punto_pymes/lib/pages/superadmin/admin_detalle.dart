import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import '../../service/supabase_service.dart';
import '../../theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AdminDetallePage extends StatefulWidget {
  final Map<String, dynamic> admin;
  const AdminDetallePage({super.key, required this.admin});

  @override
  State<AdminDetallePage> createState() => _AdminDetallePageState();
}

class _AdminDetallePageState extends State<AdminDetallePage> {
  Map<String, dynamic>? _empresa;
  double? _lat;
  double? _lng;
  bool _loading = true;
  gmaps.GoogleMapController? _mapController;
  double _zoom = 14.0;

  @override
  void initState() {
    super.initState();
    _fetchEmpresa();
  }

  Future<void> _fetchEmpresa() async {
    setState(() => _loading = true);
    try {
      final empresaId = widget.admin['empresa_id']?.toString();
      if (empresaId != null && empresaId.isNotEmpty) {
        final data = await SupabaseService.instance.getEmpresaById(empresaId);
        if (data != null) {
          _empresa = data;
          final latVal = data['latitud'];
          final lngVal = data['longitud'];
          _lat = (latVal is num)
              ? latVal.toDouble()
              : double.tryParse('$latVal');
          _lng = (lngVal is num)
              ? lngVal.toDouble()
              : double.tryParse('$lngVal');
        }
      }
    } catch (_) {
      // ignore errors for now
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDate(dynamic v) {
    try {
      final d = v is DateTime ? v : DateTime.tryParse(v.toString());
      if (d == null) return v.toString();
      final local = d.toLocal();
      final dd = local.day.toString().padLeft(2, '0');
      final mm = local.month.toString().padLeft(2, '0');
      final yyyy = local.year;
      final hh = local.hour.toString().padLeft(2, '0');
      final min = local.minute.toString().padLeft(2, '0');
      return '$dd/$mm/$yyyy $hh:$min';
    } catch (_) {
      return v.toString();
    }
  }

  String? _resolveField(List<String> keys) {
    bool nonEmpty(dynamic x) {
      if (x is String) return x.trim().isNotEmpty;
      if (x is num) return true;
      if (x is Map || x is List) return true;
      return false;
    }

    String toStr(dynamic x) {
      if (x == null) return '';
      if (x is String) return x.trim();
      return x.toString();
    }

    for (final k in keys) {
      // 1) direct on admin
      final v = widget.admin[k];
      if (nonEmpty(v)) return toStr(v);

      // 2) common nested objects
      final nestedCandidates = ['user', 'profile', 'data'];
      for (final n in nestedCandidates) {
        final node = widget.admin[n];
        if (node is Map && node.containsKey(k)) {
          final nv = node[k];
          if (nonEmpty(nv)) return toStr(nv);
        }
      }

      // 3) check empresa object
      if (_empresa != null && _empresa!.containsKey(k)) {
        final ev = _empresa![k];
        if (nonEmpty(ev)) return toStr(ev);
      }
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

  Widget _infoCard(IconData icon, String label, String? value) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: const Color(0xFFD92344)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value ?? 'No registrado',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _mapContainer() {
    if (_loading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_lat == null || _lng == null) {
      return Card(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('No hay ubicación registrada para esta empresa.'),
        ),
      );
    }

    return Container(
      height: 260.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 8),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            gmaps.GoogleMap(
              initialCameraPosition: gmaps.CameraPosition(
                target: gmaps.LatLng(_lat!, _lng!),
                zoom: _zoom,
              ),
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              markers: {
                gmaps.Marker(
                  markerId: const gmaps.MarkerId('company'),
                  position: gmaps.LatLng(_lat!, _lng!),
                ),
              },
              circles: (() {
                final r = _getStoredRadius();
                if (r == null) return <gmaps.Circle>{};
                return {
                  gmaps.Circle(
                    circleId: const gmaps.CircleId('company_radius'),
                    center: gmaps.LatLng(_lat!, _lng!),
                    radius: r,
                    fillColor: const Color.fromRGBO(33, 150, 243, 0.12),
                    strokeColor: const Color.fromRGBO(33, 150, 243, 0.8),
                    strokeWidth: 1,
                  ),
                };
              })(),
              onMapCreated: (ctrl) => _mapController = ctrl,
            ),
            Positioned(
              right: 12.w,
              top: 12.w,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      _zoom = (_zoom + 1).clamp(2.0, 20.0);
                      _centerMap();
                    },
                    child: Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(20),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.add,
                        color: const Color(0xFFD92344),
                        size: 18.w,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  GestureDetector(
                    onTap: () {
                      _zoom = (_zoom - 1).clamp(2.0, 20.0);
                      _centerMap();
                    },
                    child: Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(20),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.remove,
                        color: const Color(0xFFD92344),
                        size: 18.w,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  GestureDetector(
                    onTap: _centerMap,
                    child: Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(20),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.my_location,
                        color: const Color(0xFFD92344),
                        size: 18.w,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullName =
        '${widget.admin['nombres'] ?? ''} ${widget.admin['apellidos'] ?? ''}'
            .trim();
    final empresaNombre = widget.admin['empresas'] != null
        ? (widget.admin['empresas']['nombre']?.toString() ?? '')
        : '';
    final rol = widget.admin['rol'] ?? widget.admin['role'] ?? '';
    final emailVal = _resolveField([
      'email',
      'correo',
      'correo_electronico',
      'user_email',
    ]);
    final phoneVal = _resolveField([
      'telefono',
      'phone',
      'telefono_movil',
      'mobile',
    ]);
    final createdRaw = _resolveField([
      'created_at',
      'createdAt',
      'fecha_creacion',
      'created',
    ]);
    final createdVal = createdRaw != null ? _formatDate(createdRaw) : null;
    final address =
        _empresa?['direccion'] ??
        _empresa?['direccion_completa'] ??
        _empresa?['address'];

    return Scaffold(
      appBar: AppBar(
        title: Text(fullName.isEmpty ? 'Detalle' : fullName),
        backgroundColor: AppColors.primary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header row
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: AppColors.surfaceSoft,
                            child: const Icon(
                              Icons.person,
                              color: Color(0xFFD92344),
                              size: 34,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fullName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8.0,
                                  runSpacing: 6.0,
                                  children: [
                                    if (empresaNombre.isNotEmpty)
                                      Chip(
                                        label: Text(empresaNombre),
                                        backgroundColor: AppColors.surface,
                                      ),
                                    Chip(
                                      label: Text(rol.toString()),
                                      backgroundColor: AppColors.surface,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Info cards row: responsive — wrap to next line on narrow screens
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final spacing = 8.0;
                          final cardWidth =
                              (constraints.maxWidth - spacing * 2) / 3;
                          return Wrap(
                            spacing: spacing,
                            runSpacing: 8.0,
                            children: [
                              SizedBox(
                                width: cardWidth,
                                child: _infoCard(
                                  Icons.email,
                                  'Email',
                                  emailVal,
                                ),
                              ),
                              SizedBox(
                                width: cardWidth,
                                child: _infoCard(
                                  Icons.phone,
                                  'Teléfono',
                                  phoneVal,
                                ),
                              ),
                              SizedBox(
                                width: cardWidth,
                                child: _infoCard(
                                  Icons.calendar_today,
                                  'Creado',
                                  createdVal,
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      if (address != null)
                        Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            address.toString(),
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ),

                      const SizedBox(height: 18),
                      const Text(
                        'Ubicación asociada',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      // Map at the end
                      _mapContainer(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
