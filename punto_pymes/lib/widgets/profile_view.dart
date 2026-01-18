import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlng;
import '../theme.dart';

class ProfileView extends StatefulWidget {
  final TextEditingController nombresController;
  final TextEditingController apellidosController;
  final TextEditingController cedulaController;
  final TextEditingController telefonoController;
  final TextEditingController direccionController;
  final String? email;
  final String? fotoUrl;
  final File? selectedImageFile;
  final VoidCallback onPickImage;
  final Future<void> Function() onSave;
  final bool isLoading;
  final String? errorMessage;
  final double? companyLat;
  final double? companyLng;
  final String? companyName;
  final String? companyAddress;
  final double? userLat;
  final double? userLng;
  final String? userAddress;

  const ProfileView({
    super.key,
    required this.nombresController,
    required this.apellidosController,
    required this.cedulaController,
    required this.telefonoController,
    required this.direccionController,
    required this.onPickImage,
    required this.onSave,
    this.email,
    this.fotoUrl,
    this.selectedImageFile,
    this.isLoading = false,
    this.errorMessage,
    this.companyLat,
    this.companyLng,
    this.companyName,
    this.companyAddress,
    this.userLat,
    this.userLng,
    this.userAddress,
  });

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  bool _editing = false;
  late Map<String, String> _backup;
  double? _deviceLat;
  double? _deviceLng;
  final MapController _profileMapController = MapController();
  double _profileMapZoom = 15.0;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _backup = {
      'nombres': widget.nombresController.text,
      'apellidos': widget.apellidosController.text,
      'telefono': widget.telefonoController.text,
      'direccion': widget.direccionController.text,
      'cedula': widget.cedulaController.text,
    };
    _emailController = TextEditingController(text: widget.email ?? '');
    _initDeviceLocation();
  }

  @override
  void didUpdateWidget(covariant ProfileView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.email != oldWidget.email) {
      _emailController.text = widget.email ?? '';
    }
  }

  Future<void> _initDeviceLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (mounted) {
        setState(() {
          _deviceLat = pos.latitude;
          _deviceLng = pos.longitude;
        });
      }
    } catch (e) {
      // ignore errors silently; device location is optional
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 18),
        Center(child: _buildAvatar(context)),
        const SizedBox(height: 18),

        // Card with fields (styled)
        Card(
          elevation: 6,
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Información',
                        style: AppTextStyles.sectionTitle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: widget.nombresController,
                  enabled: _editing,
                  textCapitalization: TextCapitalization.words,
                  decoration: _fieldDecoration(
                    Icons.person,
                    'Nombres',
                    readOnly: !_editing,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: widget.apellidosController,
                  enabled: _editing,
                  textCapitalization: TextCapitalization.words,
                  decoration: _fieldDecoration(
                    Icons.person,
                    'Apellidos',
                    readOnly: !_editing,
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _emailController,
                  readOnly: true,
                  decoration: _fieldDecoration(
                    Icons.email,
                    'Correo electrónico',
                    readOnly: true,
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: widget.cedulaController,
                  readOnly: true,
                  decoration: _fieldDecoration(
                    Icons.credit_card,
                    'Cédula / Documento',
                    readOnly: true,
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: widget.telefonoController,
                  enabled: _editing,
                  keyboardType: TextInputType.phone,
                  decoration: _fieldDecoration(
                    Icons.phone,
                    'Teléfono',
                    readOnly: !_editing,
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: widget.direccionController,
                  enabled: _editing,
                  keyboardType: TextInputType.streetAddress,
                  decoration: _fieldDecoration(
                    Icons.location_on,
                    'Dirección',
                    readOnly: !_editing,
                  ),
                ),
                const SizedBox(height: 14),
                if (widget.companyName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      widget.companyName!,
                      style: AppTextStyles.smallLabel,
                    ),
                  ),
                if (widget.companyAddress != null &&
                    widget.companyAddress!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      widget.companyAddress!,
                      style: AppTextStyles.smallLabel.copyWith(
                        color: AppColors.mutedGray,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),
        if (widget.errorMessage != null)
          Text(
            widget.errorMessage!,
            style: AppTextStyles.smallLabel.copyWith(
              color: AppColors.dangerRed,
            ),
          ),
        const SizedBox(height: 12),

        // Interactive map (OpenStreetMap via flutter_map)
        if (widget.userLat != null || widget.companyLat != null)
          SizedBox(
            height: 220,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _profileMapController,
                    options: MapOptions(
                      initialCenter: _calculateCenter(),
                      initialZoom: _profileMapZoom,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.pymes.app',
                      ),
                      MarkerLayer(markers: _buildMarkers()),
                    ],
                  ),

                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 6),
                        ],
                      ),
                      child: Column(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.my_location,
                              color: Colors.black87,
                            ),
                            onPressed: () {
                              final center = _calculateCenter();
                              _profileMapController.move(
                                center,
                                _profileMapZoom,
                              );
                            },
                          ),
                          const Divider(height: 1),
                          IconButton(
                            icon: const Icon(Icons.add, size: 20),
                            onPressed: () {
                              _profileMapZoom = (_profileMapZoom + 1).clamp(
                                1,
                                20,
                              );
                              _profileMapController.move(
                                _calculateCenter(),
                                _profileMapZoom,
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove, size: 20),
                            onPressed: () {
                              _profileMapZoom = (_profileMapZoom - 1).clamp(
                                1,
                                20,
                              );
                              _profileMapController.move(
                                _calculateCenter(),
                                _profileMapZoom,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),

        if (_editing)
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: widget.isLoading ? null : _cancelEdit,
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: widget.isLoading ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: const StadiumBorder(),
                    ),
                    child: widget.isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Guardar',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ),
            ],
          )
        else
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _enterEdit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: const StadiumBorder(),
              ),
              child: const Text(
                'Editar',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }

  void _enterEdit() {
    setState(() {
      _backup = {
        'nombres': widget.nombresController.text,
        'apellidos': widget.apellidosController.text,
        'telefono': widget.telefonoController.text,
        'direccion': widget.direccionController.text,
        'cedula': widget.cedulaController.text,
      };
      _editing = true;
    });
  }

  void _cancelEdit() {
    setState(() {
      widget.nombresController.text = _backup['nombres'] ?? '';
      widget.apellidosController.text = _backup['apellidos'] ?? '';
      widget.telefonoController.text = _backup['telefono'] ?? '';
      widget.direccionController.text = _backup['direccion'] ?? '';
      widget.cedulaController.text = _backup['cedula'] ?? '';
      _editing = false;
    });
  }

  Future<void> _saveChanges() async {
    await widget.onSave();
    if (mounted) {
      setState(() {
        _editing = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Widget _buildAvatar(BuildContext context) {
    final radius = 48.0;
    ImageProvider? img;
    if (widget.selectedImageFile != null) {
      img = FileImage(widget.selectedImageFile!);
    } else if (widget.fotoUrl != null && widget.fotoUrl!.isNotEmpty) {
      img = NetworkImage(widget.fotoUrl!);
    }

    return GestureDetector(
      onTap: widget.onPickImage,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.surfaceSoft,
        backgroundImage: img,
        child: img == null
            ? Text(
                (widget.nombresController.text.isNotEmpty
                        ? widget.nombresController.text[0]
                        : 'U') +
                    (widget.apellidosController.text.isNotEmpty
                        ? widget.apellidosController.text[0]
                        : ''),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              )
            : null,
      ),
    );
  }

  InputDecoration _fieldDecoration(
    IconData icon,
    String label, {
    bool readOnly = false,
  }) {
    return InputDecoration(
      prefixIcon: Icon(icon),
      labelText: label,
      filled: true,
      fillColor: AppColors.surfaceSoft,
      enabled: !readOnly,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  // intentionally left blank: map opening handled externally if needed

  latlng.LatLng _calculateCenter() {
    final pts = <latlng.LatLng>[];
    if (widget.companyLat != null && widget.companyLng != null) {
      pts.add(latlng.LatLng(widget.companyLat!, widget.companyLng!));
    }
    if (widget.userLat != null && widget.userLng != null) {
      pts.add(latlng.LatLng(widget.userLat!, widget.userLng!));
    }
    if (_deviceLat != null && _deviceLng != null) {
      pts.add(latlng.LatLng(_deviceLat!, _deviceLng!));
    }
    if (pts.isEmpty) return latlng.LatLng(0, 0);
    double latSum = 0, lngSum = 0;
    for (final p in pts) {
      latSum += p.latitude;
      lngSum += p.longitude;
    }
    return latlng.LatLng(latSum / pts.length, lngSum / pts.length);
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
    if (widget.companyLat != null && widget.companyLng != null) {
      markers.add(
        Marker(
          width: 40,
          height: 40,
          point: latlng.LatLng(widget.companyLat!, widget.companyLng!),
          child: const Icon(Icons.location_on, color: Colors.red, size: 36),
        ),
      );
    }
    if (widget.userLat != null && widget.userLng != null) {
      markers.add(
        Marker(
          width: 28,
          height: 28,
          point: latlng.LatLng(widget.userLat!, widget.userLng!),
          child: const Icon(Icons.my_location, color: Colors.blue, size: 28),
        ),
      );
    }
    if (_deviceLat != null && _deviceLng != null) {
      markers.add(
        Marker(
          width: 22,
          height: 22,
          point: latlng.LatLng(_deviceLat!, _deviceLng!),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue,
            ),
            width: 14,
            height: 14,
          ),
        ),
      );
    }
    return markers;
  }
}
