import 'dart:io';

import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:path/path.dart' as p;
// logout_helper removed: no onWillPop logic here anymore
import 'widgets/superadmin_header.dart';
import '../../service/supabase_service.dart';
import '../../theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
  gmaps.LatLng? _selectedLocation;
  gmaps.GoogleMapController? _modalGoogleMapController;

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
          ],
        ),
      ),
    );

    if (!mounted) return;

    if (choice == 'remove') {
      setState(() {
        _logoImage = null;
        _logoFilePath = null;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Logo eliminado')));
      return;
    }

    if (choice == 'gallery' || choice == 'camera') {
      try {
        final XFile? picked = await _picker.pickImage(
          source: choice == 'gallery'
              ? ImageSource.gallery
              : ImageSource.camera,
          maxWidth: 1200,
          imageQuality: 85,
        );

        if (picked != null) {
          if (!mounted) return;
          setState(() {
            _logoImage = FileImage(File(picked.path));
            _logoFilePath = picked.path;
          });
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Logo seleccionado')));
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al seleccionar imagen: $e')),
          );
        }
      }
    }
  }

  String _generateCodigoAcceso(String nombre) {
    final base = nombre
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();
    final random = DateTime.now().millisecondsSinceEpoch % 1000000;
    final symbols = String.fromCharCodes(
      List.generate(2, (i) => 65 + (random + i) % 26),
    );
    return 'EMP-${base.substring(0, base.length > 4 ? 4 : base.length)}$symbols$random';
  }

  // Remove accents and invalid filename chars, replace spaces with underscores
  String _sanitizeFileName(String input) {
    if (input.isEmpty) return 'file';
    final Map<String, String> map = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'Á': 'A',
      'É': 'E',
      'Í': 'I',
      'Ó': 'O',
      'Ú': 'U',
      'ñ': 'n',
      'Ñ': 'N',
      'ü': 'u',
      'Ü': 'U',
    };
    var s = input;
    map.forEach((k, v) => s = s.replaceAll(k, v));
    // replace any non-word characters with underscore
    s = s.replaceAll(RegExp(r"[^A-Za-z0-9\-_]"), '_');
    // collapse multiple underscores
    s = s.replaceAll(RegExp(r'_+'), '_');
    // trim underscores
    s = s.replaceAll(RegExp(r'^_+|_+\$'), '');
    if (s.isEmpty) return 'file';
    return s;
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
        const SnackBar(
          content: Text('Debes seleccionar un logo para la empresa'),
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    String? finalFilePath;
    bool movedToFinal = false;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final rawName = _nombreController.text.trim();
      final safeName = _sanitizeFileName(rawName);
      // Preserve original file extension if available (allow .png, .jpg, .jpeg, etc.)
      String ext = '.jpg';
      try {
        final srcExt = p.extension(_logoFilePath ?? '').toLowerCase();
        if (srcExt.isNotEmpty) ext = srcExt;
      } catch (_) {}
      final fileName = 'empresa_${timestamp}_$safeName$ext';
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
        ruc: _rucController.text.trim().isNotEmpty
            ? _rucController.text.trim()
            : null,
        direccion: _direccionController.text.trim().isNotEmpty
            ? _direccionController.text.trim()
            : null,
        telefono: _telefonoController.text.trim().isNotEmpty
            ? _telefonoController.text.trim()
            : null,
        correo: _correoController.text.trim().isNotEmpty
            ? _correoController.text.trim()
            : null,
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
            content: Text(
              'Empresa creada exitosamente\nCódigo de acceso: $codigoAcceso',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }

      if (mounted && Navigator.canPop(context)) Navigator.of(context).pop(true);
    } catch (e) {
      try {
        if (movedToFinal && finalFilePath != null) {
          await SupabaseService.instance.deleteFile(
            bucketName: 'fotos',
            filePath: finalFilePath,
          );
        }
      } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear empresa: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _openMapPicker() async {
    // Inicio: preferir ubicación seleccionada; si no, intentar ubicación del dispositivo;
    // si no hay permisos/disponible, usar campos de lat/lng; por defecto Ecuador.
    gmaps.LatLng initial = const gmaps.LatLng(-2.8895, -79.0086);
    if (_selectedLocation != null) {
      initial = _selectedLocation!;
    } else {
      try {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.always ||
              permission == LocationPermission.whileInUse) {
            final pos = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
              ),
            );
            initial = gmaps.LatLng(pos.latitude, pos.longitude);
          }
        }
      } catch (_) {}

      // If still default and form fields are filled, use them
      if (initial.latitude == -2.8895 && initial.longitude == -79.0086) {
        if (_latitudController.text.isNotEmpty &&
            _longitudController.text.isNotEmpty) {
          final lat =
              double.tryParse(_latitudController.text) ?? initial.latitude;
          final lng =
              double.tryParse(_longitudController.text) ?? initial.longitude;
          initial = gmaps.LatLng(lat, lng);
        }
      }
    }

    // Prepare modal-scoped search state so results persist across setStateModal
    final TextEditingController modalSearchController = TextEditingController();
    List<Map<String, dynamic>> modalResults = [];
    Timer? modalDebounce;

    Future<void> doModalSearch(
      String q,
      void Function(void Function()) setStateModal,
    ) async {
      modalDebounce?.cancel();
      modalDebounce = Timer(const Duration(milliseconds: 350), () async {
        if (q.trim().isEmpty) {
          setStateModal(() {
            modalResults = [];
          });
          return;
        }
        setStateModal(() {
          modalResults = [];
        });
        try {
          final res = await SupabaseService.instance.geocodeSearch(q, limit: 6);
          setStateModal(() {
            modalResults = res;
          });
        } catch (_) {
          setStateModal(() {
            modalResults = [];
          });
        } finally {
          setStateModal(() {});
        }
      });
    }

    final result = await showModalBottomSheet<gmaps.LatLng>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        gmaps.LatLng picked = initial;
        double modalZoom = 15.0;
        final Set<gmaps.Marker> markers = {};

        return StatefulBuilder(
          builder: (context, setStateModal) {
            // Ensure initial draggable marker if a location was previously selected
            if (markers.isEmpty && _selectedLocation != null) {
              picked = _selectedLocation!;
              markers.add(
                gmaps.Marker(
                  markerId: gmaps.MarkerId(
                    '${picked.latitude}_${picked.longitude}',
                  ),
                  position: gmaps.LatLng(picked.latitude, picked.longitude),
                  draggable: true,
                  onDragEnd: (newPos) {
                    setStateModal(() {
                      picked = gmaps.LatLng(newPos.latitude, newPos.longitude);
                      markers.clear();
                      markers.add(
                        gmaps.Marker(
                          markerId: gmaps.MarkerId(
                            '${newPos.latitude}_${newPos.longitude}',
                          ),
                          position: gmaps.LatLng(
                            newPos.latitude,
                            newPos.longitude,
                          ),
                          draggable: true,
                        ),
                      );
                    });
                  },
                ),
              );
            }

            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Selecciona la ubicación',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cerrar'),
                        ),
                      ],
                    ),
                  ),

                  // Search field
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: modalSearchController,
                          decoration: InputDecoration(
                            hintText: 'Buscar dirección o lugar',
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.grey,
                            ),
                            suffixIcon: modalSearchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      modalSearchController.clear();
                                      setStateModal(() => modalResults = []);
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          onChanged: (v) => doModalSearch(v, setStateModal),
                          onSubmitted: (v) async {
                            await doModalSearch(v, setStateModal);
                          },
                        ),

                        // Results list
                        if (modalResults.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  // ignore: deprecated_member_use
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.of(context).size.height * 0.25,
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: modalResults.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (ctx, i) {
                                final r = modalResults[i];
                                final display =
                                    r['display_name'] ?? r['description'] ?? '';
                                return ListTile(
                                  title: Text(display.toString()),
                                  onTap: () async {
                                    final lat =
                                        double.tryParse(
                                          r['lat']?.toString() ?? '',
                                        ) ??
                                        double.tryParse(
                                          r['latitud']?.toString() ?? '',
                                        );
                                    final lon =
                                        double.tryParse(
                                          r['lon']?.toString() ?? '',
                                        ) ??
                                        double.tryParse(
                                          r['longitud']?.toString() ?? '',
                                        );
                                    if (lat != null && lon != null) {
                                      setStateModal(() {
                                        picked = gmaps.LatLng(lat, lon);
                                        markers.clear();
                                        markers.add(
                                          gmaps.Marker(
                                            markerId: gmaps.MarkerId(
                                              '${lat}_${lon}',
                                            ),
                                            position: gmaps.LatLng(lat, lon),
                                            draggable: true,
                                            onDragEnd: (newPos) {
                                              setStateModal(() {
                                                picked = gmaps.LatLng(
                                                  newPos.latitude,
                                                  newPos.longitude,
                                                );
                                                markers.clear();
                                                markers.add(
                                                  gmaps.Marker(
                                                    markerId: gmaps.MarkerId(
                                                      '${newPos.latitude}_${newPos.longitude}',
                                                    ),
                                                    position: gmaps.LatLng(
                                                      newPos.latitude,
                                                      newPos.longitude,
                                                    ),
                                                    draggable: true,
                                                  ),
                                                );
                                              });
                                            },
                                          ),
                                        );
                                        modalResults = [];
                                        modalSearchController.text = display
                                            .toString();
                                      });
                                      try {
                                        if (_modalGoogleMapController != null) {
                                          _modalGoogleMapController!
                                              .animateCamera(
                                                gmaps
                                                    .CameraUpdate.newLatLngZoom(
                                                  gmaps.LatLng(lat, lon),
                                                  modalZoom,
                                                ),
                                              );
                                        }
                                      } catch (_) {}
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: double.infinity,
                            height: double.infinity,
                            child: gmaps.GoogleMap(
                              initialCameraPosition: gmaps.CameraPosition(
                                target: gmaps.LatLng(
                                  initial.latitude,
                                  initial.longitude,
                                ),
                                zoom: modalZoom,
                              ),
                              onMapCreated: (ctrl) {
                                _modalGoogleMapController = ctrl;
                              },
                              onTap: (pos) {
                                setStateModal(() {
                                  picked = gmaps.LatLng(
                                    pos.latitude,
                                    pos.longitude,
                                  );
                                  markers.clear();
                                  markers.add(
                                    gmaps.Marker(
                                      markerId: gmaps.MarkerId(
                                        '${pos.latitude}_${pos.longitude}',
                                      ),
                                      position: gmaps.LatLng(
                                        pos.latitude,
                                        pos.longitude,
                                      ),
                                      draggable: true,
                                      onDragEnd: (newPos) {
                                        setStateModal(() {
                                          picked = gmaps.LatLng(
                                            newPos.latitude,
                                            newPos.longitude,
                                          );
                                          markers.clear();
                                          markers.add(
                                            gmaps.Marker(
                                              markerId: gmaps.MarkerId(
                                                '${newPos.latitude}_${newPos.longitude}',
                                              ),
                                              position: gmaps.LatLng(
                                                newPos.latitude,
                                                newPos.longitude,
                                              ),
                                              draggable: true,
                                            ),
                                          );
                                        });
                                      },
                                    ),
                                  );
                                });
                              },
                              markers: markers,
                              zoomControlsEnabled: false,
                              myLocationButtonEnabled: false,
                              mapToolbarEnabled: false,
                              gestureRecognizers:
                                  <Factory<OneSequenceGestureRecognizer>>{
                                    Factory<OneSequenceGestureRecognizer>(
                                      () => EagerGestureRecognizer(),
                                    ),
                                  },
                            ),
                          ),
                        ),

                        // Zoom controls (top-right)
                        Positioned(
                          right: 12,
                          top: 12,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Material(
                                color: Colors.white,
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  padding: const EdgeInsets.all(6),
                                  icon: const Icon(Icons.add, size: 20),
                                  onPressed: () async {
                                    try {
                                      modalZoom = (modalZoom + 1).clamp(1, 20);
                                      if (_modalGoogleMapController != null) {
                                        _modalGoogleMapController!
                                            .animateCamera(
                                              gmaps.CameraUpdate.newLatLngZoom(
                                                gmaps.LatLng(
                                                  picked.latitude,
                                                  picked.longitude,
                                                ),
                                                modalZoom,
                                              ),
                                            );
                                      }
                                      setStateModal(() {});
                                    } catch (_) {}
                                  },
                                ),
                              ),
                              const SizedBox(height: 6),
                              Material(
                                color: Colors.white,
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  padding: const EdgeInsets.all(6),
                                  icon: const Icon(Icons.remove, size: 20),
                                  onPressed: () async {
                                    try {
                                      modalZoom = (modalZoom - 1).clamp(1, 20);
                                      if (_modalGoogleMapController != null) {
                                        _modalGoogleMapController!
                                            .animateCamera(
                                              gmaps.CameraUpdate.newLatLngZoom(
                                                gmaps.LatLng(
                                                  picked.latitude,
                                                  picked.longitude,
                                                ),
                                                modalZoom,
                                              ),
                                            );
                                      }
                                      setStateModal(() {});
                                    } catch (_) {}
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Center-on-picked control (bottom-right over map)
                        Positioned(
                          right: 12,
                          bottom: 12 + 56, // above the confirm row
                          child: Material(
                            color: Colors.white,
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              padding: const EdgeInsets.all(8),
                              icon: const Icon(Icons.my_location, size: 20),
                              onPressed: () async {
                                try {
                                  modalZoom = 17;
                                  if (_modalGoogleMapController != null) {
                                    _modalGoogleMapController!.animateCamera(
                                      gmaps.CameraUpdate.newLatLngZoom(
                                        gmaps.LatLng(
                                          picked.latitude,
                                          picked.longitude,
                                        ),
                                        modalZoom,
                                      ),
                                    );
                                  }
                                  setStateModal(() {});
                                } catch (_) {}
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Lat: ${picked.latitude.toStringAsFixed(6)}, Lng: ${picked.longitude.toStringAsFixed(6)}',
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(picked),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24.r),
                            ),
                          ),
                          child: const Text('Confirmar'),
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

    if (result != null) {
      setState(() {
        _selectedLocation = result;
        _latitudController.text = result.latitude.toString();
        _longitudController.text = result.longitude.toString();
      });
      // clear modal controller ref
      _modalGoogleMapController = null;
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
                          Expanded(
                            child: Text(
                              'Nueva Empresa',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            icon: Icon(Icons.close, color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Rellena los datos básicos de la empresa',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 12),

                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 760),
                          child: Card(
                            color: AppColors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: AppColors.surfaceSoft,
                                        child: const Icon(
                                          Icons.apartment,
                                          color: AppColors.accentBlue,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Información de la empresa',
                                          style: AppTextStyles.sectionTitle,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  GestureDetector(
                                    onTap: _showLogoOptions,
                                    child: Container(
                                      height: 120,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: AppColors.surfaceSoft,
                                      ),
                                      child: Center(
                                        child: _isUploading
                                            ? Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: const [
                                                  CircularProgressIndicator(),
                                                  SizedBox(height: 8),
                                                  Text('Subiendo...'),
                                                ],
                                              )
                                            : _logoImage != null
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image(
                                                  image: _logoImage!,
                                                  width: double.infinity,
                                                  height: 120,
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            : Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.cloud_upload_outlined,
                                                    size: 28,
                                                    color: AppColors.mutedGray,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Toca para subir el logo',
                                                    style: AppTextStyles
                                                        .smallLabel
                                                        .copyWith(
                                                          color: AppColors
                                                              .mutedGray,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  _buildTextField(
                                    controller: _nombreController,
                                    label: 'Nombre de la Empresa *',
                                    enabled: !_isCreating,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: _rucController,
                                    label: 'RUC',
                                    enabled: !_isCreating,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: _direccionController,
                                    label: 'Dirección',
                                    enabled: !_isCreating,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: _telefonoController,
                                    label: 'Teléfono',
                                    enabled: !_isCreating,
                                    keyboardType: TextInputType.phone,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: _correoController,
                                    label: 'Email',
                                    enabled: !_isCreating,
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  // Lat/Lng inputs hidden — coordinates set via map picker
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: _openMapPicker,
                                          icon: const Icon(Icons.map),
                                          label: const Text(
                                            'Seleccionar ubicación en mapa',
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppColors.accentBlue,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (_selectedLocation != null)
                                        Text(
                                          '${_selectedLocation!.latitude.toStringAsFixed(5)}, ${_selectedLocation!.longitude.toStringAsFixed(5)}',
                                        )
                                      else if (_latitudController
                                              .text
                                              .isNotEmpty &&
                                          _longitudController.text.isNotEmpty)
                                        Text(
                                          '${_latitudController.text}, ${_longitudController.text}',
                                        )
                                      else
                                        const SizedBox.shrink(),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  SizedBox(
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: (canCreate && !_isCreating)
                                          ? _createEmpresa
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      child: _isCreating
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                            )
                                          : const Text(
                                              'Crear Empresa',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Color.fromARGB(
                                                  255,
                                                  255,
                                                  255,
                                                  255,
                                                ),
                                              ),
                                            ),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
