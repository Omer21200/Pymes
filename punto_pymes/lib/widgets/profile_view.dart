import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import '../theme.dart';
import 'department_selector_card.dart';
// map preview removed from profile view per user request

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
  final double? companyRadiusMeters;
  final String? companyName;
  final String? companyAddress;
  final double? userLat;
  final double? userLng;
  final String? userAddress;
  final List<Map<String, dynamic>>? departamentos;
  final String? departamentoId;
  final ValueChanged<String?>? onDepartamentoChanged;

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
    this.companyRadiusMeters,
    this.companyName,
    this.companyAddress,
    this.userLat,
    this.userLng,
    this.userAddress,
    this.departamentos,
    this.departamentoId,
    this.onDepartamentoChanged,
  });

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  bool _editing = false;
  late Map<String, String> _backup;
  double? _deviceLat;
  double? _deviceLng;
  gmaps.GoogleMapController? _googleMapController;
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
                if (widget.departamentos != null) ...[
                  // Use reusable DepartmentSelectorCard for consistent styling
                  DepartmentSelectorCard(
                    departamentos: widget.departamentos,
                    departamentoId: widget.departamentoId,
                    onChanged: _editing
                        ? (v) {
                            if (widget.onDepartamentoChanged != null) {
                              widget.onDepartamentoChanged!(v);
                            }
                            setState(() {});
                          }
                        : null,
                    enabled: _editing,
                    label: 'Departamento',
                  ),
                  const SizedBox(height: 14),
                ],
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

        // map removed from profile view
        const SizedBox(height: 12),

        if (_editing)
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: widget.isLoading ? null : _cancelEdit,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.dangerRed,
                  ),
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
                      foregroundColor: Colors.white,
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
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
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
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              child: const Text(
                'Editar',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
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
        backgroundColor: const Color.fromARGB(255, 211, 211, 213),
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

  gmaps.LatLng _calculateCenter() {
    final pts = <gmaps.LatLng>[];
    final c = _normalizeLatLng(widget.companyLat, widget.companyLng);
    if (c != null) pts.add(c);
    final u = _normalizeLatLng(widget.userLat, widget.userLng);
    if (u != null) pts.add(u);
    final d = _normalizeLatLng(_deviceLat, _deviceLng);
    if (d != null) pts.add(d);
    if (pts.isEmpty) return const gmaps.LatLng(0, 0);
    double latSum = 0, lngSum = 0;
    for (final p in pts) {
      latSum += p.latitude;
      lngSum += p.longitude;
    }
    return gmaps.LatLng(latSum / pts.length, lngSum / pts.length);
  }

  Set<gmaps.Marker> _buildGmapsMarkers() {
    final Set<gmaps.Marker> markers = {};
    final company = _normalizeLatLng(widget.companyLat, widget.companyLng);
    if (company != null) {
      markers.add(
        gmaps.Marker(
          markerId: const gmaps.MarkerId('company'),
          position: company,
        ),
      );
    }
    final user = _normalizeLatLng(widget.userLat, widget.userLng);
    if (user != null) {
      markers.add(
        gmaps.Marker(markerId: const gmaps.MarkerId('user'), position: user),
      );
    }
    // Only add a device marker if there's no saved user location to avoid duplicates
    final device = _normalizeLatLng(_deviceLat, _deviceLng);
    if (device != null && user == null) {
      markers.add(
        gmaps.Marker(
          markerId: const gmaps.MarkerId('device'),
          position: device,
        ),
      );
    }
    return markers;
  }

  Set<gmaps.Circle> _buildGmapsCircles() {
    final Set<gmaps.Circle> circles = {};
    final companyCenter = _normalizeLatLng(
      widget.companyLat,
      widget.companyLng,
    );
    if (companyCenter != null && widget.companyRadiusMeters != null) {
      circles.add(
        gmaps.Circle(
          circleId: const gmaps.CircleId('company_radius'),
          center: companyCenter,
          radius: widget.companyRadiusMeters!,
          fillColor: const Color.fromRGBO(217, 35, 68, 0.35),
          strokeColor: const Color.fromRGBO(217, 35, 68, 1.0),
          strokeWidth: 4,
        ),
      );
    }
    return circles;
  }

  gmaps.LatLng? _normalizeLatLng(double? lat, double? lng) {
    if (lat == null || lng == null) return null;
    // if lat looks like a longitude (abs>90) and lng looks like a latitude, swap
    if (lat.abs() > 90 && lng.abs() <= 90) return gmaps.LatLng(lng, lat);
    return gmaps.LatLng(lat, lng);
  }
}
