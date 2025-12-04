import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../service/supabase_service.dart';
import 'widgets/superadmin_header.dart';

class EmpresaDetallePage extends StatefulWidget {
  final String empresaId;
  final Map<String, dynamic>? initialEmpresa;

  const EmpresaDetallePage({super.key, required this.empresaId, this.initialEmpresa});

  @override
  State<EmpresaDetallePage> createState() => _EmpresaDetallePageState();
}

class _EmpresaDetallePageState extends State<EmpresaDetallePage> {
  Map<String, dynamic>? _empresa;
  bool _loading = true;
  bool _saving = false;

  final _nombre = TextEditingController();
  final _ruc = TextEditingController();
  final _direccion = TextEditingController();
  final _telefono = TextEditingController();
  final _correo = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  String? _newLogoLocalPath;
  String? _currentLogoUrl;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmpresa != null) {
      _setEmpresa(widget.initialEmpresa!);
      _loading = false;
    }
    _fetch();
  }

  @override
  void dispose() {
    _nombre.dispose();
    _ruc.dispose();
    _direccion.dispose();
    _telefono.dispose();
    _correo.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final data = await SupabaseService.instance.getEmpresaById(widget.empresaId);
      if (data != null) {
        _setEmpresa(data);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar empresa: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
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
    _currentLogoUrl = e['empresa_foto_url'] as String?;
    setState(() {});
  }

  Future<void> _pickLogo() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
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
      // Subir nuevo logo si hay
      if (_newLogoLocalPath != null) {
        final ts = DateTime.now().millisecondsSinceEpoch;
        final safe = _nombre.text.trim().replaceAll(' ', '_');
        final fileName = 'empresa_${ts}_$safe.jpg';
        finalPath = 'empresas/$fileName';

        // Subir directamente a la ruta final
        logoUrl = await SupabaseService.instance.uploadFile(
          filePath: _newLogoLocalPath!,
          bucketName: 'fotos',
          destinationPath: finalPath,
        );
        moved = true;
      }

      // Preparar updates solo con cambios
      double? lat;
      double? lng;
      if (_lat.text.trim().isNotEmpty) lat = double.tryParse(_lat.text.trim());
      if (_lng.text.trim().isNotEmpty) lng = double.tryParse(_lng.text.trim());

      await SupabaseService.instance.updateEmpresa(
        empresaId: widget.empresaId,
        nombre: _nombre.text.trim().isEmpty ? null : _nombre.text.trim(),
        ruc: _ruc.text.trim().isEmpty ? null : _ruc.text.trim(),
        direccion: _direccion.text.trim().isEmpty ? null : _direccion.text.trim(),
        telefono: _telefono.text.trim().isEmpty ? null : _telefono.text.trim(),
        correo: _correo.text.trim().isEmpty ? null : _correo.text.trim(),
        empresaFotoUrl: logoUrl,
        latitud: lat,
        longitud: lng,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cambios guardados'), backgroundColor: Colors.green),
        );
      }
      await _fetch();
      setState(() => _newLogoLocalPath = null);
    } catch (e) {
      // Cleanup si falla el update
      try {
        if (moved && finalPath != null) {
          await SupabaseService.instance.deleteFile(bucketName: 'fotos', filePath: finalPath);
        }
      } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
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
                actions: [
                  TextButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Guardar', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.all(16),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Logo
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
                                        child: Image.file(File(_newLogoLocalPath!), height: 150, width: double.infinity, fit: BoxFit.cover),
                                      )
                                    : (_currentLogoUrl != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.network(_currentLogoUrl!, height: 150, width: double.infinity, fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported)))
                                        : const Icon(Icons.add_a_photo_outlined, size: 36)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          if (_empresa?['codigo_acceso_empleado'] != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: const Color(0xFFFFECEF), borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                children: [
                                  const Icon(Icons.key, color: Color(0xFFD92344)),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text('Código de acceso: ${_empresa!['codigo_acceso_empleado']}')),
                                ],
                              ),
                            ),

                          const SizedBox(height: 12),
                          _buildField('Nombre', _nombre),
                          _buildField('RUC', _ruc),
                          _buildField('Dirección', _direccion),
                          _buildField('Teléfono', _telefono),
                          _buildField('Email', _correo, keyboardType: TextInputType.emailAddress),
                          _buildField('Latitud', _lat, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true)),
                          _buildField('Longitud', _lng, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true)),
                        ],
                      ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        enabled: !_saving,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF3F3F3),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}
