import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// logout_helper removed: no onWillPop logic here anymore
import 'widgets/superadmin_header.dart';
import '../../service/supabase_service.dart';

class CreacionEmpresas extends StatefulWidget {
  const CreacionEmpresas({super.key});

  @override
  State<CreacionEmpresas> createState() => _CreacionEmpresasState();
}

class _CreacionEmpresasState extends State<CreacionEmpresas> {
  ImageProvider? _logoImage;
  String? _logoFilePath;
  final bool _isUploading = false;
  bool _isCreating = false;

  final ImagePicker _picker = ImagePicker();

  // Controladores de formulario
  final _nombreController = TextEditingController();
  final _rucController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _correoController = TextEditingController();
  final _latitudController = TextEditingController();
  final _longitudController = TextEditingController();
  // Mapa - selección de ubicación
  LatLng? _selectedLocation;
  GoogleMapController? _mapController;

  @override
  void dispose() {
    _nombreController.dispose();
    _rucController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    _latitudController.dispose();
    _longitudController.dispose();
    super.dispose();
  }

  void _showLogoOptions() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Elegir desde la galería'),
            onTap: () => Navigator.of(context).pop('gallery'),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Tomar foto (cámara)'),
            onTap: () => Navigator.of(context).pop('camera'),
          ),
          if (_logoImage != null)
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Quitar logo'),
              onTap: () => Navigator.of(context).pop('remove'),
            ),
          ListTile(
            leading: const Icon(Icons.close),
            title: const Text('Cancelar'),
            onTap: () => Navigator.of(context).pop('cancel'),
          ),
        ]),
      ),
    );

    if (!mounted) return;

    if (choice == 'remove') {
      setState(() {
        _logoImage = null;
        _logoFilePath = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logo eliminado')));
      return;
    }

    if (choice == 'gallery' || choice == 'camera') {
      try {
        final XFile? picked = await _picker.pickImage(
          source: choice == 'gallery' ? ImageSource.gallery : ImageSource.camera,
          maxWidth: 1200,
          imageQuality: 85,
        );

        if (picked != null) {
          if (!mounted) return;
          setState(() {
            _logoImage = FileImage(File(picked.path));
            _logoFilePath = picked.path;
          });
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logo seleccionado')));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al seleccionar imagen: $e')));
      }
    }
  }

  String _generateCodigoAcceso(String nombre) {
    final base = nombre.trim().replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    final random = DateTime.now().millisecondsSinceEpoch % 1000000;
    final symbols = String.fromCharCodes(List.generate(2, (i) => 65 + (random + i) % 26));
    return 'EMP-${base.substring(0, base.length > 4 ? 4 : base.length)}$symbols$random';
  }

  Future<void> _createEmpresa() async {
    if (_nombreController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre de la empresa es obligatorio')),
      );
      return;
    }

    if (_logoFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes seleccionar un logo para la empresa')),
      );
      return;
    }

    setState(() => _isCreating = true);

    String? finalFilePath;
    bool movedToFinal = false;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeName = _nombreController.text.trim().replaceAll(' ', '_');
      final fileName = 'empresa_${timestamp}_$safeName.jpg';
      finalFilePath = 'empresas/$fileName';

      // Subir directamente a la ruta final para evitar errores de move
      final logoUrl = await SupabaseService.instance.uploadFile(
        filePath: _logoFilePath!,
        bucketName: 'fotos',
        destinationPath: finalFilePath,
      );
      movedToFinal = true;
      double? lat;
      double? lng;
      // Si el usuario seleccionó ubicación en el mapa, priorizamos esa ubicación
      if (_selectedLocation != null) {
        lat = _selectedLocation!.latitude;
        lng = _selectedLocation!.longitude;
        _latitudController.text = lat.toString();
        _longitudController.text = lng.toString();
      } else {
        if (_latitudController.text.trim().isNotEmpty) {
          lat = double.tryParse(_latitudController.text.trim());
          if (lat != null && (lat < -90 || lat > 90)) {
            throw Exception('Latitud debe estar entre -90 y 90');
          }
        }
        if (_longitudController.text.trim().isNotEmpty) {
          lng = double.tryParse(_longitudController.text.trim());
          if (lng != null && (lng < -180 || lng > 180)) {
            throw Exception('Longitud debe estar entre -180 y 180');
          }
        }
      }

      final codigoAcceso = _generateCodigoAcceso(_nombreController.text.trim());

      await SupabaseService.instance.createEmpresa(
        nombre: _nombreController.text.trim(),
        ruc: _rucController.text.trim().isNotEmpty ? _rucController.text.trim() : null,
        direccion: _direccionController.text.trim().isNotEmpty ? _direccionController.text.trim() : null,
        telefono: _telefonoController.text.trim().isNotEmpty ? _telefonoController.text.trim() : null,
        correo: _correoController.text.trim().isNotEmpty ? _correoController.text.trim() : null,
        empresaFotoUrl: logoUrl,
        latitud: lat,
        longitud: lng,
        codigoAcceso: codigoAcceso,
      );

      _nombreController.clear();
      _rucController.clear();
      _direccionController.clear();
      _telefonoController.clear();
      _correoController.clear();
      _latitudController.clear();
      _longitudController.clear();
      setState(() {
        _logoImage = null;
        _logoFilePath = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Empresa creada exitosamente\nCódigo de acceso: $codigoAcceso'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }

      if (mounted && Navigator.canPop(context)) Navigator.of(context).pop(true);
    } catch (e) {
      try {
        if (movedToFinal && finalFilePath != null) {
          await SupabaseService.instance.deleteFile(bucketName: 'fotos', filePath: finalFilePath);
        }
      } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al crear empresa: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _openMapPicker() async {
    // Inicio: si hay coordenadas en el form, úsalas; si no, centro en Ecuador
    LatLng initial = const LatLng(-2.8895, -79.0086);
    if (_selectedLocation != null) initial = _selectedLocation!;
    else if (_latitudController.text.isNotEmpty && _longitudController.text.isNotEmpty) {
      final lat = double.tryParse(_latitudController.text) ?? initial.latitude;
      final lng = double.tryParse(_longitudController.text) ?? initial.longitude;
      initial = LatLng(lat, lng);
    }

    final result = await showModalBottomSheet<LatLng>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        LatLng picked = initial;
        final markers = <Marker>{};
        if (_selectedLocation != null) {
          picked = _selectedLocation!;
          markers.add(Marker(markerId: const MarkerId('selected'), position: picked));
        }

        return StatefulBuilder(builder: (context, setStateModal) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Expanded(child: Text('Selecciona la ubicación', style: TextStyle(fontWeight: FontWeight.w600))),
                      TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
                    ],
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(target: initial, zoom: 15),
                      onTap: (pos) {
                        setStateModal(() {
                          picked = pos;
                          markers.clear();
                          markers.add(Marker(markerId: const MarkerId('selected'), position: picked));
                        });
                      },
                      markers: markers,
                      // Performance: avoid extra heavy gestures and buttons
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: true,
                      rotateGesturesEnabled: false,
                      tiltGesturesEnabled: false,
                      compassEnabled: false,
                      mapToolbarEnabled: false,
                      onMapCreated: (c) => _mapController = c,
                      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(child: Text('Lat: ${picked.latitude.toStringAsFixed(6)}, Lng: ${picked.longitude.toStringAsFixed(6)}')),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(picked),
                        child: const Text('Confirmar'),
                      ),
                    ],
                  ),
                )
              ],
            ),
          );
        });
      },
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result;
        _latitudController.text = result.latitude.toString();
        _longitudController.text = result.longitude.toString();
      });
      // Dispose temporary map controller to free resources and avoid retained platform view
      try {
        _mapController?.dispose();
      } catch (_) {}
      _mapController = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canCreate = _logoImage != null;
    // ignore: deprecated_member_use
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SuperadminHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text('Nueva Empresa', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700))),
                            IconButton(onPressed: () => Navigator.of(context).pop(false), icon: Icon(Icons.close, color: Colors.grey.shade700)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text('Rellena los datos básicos de la empresa', style: TextStyle(color: Colors.black54)),
                        const SizedBox(height: 12),

                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 760),
                            child: Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(children: const [
                                      CircleAvatar(backgroundColor: Color(0xFFFFECEF), child: Icon(Icons.apartment, color: Color(0xFFD92344))),
                                      SizedBox(width: 12),
                                      Expanded(child: Text('Información de la empresa', style: TextStyle(fontWeight: FontWeight.w600))),
                                    ]),
                                    const SizedBox(height: 12),

                                    GestureDetector(
                                      onTap: _showLogoOptions,
                                      child: Container(
                                        height: 120,
                                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: const Color(0xFFF3F3F3)),
                                        child: Center(
                                          child: _isUploading
                                              ? Column(mainAxisSize: MainAxisSize.min, children: const [CircularProgressIndicator(), SizedBox(height: 8), Text('Subiendo...')])
                                              : _logoImage != null
                                                  ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image(image: _logoImage!, width: double.infinity, height: 120, fit: BoxFit.cover))
                                                  : Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.cloud_upload_outlined, size: 28, color: Colors.grey.shade700), const SizedBox(height: 8), Text('Toca para subir el logo', style: TextStyle(color: Colors.grey.shade600))]),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    _buildTextField(controller: _nombreController, label: 'Nombre de la Empresa *', enabled: !_isCreating),
                                    const SizedBox(height: 8),
                                    _buildTextField(controller: _rucController, label: 'RUC', enabled: !_isCreating),
                                    const SizedBox(height: 8),
                                    _buildTextField(controller: _direccionController, label: 'Dirección', enabled: !_isCreating),
                                    const SizedBox(height: 8),
                                    _buildTextField(controller: _telefonoController, label: 'Teléfono', enabled: !_isCreating, keyboardType: TextInputType.phone),
                                    const SizedBox(height: 8),
                                    _buildTextField(controller: _correoController, label: 'Email', enabled: !_isCreating, keyboardType: TextInputType.emailAddress),
                                    const SizedBox(height: 8),
                                    _buildTextField(controller: _latitudController, label: 'Latitud', enabled: !_isCreating, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), helperText: 'Rango: -90 a 90'),
                                    const SizedBox(height: 8),
                                    _buildTextField(controller: _longitudController, label: 'Longitud', enabled: !_isCreating, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), helperText: 'Rango: -180 a 180'),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: _openMapPicker,
                                            icon: const Icon(Icons.map),
                                            label: const Text('Seleccionar ubicación en mapa'),
                                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2)),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (_selectedLocation != null)
                                          Text('${_selectedLocation!.latitude.toStringAsFixed(5)}, ${_selectedLocation!.longitude.toStringAsFixed(5)}')
                                        else if (_latitudController.text.isNotEmpty && _longitudController.text.isNotEmpty)
                                          Text('${_latitudController.text}, ${_longitudController.text}')
                                        else
                                          const SizedBox.shrink(),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    SizedBox(
                                      height: 48,
                                      child: ElevatedButton(
                                        onPressed: (canCreate && !_isCreating) ? _createEmpresa : null,
                                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD92344), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                        child: _isCreating
                                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                                            : const Text('Crear Empresa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  // Helper to keep fields consistent
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool enabled = true,
    TextInputType? keyboardType,
    String? helperText,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        filled: true,
        fillColor: const Color(0xFFF3F3F3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }
}
