import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:geolocator/geolocator.dart';
import '../service/supabase_service.dart';
import '../theme.dart';

class CompanyMapPreview extends StatefulWidget {
  final bool showOnlyCompany;
  const CompanyMapPreview({super.key, this.showOnlyCompany = false});

  @override
  State<CompanyMapPreview> createState() => _CompanyMapPreviewState();
}

class _CompanyMapPreviewState extends State<CompanyMapPreview> {
  double? _companyLat;
  double? _companyLng;
  // raw values as fetched from DB (for debugging)
  dynamic _rawCompanyLat;
  dynamic _rawCompanyLng;
  double? _companyRadius;
  double? _userLat;
  double? _userLng;
  gmaps.GoogleMapController? _mapController;
  double _zoom = 15.0;
  double? _deviceLat;
  double? _deviceLng;

  @override
  void initState() {
    super.initState();
    _loadData();
    _initDeviceLocation();
  }

  Future<void> _initDeviceLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        final p = await Geolocator.requestPermission();
        if (p == LocationPermission.denied) return;
      }
      if (perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _deviceLat = pos.latitude;
          _deviceLng = pos.longitude;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadData() async {
    try {
      final data = await SupabaseService.instance.getEmpleadoActual();
      if (data == null) return;
      String? empresaId = data['empresa_id']?.toString();
      Map<String, dynamic>? empresaData;
      if (empresaId != null) {
        empresaData = await SupabaseService.instance.getEmpresaById(empresaId);
      }

      final empleadoRaw = data['empleado_raw'] as Map<String, dynamic>?;

      double? uLat, uLng;
      final userAddress = empleadoRaw?['direccion']?.toString() ?? '';
      if (userAddress.isNotEmpty) {
        try {
          final coords = await SupabaseService.instance.geocodeAddress(
            userAddress,
          );
          if (coords != null) {
            uLat = coords['lat'];
            uLng = coords['lng'];
          }
        } catch (_) {}
      }

      double? lat, lng, radius;
      if (empresaData != null) {
        final la = empresaData['latitud'];
        final ln = empresaData['longitud'];
        _rawCompanyLat = la;
        _rawCompanyLng = ln;
        double? parseCoord(dynamic v) {
          if (v == null) return null;
          if (v is num) return v.toDouble();
          return double.tryParse(v.toString());
        }

        lat = parseCoord(la);
        lng = parseCoord(ln);
        final radiusCandidates = [
          'allowed_radius_m',
          'radius_m',
          'radio',
          'geofence_radius',
          'rango',
          'radius',
        ];
        for (final k in radiusCandidates) {
          final rv = empresaData[k];
          if (rv != null) {
            final parsed = rv is num ? rv.toDouble() : double.tryParse('$rv');
            if (parsed != null && parsed > 0) {
              radius = parsed;
              break;
            }
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _companyLat = lat;
        _companyLng = lng;
        _companyRadius = radius;
        _userLat = uLat;
        _userLng = uLng;
      });
    } catch (_) {}
  }

  gmaps.LatLng? _normalize(double? lat, double? lng) {
    if (lat == null || lng == null) return null;
    if (lat.abs() > 90 && lng.abs() <= 90) return gmaps.LatLng(lng, lat);
    return gmaps.LatLng(lat, lng);
  }

  Set<gmaps.Marker> _markers() {
    final Set<gmaps.Marker> m = {};
    final c = _normalize(_companyLat, _companyLng);
    if (c != null) {
      m.add(
        gmaps.Marker(markerId: const gmaps.MarkerId('company'), position: c),
      );
    }
    // If configured to show only the company, skip user/device markers
    if (widget.showOnlyCompany) return m;

    final u = _normalize(_userLat, _userLng);
    if (u != null) {
      m.add(gmaps.Marker(markerId: const gmaps.MarkerId('user'), position: u));
    }
    final d = _normalize(_deviceLat, _deviceLng);
    if (d != null && u == null) {
      m.add(
        gmaps.Marker(markerId: const gmaps.MarkerId('device'), position: d),
      );
    }
    return m;
  }

  Set<gmaps.Circle> _circles() {
    final Set<gmaps.Circle> c = {};
    final center = _normalize(_companyLat, _companyLng);
    if (center != null && _companyRadius != null) {
      c.add(
        gmaps.Circle(
          circleId: const gmaps.CircleId('company_radius'),
          center: center,
          radius: _companyRadius!,
          fillColor: const Color.fromRGBO(217, 35, 68, 0.35),
          strokeColor: const Color.fromRGBO(217, 35, 68, 1.0),
          strokeWidth: 3,
        ),
      );
    }
    return c;
  }

  @override
  Widget build(BuildContext context) {
    if (_companyLat == null && _userLat == null && _deviceLat == null) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text('Sin datos de ubicación', style: AppTextStyles.subtitle),
        ),
      );
    }

    final initial = gmaps.CameraPosition(
      target:
          _normalize(_companyLat, _companyLng) ??
          _normalize(_userLat, _userLng) ??
          _normalize(_deviceLat, _deviceLng) ??
          const gmaps.LatLng(0, 0),
      zoom: _zoom,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 220,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                gmaps.GoogleMap(
                  initialCameraPosition: initial,
                  markers: _markers(),
                  circles: _circles(),
                  onCameraMove: (pos) {
                    _zoom = pos.zoom;
                  },
                  onMapCreated: (c) => _mapController = c,
                  myLocationEnabled: (_userLat != null || _deviceLat != null),
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
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
                          // Localizar (círculo blanco con icono rojo)
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
                                color: AppColors.primary,
                              ),
                              onPressed: () {
                                // Prefer device position, then user address, then company
                                final target =
                                    _normalize(_deviceLat, _deviceLng) ??
                                    _normalize(_userLat, _userLng) ??
                                    _normalize(_companyLat, _companyLng);
                                if (target != null && _mapController != null) {
                                  _mapController!.animateCamera(
                                    gmaps.CameraUpdate.newLatLngZoom(
                                      target,
                                      _zoom,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Zoom +
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
                                color: AppColors.primary,
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
                          // Zoom -
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
                                color: AppColors.primary,
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
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Coordenadas (DB): ${_rawCompanyLat ?? '-'} , ${_rawCompanyLng ?? '-'}',
                style: AppTextStyles.smallLabel.copyWith(
                  color: AppColors.mutedGray,
                ),
              ),
              if ((_rawCompanyLat is num &&
                      (_rawCompanyLat as num).abs() > 90) ||
                  (_rawCompanyLng is num && (_rawCompanyLng as num).abs() > 90))
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    'Atención: las coordenadas parecen estar invertidas (latitud > 90).',
                    style: AppTextStyles.smallLabel.copyWith(
                      color: AppColors.dangerRed,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
