import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../../theme.dart';

class AsistenciaDetalleScreen extends StatefulWidget {
  final Map<String, dynamic> asistencia;
  final String? fotoUrl;

  const AsistenciaDetalleScreen({
    super.key,
    required this.asistencia,
    this.fotoUrl,
  });

  @override
  State<AsistenciaDetalleScreen> createState() =>
      _AsistenciaDetalleScreenState();
}

class _AsistenciaDetalleScreenState extends State<AsistenciaDetalleScreen> {
  late GoogleMapController mapController;
  Set<Marker> markers = {};
  bool _mapLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeMarkers();
  }

  void _initializeMarkers() {
    final latitud = widget.asistencia['latitud'] as double?;
    final longitud = widget.asistencia['longitud'] as double?;

    if (latitud != null && longitud != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('ubicacion_asistencia'),
          position: LatLng(latitud, longitud),
          infoWindow: const InfoWindow(title: 'Ubicación de Registro'),
        ),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    setState(() {
      _mapLoaded = true;
    });
  }

  String _formatearFecha(String fecha) {
    try {
      final date = DateTime.parse(fecha);
      return DateFormat('dd/MM/yyyy', 'es_ES').format(date);
    } catch (_) {
      return fecha;
    }
  }

  String _formatearHora(String? hora) {
    return hora ?? '--:--';
  }

  @override
  Widget build(BuildContext context) {
    final latitud = widget.asistencia['latitud'] as double?;
    final longitud = widget.asistencia['longitud'] as double?;
    final fecha = widget.asistencia['fecha'] as String? ?? '';
    final horaEntrada = widget.asistencia['hora_entrada'] as String?;
    final horaSalida = widget.asistencia['hora_salida'] as String?;
    final fotoUrl = widget.fotoUrl;

    final initialPosition = (latitud != null && longitud != null)
        ? LatLng(latitud, longitud)
        : const LatLng(-2.8895, -79.0086); // Centro de Ecuador

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detalle de Asistencia'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header foto + overlay
            if (fotoUrl != null && fotoUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    SizedBox(
                      height: 220,
                      width: double.infinity,
                      child: Image.network(
                        fotoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(Icons.image_not_supported, size: 48),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.28),
                            Colors.transparent,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.9),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios, size: 18),
                          color: AppColors.primary,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(height: 12),

            const SizedBox(height: 16),

            // Fecha card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calendar_today,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fecha',
                        style: AppTextStyles.smallLabel.copyWith(
                          color: AppColors.mutedGray,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatearFecha(fecha),
                        style: AppTextStyles.sectionTitle,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Horas
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.login,
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Entrada',
                              style: AppTextStyles.smallLabel.copyWith(
                                color: AppColors.mutedGray,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _formatearHora(horaEntrada),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.dangerRed.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.logout,
                                color: AppColors.dangerRed,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Salida',
                              style: AppTextStyles.smallLabel.copyWith(
                                color: AppColors.mutedGray,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _formatearHora(horaSalida),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Coordenadas
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.subtleBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.place, color: AppColors.accentBlue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Coordenadas GPS',
                          style: AppTextStyles.smallLabel.copyWith(
                            color: AppColors.mutedGray,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Latitud',
                                style: AppTextStyles.smallLabel,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Longitud',
                                textAlign: TextAlign.right,
                                style: AppTextStyles.smallLabel,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                latitud != null
                                    ? latitud.toStringAsFixed(6)
                                    : '--',
                                style: const TextStyle(
                                  fontFamily: 'Courier',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                longitud != null
                                    ? longitud.toStringAsFixed(6)
                                    : '--',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontFamily: 'Courier',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Mapa
            if (latitud != null && longitud != null) ...[
              Text('Ubicación en mapa', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 300,
                  child: GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: initialPosition,
                      zoom: 18,
                    ),
                    markers: markers,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    compassEnabled: false,
                    mapType: MapType.normal,
                  ),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No hay datos de ubicación para este registro',
                        style: AppTextStyles.smallLabel,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (_mapLoaded) {
      mapController.dispose();
    }
    super.dispose();
  }
}
