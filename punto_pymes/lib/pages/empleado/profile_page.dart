import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../service/supabase_service.dart';

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
    final radius = 48.0;
    if (_selectedImageFile != null) {
      return CircleAvatar(radius: radius, backgroundImage: FileImage(_selectedImageFile!));
    }
    if (_fotoUrl != null && _fotoUrl!.isNotEmpty) {
      return CircleAvatar(radius: radius, backgroundImage: NetworkImage(_fotoUrl!));
    }
    return CircleAvatar(radius: radius, child: const Icon(Icons.person, size: 48));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: GestureDetector(onTap: _pickImage, child: _buildAvatar())),
            const SizedBox(height: 12),
            TextButton.icon(onPressed: _pickImage, icon: const Icon(Icons.camera_alt), label: const Text('Cambiar foto')),
            const SizedBox(height: 12),

            TextField(controller: _nombresController, decoration: const InputDecoration(labelText: 'Nombres')),
            const SizedBox(height: 8),
            TextField(controller: _apellidosController, decoration: const InputDecoration(labelText: 'Apellidos')),
            const SizedBox(height: 8),
            TextField(controller: TextEditingController(text: _email ?? ''), enabled: false, decoration: const InputDecoration(labelText: 'Correo electrónico')),
            const SizedBox(height: 8),
            TextField(controller: _cedulaController, decoration: const InputDecoration(labelText: 'Cédula / Documento')),
            const SizedBox(height: 8),
            TextField(controller: _telefonoController, decoration: const InputDecoration(labelText: 'Teléfono')),
            const SizedBox(height: 8),
            TextField(controller: _direccionController, decoration: const InputDecoration(labelText: 'Dirección')),
            const SizedBox(height: 16),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) : const Text('Guardar cambios'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
