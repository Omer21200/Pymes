import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import '../../service/supabase_service.dart';
import '../../theme.dart';

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

  double? _toDouble(Object? v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
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

  void _centerMap() {
    if (_mapController == null || _lat == null || _lng == null) return;
    try {
      _mapController!.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(gmaps.LatLng(_lat!, _lng!), _zoom),
      );
    } catch (_) {}
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
                    Text(
                      _empresa?['nombre']?.toString() ?? 'Empresa',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
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
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _empresa!['empresa_foto_url'],
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Text(
                              _empresa?['direccion']?.toString() ??
                                  'Sin dirección registrada',
                              style: const TextStyle(color: Colors.black87),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 260,
                              child: _lat != null && _lng != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: gmaps.GoogleMap(
                                        initialCameraPosition:
                                            gmaps.CameraPosition(
                                              target: gmaps.LatLng(
                                                _lat!,
                                                _lng!,
                                              ),
                                              zoom: _zoom,
                                            ),
                                        markers: {
                                          gmaps.Marker(
                                            markerId: const gmaps.MarkerId(
                                              'company',
                                            ),
                                            position: gmaps.LatLng(
                                              _lat!,
                                              _lng!,
                                            ),
                                          ),
                                        },
                                        circles: {
                                          gmaps.Circle(
                                            circleId: const gmaps.CircleId(
                                              'company_radius',
                                            ),
                                            center: gmaps.LatLng(_lat!, _lng!),
                                            radius:
                                                _determineCompanyRadiusMeters(),
                                            fillColor: Colors.blue.withOpacity(
                                              0.12,
                                            ),
                                            strokeColor: Colors.blue,
                                            strokeWidth: 2,
                                          ),
                                        },
                                        onMapCreated: (c) => _mapController = c,
                                        myLocationButtonEnabled: false,
                                        zoomControlsEnabled: false,
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
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _centerMap,
                                  icon: const Icon(Icons.my_location),
                                  label: const Text('Centrar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                  ),
                                ),
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
}
