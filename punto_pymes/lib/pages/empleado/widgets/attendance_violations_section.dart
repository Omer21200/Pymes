import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import '../../../service/supabase_service.dart';
import '../../../theme.dart';

class AttendanceViolationsSection extends StatefulWidget {
  const AttendanceViolationsSection({super.key});

  @override
  State<AttendanceViolationsSection> createState() =>
      _AttendanceViolationsSectionState();
}

class _AttendanceViolationsSectionState
    extends State<AttendanceViolationsSection> {
  late Future<List<Map<String, dynamic>>> _violFuture;

  @override
  void initState() {
    super.initState();
    _violFuture = SupabaseService.instance.getMisViolaciones(limite: 6);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _violFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return SizedBox(
            height: 120,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.brandRed),
            ),
          );
        }
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return SizedBox(
            height: 80,
            child: Center(
              child: Text(
                'No hay violaciones recientes',
                style: AppTextStyles.subtitle.copyWith(
                  color: AppColors.mutedGray,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              child: Text('Reportes', style: AppTextStyles.sectionTitle),
            ),
            SizedBox(
              height: 140,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final v = items[index];
                  final created = v['created_at']?.toString() ?? '';
                  final dist = v['distance_m']?.toString() ?? '';

                  return _buildViolationCard(context, v, created, dist);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildViolationCard(
    BuildContext context,
    Map<String, dynamic> v,
    String created,
    String dist,
  ) {
    String formatDistanceLocal(String raw) {
      try {
        final d = double.parse(raw);
        if (d >= 1000) {
          final km = (d / 1000);
          return '${km.toStringAsFixed(1)} km';
        }
        return '${d.toStringAsFixed(0)} m';
      } catch (_) {
        return raw;
      }
    }

    String formatDateLocal(String raw) {
      try {
        final dt = DateTime.parse(raw).toLocal();
        return DateFormat('dd/MM/yyyy HH:mm').format(dt);
      } catch (_) {
        return raw;
      }
    }

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.notificationBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.gps_off, color: AppColors.brandRed, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Violación de geocerca',
                  style: AppTextStyles.sectionTitle.copyWith(
                    fontSize: 14,
                    color: AppColors.brandRed,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatDistanceLocal(dist),
            style: AppTextStyles.smallLabel.copyWith(
              color: AppColors.mutedGray,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatDateLocal(created),
                style: AppTextStyles.smallLabel.copyWith(
                  color: AppColors.mutedGray,
                ),
              ),
              TextButton(
                onPressed: () => _showViolationDetail(context, v),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  backgroundColor: AppColors.brandRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Ver',
                  style: AppTextStyles.smallLabel.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Helper: show modal with violation detail and map
void _showViolationDetail(BuildContext context, Map<String, dynamic> v) {
  double? parseVal(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString());
  }

  final lat = parseVal(v['latitud'] ?? v['lat']);
  final lng = parseVal(v['longitud'] ?? v['lng']);
  final dist = v['distance_m']?.toString() ?? '';
  final created = v['created_at']?.toString() ?? '';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      if (lat == null || lng == null) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'No hay coordenadas disponibles para esta violación',
            style: AppTextStyles.subtitle,
          ),
        );
      }

      final companyFuture = (() async {
        try {
          final me = await SupabaseService.instance.getEmpleadoActual();
          final empresaId = me == null ? null : me['empresa_id']?.toString();
          if (empresaId == null) return null;
          final empresa = await SupabaseService.instance.getEmpresaById(
            empresaId,
          );
          return empresa;
        } catch (_) {
          return null;
        }
      })();

      return FutureBuilder<Map<String, dynamic>?>(
        future: companyFuture,
        builder: (context2, snap) {
          final empresa = snap.data;

          double? compLat;
          double? compLng;
          double? compRadius;
          if (empresa != null) {
            dynamic la = empresa['latitud'];
            dynamic ln = empresa['longitud'];
            double? parseCoord(dynamic v) {
              if (v == null) return null;
              if (v is num) return v.toDouble();
              return double.tryParse(v.toString());
            }

            compLat = parseCoord(la);
            compLng = parseCoord(ln);

            final radiusCandidates = [
              'allowed_radius_m',
              'radius_m',
              'radio',
              'geofence_radius',
              'rango',
              'radius',
            ];
            for (final k in radiusCandidates) {
              final rv = empresa[k];
              if (rv != null) {
                final parsed = rv is num
                    ? rv.toDouble()
                    : double.tryParse('$rv');
                if (parsed != null && parsed > 0) {
                  compRadius = parsed;
                  break;
                }
              }
            }
          }

          final List<gmaps.LatLng> pts = [];
          final vPos = gmaps.LatLng(lat, lng);
          pts.add(vPos);
          if (compLat != null && compLng != null) {
            pts.add(gmaps.LatLng(compLat, compLng));
          }

          gmaps.LatLng initialTarget;
          double initialZoom = 16;
          if (pts.length == 1) {
            initialTarget = pts.first;
          } else {
            double la = 0, ln = 0;
            for (final p in pts) {
              la += p.latitude;
              ln += p.longitude;
            }
            initialTarget = gmaps.LatLng(la / pts.length, ln / pts.length);
            initialZoom = 14;
          }

          final initial = gmaps.CameraPosition(
            target: initialTarget,
            zoom: initialZoom,
          );

          final markers = <gmaps.Marker>{
            gmaps.Marker(markerId: const gmaps.MarkerId('v'), position: vPos),
          };
          if (compLat != null && compLng != null) {
            markers.add(
              gmaps.Marker(
                markerId: const gmaps.MarkerId('company'),
                position: gmaps.LatLng(compLat, compLng),
              ),
            );
          }

          final circles = <gmaps.Circle>{};
          if (compLat != null && compLng != null && compRadius != null) {
            circles.add(
              gmaps.Circle(
                circleId: const gmaps.CircleId('company_radius'),
                center: gmaps.LatLng(compLat, compLng),
                radius: compRadius,
                fillColor: const Color.fromRGBO(217, 35, 68, 0.25),
                strokeColor: const Color.fromRGBO(217, 35, 68, 1.0),
                strokeWidth: 3,
              ),
            );
          }

          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.66,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Detalle de violación',
                          style: AppTextStyles.headline,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: gmaps.GoogleMap(
                      initialCameraPosition: initial,
                      markers: markers,
                      circles: circles,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: true,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Distancia: ${_formatDistanceShort(dist)}',
                            style: AppTextStyles.sectionTitle,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Fecha: ${_formatDateShort(created)}',
                            style: AppTextStyles.smallLabel.copyWith(
                              color: AppColors.mutedGray,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          'Cerrar',
                          style: AppTextStyles.smallLabel.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

String _formatDistanceShort(String raw) {
  try {
    final d = double.parse(raw);
    if (d >= 1000) return '${(d / 1000).toStringAsFixed(1)} km';
    return '${d.toStringAsFixed(0)} m';
  } catch (_) {
    return raw;
  }
}

String _formatDateShort(String raw) {
  try {
    final dt = DateTime.parse(raw).toLocal();
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  } catch (_) {
    return raw;
  }
}
