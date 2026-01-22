import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../service/supabase_service.dart';
import '../../theme.dart';
import '../../widgets/profile_view.dart';

class EmpleadoProfilePage extends StatefulWidget {
  const EmpleadoProfilePage({super.key});

  @override
  State<EmpleadoProfilePage> createState() => _EmpleadoProfilePageState();
}

class _EmpleadoProfilePageState extends State<EmpleadoProfilePage> {
  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _departamentoController = TextEditingController();

  String? _email;
  String? _fotoUrl;
  File? _selectedImageFile;
  double? _companyLat;
  double? _companyLng;
  double? _companyRadius;
  String? _companyName;
  List<Map<String, dynamic>>? _departamentos;
  String? _departamentoId;
  double? _userLat;
  double? _userLng;
  String? _userRole;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _cedulaController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _departamentoController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await SupabaseService.instance.getEmpleadoActual();
      if (data == null) return;
      // Fetch empresa details if available
      String? empresaId = data['empresa_id']?.toString();
      Map<String, dynamic>? empresaData;
      if (empresaId != null) {
        try {
          empresaData = await SupabaseService.instance.getEmpresaById(
            empresaId,
          );
          // store empresaId and direccion for later geocoding
          if (empresaData != null) {
            _empresaId = empresaId;
            _empresaDireccion = empresaData['direccion']?.toString();
          }
        } catch (_) {
          empresaData = null;
        }
      }

      final empleadoRaw = data['empleado_raw'] as Map<String, dynamic>?;
      setState(() {
        _nombresController.text = data['nombres'] ?? '';
        _apellidosController.text = data['apellidos'] ?? '';
        _cedulaController.text = empleadoRaw?['cedula']?.toString() ?? '';
        _telefonoController.text = empleadoRaw?['telefono']?.toString() ?? '';
        _direccionController.text = empleadoRaw?['direccion']?.toString() ?? '';
        _email = data['correo']?.toString();
        final profileRaw = data['profile_raw'] as Map<String, dynamic>?;
        _fotoUrl = profileRaw?['foto_url'] as String?;
        _userRole = profileRaw?['rol'] as String?;
        _companyName = empresaData?['nombre'] as String?;
        final lat = empresaData?['latitud'];
        final lng = empresaData?['longitud'];
        double? companyRadius;
        final radiusCandidates = [
          'allowed_radius_m',
          'radius_m',
          'radio',
          'geofence_radius',
          'rango',
          'radius',
        ];
        for (final k in radiusCandidates) {
          final rv = empresaData?[k];
          if (rv != null) {
            final parsed = rv is num ? rv.toDouble() : double.tryParse('$rv');
            if (parsed != null && parsed > 0) {
              companyRadius = parsed;
              break;
            }
          }
        }
        double? parseCoord(dynamic v) {
          if (v == null) return null;
          if (v is num) return v.toDouble();
          return double.tryParse(v.toString());
        }

        _companyLat = parseCoord(lat);
        _companyLng = parseCoord(lng);
        _companyRadius = companyRadius;
      });

      // load departamentos for this empresa (if any)
      try {
        if (empresaId != null) {
          final deps = await SupabaseService.instance
              .getDepartamentosPorEmpresa(empresaId);
          if (mounted) setState(() => _departamentos = deps);
        }
      } catch (_) {
        // ignore
      }
      _departamentoId = empleadoRaw?['departamento_id']?.toString();

      // Attempt to geocode the user's own address (if present) so we can show a personal map
      final userAddress = _direccionController.text.trim();
      if (userAddress.isNotEmpty) {
        try {
          final userCoords = await SupabaseService.instance.geocodeAddress(
            userAddress,
          );
          if (mounted && userCoords != null) {
            setState(() {
              _userLat = userCoords['lat'];
              _userLng = userCoords['lng'];
            });
          }
        } catch (_) {
          // ignore geocoding failures for user address
        }
      }
    } catch (e) {
      setState(() => _error = 'Error cargando perfil: $e');
    }
  }

  String? _empresaId;
  String? _empresaDireccion;

  // Removed unused _fetchExactCoordinates() — coordinate fetching
  // is handled elsewhere (admin flow). Kept save logic in place.

  Future<void> _saveCompanyCoordinates() async {
    if (_empresaId == null || _companyLat == null || _companyLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay coordenadas para guardar')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await SupabaseService.instance.updateEmpresaCoordinates(
        _empresaId!,
        _companyLat!,
        _companyLng!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Coordenadas guardadas')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error guardando coordenadas: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (picked == null) return;
      setState(() => _selectedImageFile = File(picked.path));
    } catch (e) {
      setState(() => _error = 'Error seleccionando imagen: $e');
    }
  }

  Future<void> _save() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      String? uploadedUrl;
      if (_selectedImageFile != null) {
        uploadedUrl = await SupabaseService.instance.uploadProfilePhoto(
          filePath: _selectedImageFile!.path,
        );
        // Actualizar profiles foto_url
        await SupabaseService.instance.updateMyProfile(fotoUrl: uploadedUrl);
      }

      // Actualizar nombres/apellidos en profiles
      await SupabaseService.instance.updateMyProfile(
        nombres: _nombresController.text.trim().isEmpty
            ? null
            : _nombresController.text.trim(),
        apellidos: _apellidosController.text.trim().isEmpty
            ? null
            : _apellidosController.text.trim(),
      );

      // Actualizar campos en empleados
      await SupabaseService.instance.updateEmpleadoProfile(
        cedula: _cedulaController.text.trim().isEmpty
            ? null
            : _cedulaController.text.trim(),
        telefono: _telefonoController.text.trim().isEmpty
            ? null
            : _telefonoController.text.trim(),
        direccion: _direccionController.text.trim().isEmpty
            ? null
            : _direccionController.text.trim(),
        departamentoId: _departamentoId?.trim().isEmpty == true
            ? null
            : _departamentoId,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: AppColors.primary,
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ProfileView(
              nombresController: _nombresController,
              apellidosController: _apellidosController,
              cedulaController: _cedulaController,
              telefonoController: _telefonoController,
              direccionController: _direccionController,
              departamentos: _departamentos,
              departamentoId: _departamentoId,
              onDepartamentoChanged: (v) => setState(() => _departamentoId = v),
              email: _email,
              fotoUrl: _fotoUrl,
              selectedImageFile: _selectedImageFile,
              onPickImage: _pickImage,
              onSave: _save,
              isLoading: _isLoading,
              errorMessage: _error,
              companyLat: _companyLat,
              companyLng: _companyLng,
              companyRadiusMeters: _companyRadius,
              companyName: _companyName,
              companyAddress: _empresaDireccion,
              userLat: _userLat,
              userLng: _userLng,
              userAddress: _direccionController.text,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  if (_empresaId != null && _userRole == 'ADMIN_EMPRESA')
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: (_isLoading || _companyLat == null)
                            ? null
                            : _saveCompanyCoordinates,
                        icon: const Icon(Icons.save),
                        label: const Text('Guardar coordenadas'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
