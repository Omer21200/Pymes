import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
// Using google_maps_flutter for all map interactions (view + edit)
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import '../../service/supabase_service.dart';
import '../../theme.dart';
import '../../config/google_maps_config.dart';
import 'creacion_departamentos.dart';
import 'departamento_detalle.dart';
import 'widgets/superadmin_header.dart';

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
  List<Map<String, dynamic>> _departamentos = [];
  bool _loading = true;
  bool _saving = false;
  bool _loadingDepartamentos = true;
  bool _editing = false;
  Map<String, String> _backup = {};

  // Backup coordinates when entering edit mode so Cancel can restore them
  double? _backupLat;
  double? _backupLng;

  double? _companyLat;
  double? _companyLng;
  bool _locatingCompany = false;
  // Search state for map/address picker
  final TextEditingController _mapSearchController = TextEditingController();
  List<Map<String, dynamic>> _mapSearchResults = [];
  bool _searchingMap = false;
  Timer? _mapSearchDebounce;
  gmaps.GoogleMapController? _googleMapController;
  final TextEditingController _nombre = TextEditingController();
  final TextEditingController _ruc = TextEditingController();
  final TextEditingController _direccion = TextEditingController();
  final TextEditingController _telefono = TextEditingController();
  final TextEditingController _correo = TextEditingController();
  final TextEditingController _lat = TextEditingController();
  final TextEditingController _lng = TextEditingController();

  String? _newLogoLocalPath;
  String? _currentLogoUrl;
  final ImagePicker _picker = ImagePicker();

  double _mapZoom = 15.0;

  void _onMapSearchChanged(String v) {
    _mapSearchDebounce?.cancel();
    _mapSearchDebounce = Timer(const Duration(milliseconds: 350), () {
      _performMapSearch(v);
    });
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final data = await SupabaseService.instance.getEmpresaById(
        widget.empresaId,
      );
      if (data != null) _setEmpresa(data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar empresa: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchDepartamentos() async {
    setState(() => _loadingDepartamentos = true);
    try {
      final data = await SupabaseService.instance.getDepartamentosPorEmpresa(
        widget.empresaId,
      );
      if (mounted) setState(() => _departamentos = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar departamentos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingDepartamentos = false);
    }
  }

  void _setEmpresa(Map<String, dynamic> e) {
    _empresa = e;
    _nombre.text = e['nombre'] ?? '';
    _ruc.text = e['ruc'] ?? '';
    _direccion.text = e['direccion'] ?? '';
    _telefono.text = e['telefono'] ?? '';
    _correo.text = e['correo'] ?? '';
    _lat.text = (e['latitud']?.toString() ?? '');
    _lng.text = (e['longitud']?.toString() ?? '');
    // set company coords if present
    _companyLat = e['latitud'] is num
        ? (e['latitud'] as num).toDouble()
        : double.tryParse(_lat.text);
    _companyLng = e['longitud'] is num
        ? (e['longitud'] as num).toDouble()
        : double.tryParse(_lng.text);
    _currentLogoUrl = e['empresa_foto_url'] as String?;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialEmpresa != null) {
      _setEmpresa(widget.initialEmpresa!);
      _loading = false;
    }
    _fetch();
    _fetchDepartamentos();
  }

  void _enterEdit() {
    _backup = {
      'nombre': _nombre.text,
      'ruc': _ruc.text,
      'direccion': _direccion.text,
      'telefono': _telefono.text,
      'correo': _correo.text,
      'lat': _lat.text,
      'lng': _lng.text,
    };
    // store current coordinates so we can restore on cancel
    _backupLat = _companyLat;
    _backupLng = _companyLng;
    setState(() => _editing = true);
  }

  void _cancelEdit() {
    _nombre.text = _backup['nombre'] ?? '';
    _ruc.text = _backup['ruc'] ?? '';
    _direccion.text = _backup['direccion'] ?? '';
    _telefono.text = _backup['telefono'] ?? '';
    _correo.text = _backup['correo'] ?? '';
    _lat.text = _backup['lat'] ?? '';
    _lng.text = _backup['lng'] ?? '';
    // restore backed-up coordinates (if any) and move camera back
    if (_backupLat != null && _backupLng != null) {
      setState(() {
        _companyLat = _backupLat;
        _companyLng = _backupLng;
        _lat.text = _companyLat?.toString() ?? '';
        _lng.text = _companyLng?.toString() ?? '';
        _editing = false;
      });
      try {
        _googleMapController?.animateCamera(
          gmaps.CameraUpdate.newCameraPosition(
            gmaps.CameraPosition(
              target: gmaps.LatLng(_companyLat ?? 0.0, _companyLng ?? 0.0),
              zoom: _mapZoom,
            ),
          ),
        );
      } catch (_) {}
    } else {
      setState(() => _editing = false);
    }
  }

  Future<void> _ensureCompanyLocation() async {
    if (_companyLat != null && _companyLng != null) return;
    final latFromField = double.tryParse(_lat.text.trim());
    final lngFromField = double.tryParse(_lng.text.trim());
    if (latFromField != null && lngFromField != null) {
      setState(() {
        _companyLat = latFromField;
        _companyLng = lngFromField;
      });
      return;
    }

    final address = _direccion.text.trim();
    if (address.isEmpty) return;

    setState(() => _locatingCompany = true);
    try {
      final coords = await SupabaseService.instance.geocodeAddress(address);
      if (coords != null && coords.length == 2) {
        setState(() {
          // ignore: collection_methods_unrelated_type
          _companyLat = coords[0];
          // ignore: collection_methods_unrelated_type
          _companyLng = coords[1];
          // also update hidden lat/lng fields so they get saved
          _lat.text = _companyLat!.toString();
          _lng.text = _companyLng!.toString();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _locatingCompany = false);
  }

  Future<void> _performMapSearch(String q) async {
    if (q.trim().isEmpty) {
      setState(() {
        _mapSearchResults = [];
      });
      return;
    }
    setState(() {
      _searchingMap = true;
      _mapSearchResults = [];
    });
    try {
      // If editing and a Google API key is available, use Places Autocomplete for better suggestions
      List<Map<String, dynamic>> results = [];
      if (_editing && googleMapsApiKey.trim().isNotEmpty) {
        try {
          final encoded = Uri.encodeComponent(q);
          final url = Uri.parse(
            'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$encoded&key=$googleMapsApiKey&language=es&types=geocode|establishment',
          );
          final resp = await http.get(url).timeout(const Duration(seconds: 6));
          if (resp.statusCode == 200) {
            final data = jsonDecode(resp.body) as Map<String, dynamic>;
            final preds = (data['predictions'] as List<dynamic>?) ?? [];
            results = preds.map((p) {
              final m = Map<String, dynamic>.from(p as Map<String, dynamic>);
              return {
                'display_name':
                    m['description'] ??
                    m['structured_formatting']?['main_text'] ??
                    '',
                'description': m['description'] ?? '',
                'place_id': m['place_id'] ?? '',
              };
            }).toList();
          }
        } catch (_) {
          results = [];
        }
      }

      // Fallback to Nominatim if Google not used or returned nothing
      if (results.isEmpty) {
        final nom = await SupabaseService.instance.geocodeSearch(q, limit: 6);
        results = nom;
      }

      if (mounted) setState(() => _mapSearchResults = results);
    } catch (_) {
      if (mounted) setState(() => _mapSearchResults = []);
    } finally {
      if (mounted) setState(() => _searchingMap = false);
    }
  }

  Future<void> _selectMapSearchResult(Map<String, dynamic> item) async {
    double? lat;
    double? lon;
    String? display = item['display_name'] ?? item['description'];

    final placeId = item['place_id']?.toString();
    if (placeId != null &&
        placeId.isNotEmpty &&
        googleMapsApiKey.trim().isNotEmpty) {
      // Resolve place details to get lat/lng
      try {
        final encoded = Uri.encodeComponent(placeId);
        final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/details/json?place_id=$encoded&key=$googleMapsApiKey&language=es',
        );
        final resp = await http.get(url).timeout(const Duration(seconds: 6));
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          final res = data['result'] as Map<String, dynamic>?;
          if (res != null) {
            display = res['formatted_address'] as String? ?? display;
            final geom = res['geometry'] as Map<String, dynamic>?;
            final loc = geom != null
                ? (geom['location'] as Map<String, dynamic>?)
                : null;
            if (loc != null) {
              lat = (loc['lat'] is num)
                  ? (loc['lat'] as num).toDouble()
                  : double.tryParse(loc['lat']?.toString() ?? '');
              lon = (loc['lng'] is num)
                  ? (loc['lng'] as num).toDouble()
                  : double.tryParse(loc['lng']?.toString() ?? '');
            }
          }
        }
      } catch (_) {}
    }

    lat ??= double.tryParse(item['lat']?.toString() ?? '');
    lon ??= double.tryParse(item['lon']?.toString() ?? '');

    if (lat == null || lon == null) return;

    setState(() {
      _companyLat = lat;
      _companyLng = lon;
      _lat.text = lat.toString();
      _lng.text = lon.toString();
      _mapSearchResults = [];
      _mapSearchController.text = display ?? '';
    });

    // Move map to selected position
  }

  Future<void> _pickLogo() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (x != null) {
      setState(() => _newLogoLocalPath = x.path);
    }
  }

  Future<void> _save() async {
    if (_empresa == null) return;
    setState(() => _saving = true);

    String? finalPath;
    bool moved = false;
    String? logoUrl;

    try {
      if (_newLogoLocalPath != null) {
        final ts = DateTime.now().millisecondsSinceEpoch;
        final safe = _nombre.text.trim().replaceAll(' ', '_');
        final fileName = 'empresa_${ts}_$safe.jpg';
        finalPath = 'empresas/$fileName';

        logoUrl = await SupabaseService.instance.uploadFile(
          filePath: _newLogoLocalPath!,
          bucketName: 'fotos',
          destinationPath: finalPath,
        );
        moved = true;
      }

      double? lat = double.tryParse(_lat.text.trim());
      double? lng = double.tryParse(_lng.text.trim());

      await SupabaseService.instance.updateEmpresa(
        empresaId: widget.empresaId,
        nombre: _nombre.text.trim().isEmpty ? null : _nombre.text.trim(),
        ruc: _ruc.text.trim().isEmpty ? null : _ruc.text.trim(),
        direccion: _direccion.text.trim().isEmpty
            ? null
            : _direccion.text.trim(),
        telefono: _telefono.text.trim().isEmpty ? null : _telefono.text.trim(),
        correo: _correo.text.trim().isEmpty ? null : _correo.text.trim(),
        empresaFotoUrl: logoUrl,
        latitud: lat,
        longitud: lng,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cambios guardados'),
            backgroundColor: Colors.green,
          ),
        );
      }
      await _fetch();
      // saved successfully — clear edit backups
      _backup = {};
      _backupLat = null;
      _backupLng = null;
      setState(() => _newLogoLocalPath = null);
    } catch (e) {
      if (moved && finalPath != null) {
        try {
          await SupabaseService.instance.deleteFile(
            bucketName: 'fotos',
            filePath: finalPath,
          );
        } catch (_) {}
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SuperadminHeader(
                showBack: true,
                onBack: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.all(16),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: _saving ? null : _pickLogo,
                            child: Container(
                              height: 150,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F3F3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: _newLogoLocalPath != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          File(_newLogoLocalPath!),
                                          height: 150,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : (_currentLogoUrl != null
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Image.network(
                                                _currentLogoUrl!,
                                                height: 150,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => const Icon(
                                                      Icons.image_not_supported,
                                                    ),
                                              ),
                                            )
                                          : const Icon(
                                              Icons.add_a_photo_outlined,
                                              size: 36,
                                            )),
                              ),
                            ),
                          ),
                          Container(
                            decoration: AppDecorations.card,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_empresa?['codigo_acceso_empleado'] != null)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFECEF),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.key,
                                          color: Color(0xFFD92344),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Código de acceso: ${_empresa!['codigo_acceso_empleado']}',
                                            style: AppTextStyles.smallLabel,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                _buildField('Nombre', _nombre),
                                _buildField('RUC', _ruc),
                                _buildField('Dirección', _direccion),
                                _buildField('Teléfono', _telefono),
                                _buildField(
                                  'Email',
                                  _correo,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 12),
                                if (_editing)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextButton(
                                          onPressed: _saving
                                              ? null
                                              : _cancelEdit,
                                          child: const Text('Cancelar'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: SizedBox(
                                          height: 48,
                                          child: ElevatedButton(
                                            onPressed: _saving
                                                ? null
                                                : () async {
                                                    await _save();
                                                    if (mounted) {
                                                      setState(
                                                        () => _editing = false,
                                                      );
                                                    }
                                                  },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.primary,
                                              foregroundColor: Colors.white,
                                              shape: const StadiumBorder(),
                                            ),
                                            child: _saving
                                                ? const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white,
                                                        ),
                                                  )
                                                : const Text(
                                                    'Guardar',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
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
                            ),
                          ),

                          // Company location map (replace raw lat/lng fields)
                          const SizedBox(height: 8),
                          Text(
                            'Ubicación de la empresa',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          // Search box for address/place (visible when editing)
                          if (_editing) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 0.0,
                                vertical: 8,
                              ),
                              child: TextField(
                                controller: _mapSearchController,
                                decoration: InputDecoration(
                                  hintText: 'Buscar dirección o lugar',
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon: _searchingMap
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : (_mapSearchController.text.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(Icons.clear),
                                                onPressed: () {
                                                  _mapSearchController.clear();
                                                  setState(
                                                    () =>
                                                        _mapSearchResults = [],
                                                  );
                                                },
                                              )
                                            : null),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                ),
                                onChanged: _onMapSearchChanged,
                                onSubmitted: (v) => _performMapSearch(v),
                              ),
                            ),
                            if (_mapSearchResults.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 0,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      // ignore: deprecated_member_use
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxHeight: 200,
                                  ),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    itemCount: _mapSearchResults.length,
                                    separatorBuilder: (_, _) =>
                                        const Divider(height: 1),
                                    itemBuilder: (ctx, i) {
                                      final item = _mapSearchResults[i];
                                      return ListTile(
                                        title: Text(
                                          item['display_name']
                                                  ?.toString()
                                                  .split(',')
                                                  .first ??
                                              '',
                                        ),
                                        subtitle: Text(
                                          item['display_name']?.toString() ??
                                              '',
                                        ),
                                        onTap: () =>
                                            _selectMapSearchResult(item),
                                      );
                                    },
                                  ),
                                ),
                              ),
                          ],

                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            child: SizedBox(
                              height: 200,
                              child: _locatingCompany
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : (_companyLat != null && _companyLng != null)
                                  ? Stack(
                                      children: [
                                        // Show GoogleMap when not editing (nicer tiles),
                                        // keep FlutterMap available when editing so user
                                        // can tap to change coords.
                                        // Use Google Map for both view and edit. In edit mode taps/drags update coords.
                                        gmaps.GoogleMap(
                                          initialCameraPosition:
                                              gmaps.CameraPosition(
                                                target: gmaps.LatLng(
                                                  _companyLat!,
                                                  _companyLng!,
                                                ),
                                                zoom: _mapZoom,
                                              ),
                                          markers: {
                                            gmaps.Marker(
                                              markerId: const gmaps.MarkerId(
                                                'company',
                                              ),
                                              position: gmaps.LatLng(
                                                _companyLat!,
                                                _companyLng!,
                                              ),
                                              draggable: _editing,
                                              onDragEnd: (pos) {
                                                setState(() {
                                                  _companyLat = pos.latitude;
                                                  _companyLng = pos.longitude;
                                                  _lat.text = _companyLat!
                                                      .toString();
                                                  _lng.text = _companyLng!
                                                      .toString();
                                                });
                                                if (mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Ubicación actualizada en el mapa',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                          },
                                          zoomControlsEnabled: false,
                                          myLocationButtonEnabled: false,
                                          onMapCreated: (ctrl) =>
                                              _googleMapController = ctrl,
                                          onTap: (pos) {
                                            if (_editing) {
                                              setState(() {
                                                _companyLat = pos.latitude;
                                                _companyLng = pos.longitude;
                                                _lat.text = _companyLat!
                                                    .toString();
                                                _lng.text = _companyLng!
                                                    .toString();
                                              });
                                              if (mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Ubicación actualizada en el mapa',
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                        ),

                                        // Controls: recenter + zoom
                                        Positioned(
                                          right: 8,
                                          top: 8,
                                          child: Column(
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black12,
                                                      blurRadius: 6,
                                                    ),
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
                                                        if (_companyLat !=
                                                                null &&
                                                            _companyLng !=
                                                                null) {
                                                          // Use Google map controller for camera moves
                                                          if (_googleMapController !=
                                                              null) {
                                                            _googleMapController!.animateCamera(
                                                              gmaps
                                                                  .CameraUpdate.newCameraPosition(
                                                                gmaps.CameraPosition(
                                                                  target: gmaps.LatLng(
                                                                    _companyLat!,
                                                                    _companyLng!,
                                                                  ),
                                                                  zoom:
                                                                      _mapZoom,
                                                                ),
                                                              ),
                                                            );
                                                          }
                                                        }
                                                      },
                                                    ),
                                                    const Divider(height: 1),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.add,
                                                        size: 20,
                                                      ),
                                                      onPressed: () {
                                                        _mapZoom =
                                                            (_mapZoom + 1)
                                                                .clamp(1, 20);
                                                        if (_companyLat !=
                                                                null &&
                                                            _companyLng !=
                                                                null) {
                                                          if (_googleMapController !=
                                                              null) {
                                                            _googleMapController!
                                                                .animateCamera(
                                                                  gmaps
                                                                      .CameraUpdate.zoomTo(
                                                                    _mapZoom,
                                                                  ),
                                                                );
                                                          }
                                                        }
                                                      },
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.remove,
                                                        size: 20,
                                                      ),
                                                      onPressed: () {
                                                        _mapZoom =
                                                            (_mapZoom - 1)
                                                                .clamp(1, 20);
                                                        if (_companyLat !=
                                                                null &&
                                                            _companyLng !=
                                                                null) {
                                                          if (_googleMapController !=
                                                              null) {
                                                            _googleMapController!
                                                                .animateCamera(
                                                                  gmaps
                                                                      .CameraUpdate.zoomTo(
                                                                    _mapZoom,
                                                                  ),
                                                                );
                                                          }
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  : Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'No se encontraron coordenadas para esta empresa',
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          if (_editing)
                                            ElevatedButton(
                                              onPressed: _ensureCompanyLocation,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    AppColors.primary,
                                              ),
                                              child: const Text(
                                                'Obtener desde la dirección',
                                              ),
                                            )
                                          else
                                            Text(
                                              'Pulsa "Editar" para mover la ubicación en el mapa',
                                              style: AppTextStyles.smallLabel
                                                  .copyWith(
                                                    color: AppColors.mutedGray,
                                                  ),
                                            ),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Card(
                            color: AppColors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: AppColors.surfaceSoft,
                                        child: const Icon(
                                          Icons.business_center_outlined,
                                          color: AppColors.accentBlue,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Text(
                                          'Departamentos',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          final result =
                                              await Navigator.of(
                                                context,
                                              ).push<bool>(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      CreacionDepartamentos(
                                                        empresaId:
                                                            widget.empresaId,
                                                      ),
                                                ),
                                              );
                                          if (result == true) {
                                            _fetchDepartamentos();
                                          }
                                        },
                                        icon: Icon(
                                          Icons.add,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                        label: const Text('Añadir'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _loadingDepartamentos
                                      ? const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(24.0),
                                            child: CircularProgressIndicator(),
                                          ),
                                        )
                                      : _departamentos.isEmpty
                                      ? Center(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 24.0,
                                            ),
                                            child: Column(
                                              children: [
                                                Icon(
                                                  Icons.hourglass_empty,
                                                  color: Colors.grey.shade400,
                                                  size: 32,
                                                ),
                                                const SizedBox(height: 8),
                                                const Text(
                                                  'No hay departamentos creados.',
                                                  style: TextStyle(
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      : ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: _departamentos.length,
                                          itemBuilder: (context, index) {
                                            final depto = _departamentos[index];
                                            final bg = index.isEven
                                                ? AppColors.surface
                                                : AppColors.surfaceSoft;
                                            return Card(
                                              color: bg,
                                              margin: const EdgeInsets.only(
                                                bottom: 8,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              elevation: 2,
                                              child: InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                onTap: () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          DepartamentoDetallePage(
                                                            departamentoId:
                                                                depto['id'],
                                                            departamentoNombre:
                                                                depto['nombre'] ??
                                                                'Sin nombre',
                                                          ),
                                                    ),
                                                  );
                                                },
                                                child: Row(
                                                  children: [
                                                    // left accent stripe (use soft blue instead of pink)
                                                    Container(
                                                      width: 8,
                                                      height: 72,
                                                      decoration: BoxDecoration(
                                                        color: AppColors
                                                            .accentBlue
                                                            // ignore: deprecated_member_use
                                                            .withOpacity(0.12),
                                                        borderRadius:
                                                            const BorderRadius.only(
                                                              topLeft:
                                                                  Radius.circular(
                                                                    12,
                                                                  ),
                                                              bottomLeft:
                                                                  Radius.circular(
                                                                    12,
                                                                  ),
                                                            ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    CircleAvatar(
                                                      backgroundColor:
                                                          AppColors.surfaceSoft,
                                                      child: const Icon(
                                                        Icons
                                                            .business_center_outlined,
                                                        color: AppColors
                                                            .accentBlue,
                                                        size: 20,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              vertical: 16,
                                                            ),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              depto['nombre'] ??
                                                                  'Sin nombre',
                                                              style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                fontSize: 16,
                                                              ),
                                                            ),
                                                            if (depto['descripcion'] !=
                                                                null)
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets.only(
                                                                      top: 6,
                                                                    ),
                                                                child: Text(
                                                                  depto['descripcion'] ??
                                                                      '',
                                                                  style: AppTextStyles
                                                                      .smallLabel,
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      width: 40,
                                                      height: 40,
                                                      decoration: BoxDecoration(
                                                        color: AppColors
                                                            .surfaceSoft,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Icon(
                                                        Icons.chevron_right,
                                                        color: Colors
                                                            .grey
                                                            .shade400,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                  ],
                                                ),
                                              ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        enabled: _editing,
        keyboardType: keyboardType,
        style: AppTextStyles.subtitle.copyWith(
          color: AppColors.darkText,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 12,
          ),
          labelText: label,
          labelStyle: AppTextStyles.smallLabel.copyWith(
            color: AppColors.mutedGray,
          ),
          filled: true,
          fillColor: AppColors.surfaceSoft,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
