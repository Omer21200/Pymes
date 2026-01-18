import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

class AsistenciaDetalleScreen extends StatefulWidget {
  final Map<String, dynamic> asistencia;
  final String? fotoUrl;

  const AsistenciaDetalleScreen({
    Key? key,
    required this.asistencia,
    this.fotoUrl,
  }) : super(key: key);

  @override
  State<AsistenciaDetalleScreen> createState() => _AsistenciaDetalleScreenState();
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
          infoWindow: const InfoWindow(
            title: 'Ubicación de Registro',
          ),
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
      appBar: AppBar(
        title: const Text('Detalle de Asistencia'),
        backgroundColor: const Color(0xFFD92344),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Foto si está disponible
            if (fotoUrl != null && fotoUrl.isNotEmpty) ...[
              Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.black,
                ),
                child: InteractiveViewer(
                  panEnabled: true,
                  scaleEnabled: true,
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.network(
                      fotoUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.image_not_supported, size: 48),
                                const SizedBox(height: 8),
                                Text('No se pudo cargar la foto',
                                    style: TextStyle(color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: Colors.black,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],

            // Información general
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fecha
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: Color(0xFFD92344), size: 24),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fecha',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatearFecha(fecha),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Horarios (Entrada y Salida)
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.login,
                                      color: Colors.green, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Entrada',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatearHora(horaEntrada),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Courier',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.logout,
                                      color: Colors.red, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Salida',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatearHora(horaSalida),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Courier',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Ubicación en texto
                  if (latitud != null && longitud != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  color: Colors.blue, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Coordenadas GPS',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Latitud',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$latitud',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Courier',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Longitud',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$longitud',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Courier',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Mapa
                    const Text(
                      'Ubicación en Mapa',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                        color: Colors.grey.shade100,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: GoogleMap(
                          onMapCreated: _onMapCreated,
                          initialCameraPosition: CameraPosition(
                            target: initialPosition,
                            zoom: 18,
                          ),
                          markers: markers,
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: true,
                          compassEnabled: true,
                          mapType: MapType.normal,
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.amber.shade600),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'No hay datos de ubicación para este registro',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
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
