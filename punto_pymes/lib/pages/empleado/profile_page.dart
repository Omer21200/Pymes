import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../service/supabase_service.dart';
import '../../theme.dart';

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

  String? _email;
  String? _fotoUrl;
  File? _selectedImageFile;
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
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await SupabaseService.instance.getEmpleadoActual();
      if (data == null) return;
      setState(() {
        _nombresController.text = data['nombres'] ?? '';
        _apellidosController.text = data['apellidos'] ?? '';
        final empleadoRaw = data['empleado_raw'] as Map<String, dynamic>?;
        _cedulaController.text = empleadoRaw?['cedula']?.toString() ?? '';
        _telefonoController.text = empleadoRaw?['telefono']?.toString() ?? '';
        _direccionController.text = empleadoRaw?['direccion']?.toString() ?? '';
        _email = data['correo']?.toString();
        final profileRaw = data['profile_raw'] as Map<String, dynamic>?;
        _fotoUrl = profileRaw?['foto_url'] as String?;
      });
    } catch (e) {
      setState(() => _error = 'Error cargando perfil: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final XFile? picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
      if (picked == null) return;
      setState(() => _selectedImageFile = File(picked.path));
    } catch (e) {
      setState(() => _error = 'Error seleccionando imagen: $e');
    }
  }

  Future<void> _save() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      String? uploadedUrl;
      if (_selectedImageFile != null) {
        uploadedUrl = await SupabaseService.instance.uploadProfilePhoto(filePath: _selectedImageFile!.path);
        // Actualizar profiles foto_url
        await SupabaseService.instance.updateMyProfile(fotoUrl: uploadedUrl);
      }

      // Actualizar nombres/apellidos en profiles
      await SupabaseService.instance.updateMyProfile(
        nombres: _nombresController.text.trim().isEmpty ? null : _nombresController.text.trim(),
        apellidos: _apellidosController.text.trim().isEmpty ? null : _apellidosController.text.trim(),
      );

      // Actualizar campos en empleados
      await SupabaseService.instance.updateEmpleadoProfile(
        cedula: _cedulaController.text.trim().isEmpty ? null : _cedulaController.text.trim(),
        telefono: _telefonoController.text.trim().isEmpty ? null : _telefonoController.text.trim(),
        direccion: _direccionController.text.trim().isEmpty ? null : _direccionController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildAvatar() {
    final radius = AppSizes.avatar;
    // Avatar con badge de cámara en la esquina inferior derecha
    Widget avatarImage;
    if (_selectedImageFile != null) {
      avatarImage = CircleAvatar(radius: radius, backgroundImage: FileImage(_selectedImageFile!));
    } else if (_fotoUrl != null && _fotoUrl!.isNotEmpty) {
      avatarImage = CircleAvatar(radius: radius, backgroundImage: NetworkImage(_fotoUrl!));
    } else {
      avatarImage = CircleAvatar(radius: radius, child: const Icon(Icons.person, size: 48));
    }

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: AppDecorations.avatarContainer,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(child: avatarImage),
          Positioned(
            right: -6,
            bottom: -6,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil'), backgroundColor: AppColors.primary),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: _buildAvatar()),
            const SizedBox(height: 16),

            // Form card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Nombres
                    TextField(
                      controller: _nombresController,
                      textCapitalization: TextCapitalization.words,
                      keyboardType: TextInputType.name,
                      decoration: InputDecoration(
                        labelText: 'Nombres',
                        labelStyle: AppTextStyles.smallLabel,
                        prefixIcon: const Icon(Icons.person),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.divider)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.divider)),
                      ),
                      style: AppTextStyles.smallLabel,
                    ),
                    const SizedBox(height: 16),

                    // Apellidos
                    TextField(
                      controller: _apellidosController,
                      textCapitalization: TextCapitalization.words,
                      keyboardType: TextInputType.name,
                      decoration: InputDecoration(
                        labelText: 'Apellidos',
                        labelStyle: AppTextStyles.smallLabel,
                        prefixIcon: const Icon(Icons.person),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.divider)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.divider)),
                      ),
                      style: AppTextStyles.smallLabel,
                    ),
                    const SizedBox(height: 16),

                    // Correo (solo lectura)
                    TextFormField(
                      initialValue: _email ?? '',
                      enabled: false,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Correo electrónico',
                        labelStyle: AppTextStyles.smallLabel,
                        prefixIcon: const Icon(Icons.email),
                        filled: true,
                        fillColor: AppColors.lightGray,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.divider)),
                      ),
                      style: AppTextStyles.smallLabel,
                    ),
                    const SizedBox(height: 16),

                    // Cédula (marcada como no editable para claridad)
                    TextField(
                      controller: _cedulaController,
                      readOnly: true,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Cédula / Documento',
                        labelStyle: AppTextStyles.smallLabel,
                        prefixIcon: const Icon(Icons.credit_card),
                        filled: true,
                        fillColor: AppColors.lightGray,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.divider)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.divider)),
                      ),
                      style: AppTextStyles.smallLabel,
                    ),
                    const SizedBox(height: 16),

                    // Teléfono
                    TextField(
                      controller: _telefonoController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Teléfono',
                        labelStyle: AppTextStyles.smallLabel,
                        prefixIcon: const Icon(Icons.phone),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.divider)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.divider)),
                      ),
                      style: AppTextStyles.smallLabel,
                    ),
                    const SizedBox(height: 16),

                    // Dirección
                    TextField(
                      controller: _direccionController,
                      keyboardType: TextInputType.streetAddress,
                      decoration: InputDecoration(
                        labelText: 'Dirección',
                        labelStyle: AppTextStyles.smallLabel,
                        prefixIcon: const Icon(Icons.location_on),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.divider)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.divider)),
                      ),
                      style: AppTextStyles.smallLabel,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 16),
            if (_error != null) Text(_error!, style: AppTextStyles.smallLabel.copyWith(color: AppColors.dangerRed)),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: _isLoading
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                    : const Text('Guardar cambios', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
