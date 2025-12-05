import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../service/supabase_service.dart';
import 'creacion_departamentos.dart';
import 'departamento_detalle.dart';
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
  List<Map<String, dynamic>> _departamentos = [];
  bool _loading = true;
  bool _saving = false;
  bool _loadingDepartamentos = true;

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
    _fetchDepartamentos();
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

  Future<void> _fetchDepartamentos() async {
    if (!mounted) return;
    setState(() => _loadingDepartamentos = true);
    try {
      final data = await SupabaseService.instance.getDepartamentosPorEmpresa(widget.empresaId);
      if (mounted) {
        setState(() {
          _departamentos = data;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar departamentos: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingDepartamentos = false);
      }
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
      if (moved && finalPath != null) {
        try {
          await SupabaseService.instance.deleteFile(bucketName: 'fotos', filePath: finalPath);
        } catch (_) {}
      }
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
                                    ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(_newLogoLocalPath!), height: 150, width: double.infinity, fit: BoxFit.cover))
                                        : (_currentLogoUrl != null
                                        ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(_currentLogoUrl!, height: 150, width: double.infinity, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported)))
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
                          const SizedBox(height: 24),
                          Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const CircleAvatar(backgroundColor: Color(0xFFE0F2F1), child: Icon(Icons.business_center_outlined, color: Color(0xFF00796B))),
                                      const SizedBox(width: 12),
                                      const Expanded(child: Text('Departamentos', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          final result = await Navigator.of(context).push<bool>(MaterialPageRoute(
                                            builder: (_) => CreacionDepartamentos(empresaId: widget.empresaId),
                                          ));
                                          if (result == true) {
                                            _fetchDepartamentos();
                                          }
                                        },
                                        icon: const Icon(Icons.add, size: 18),
                                        label: const Text('Añadir'),
                                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD92344), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _loadingDepartamentos
                                      ? const Center(child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator()))
                                      : _departamentos.isEmpty
                                          ? Center(
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 24.0),
                                                child: Column(
                                                  children: [
                                                    Icon(Icons.hourglass_empty, color: Colors.grey.shade400, size: 32),
                                                    const SizedBox(height: 8),
                                                    const Text('No hay departamentos creados.', style: TextStyle(color: Colors.black54)),
                                                  ],
                                                ),
                                              ),
                                            )
                                          : ListView.builder(
                                              shrinkWrap: true,
                                              physics: const NeverScrollableScrollPhysics(),
                                              itemCount: _departamentos.length,
                                              itemBuilder: (context, index) {
                                                final depto = _departamentos[index];
                                                return ListTile(
                                                  title: Text(depto['nombre'] ?? 'Sin nombre'),
                                                  subtitle: depto['descripcion'] != null ? Text(depto['descripcion']) : null,
                                                  trailing: const Icon(Icons.chevron_right),
                                                  onTap: () {
                                                    Navigator.of(context).push(MaterialPageRoute(
                                                      builder: (_) => DepartamentoDetallePage(
                                                        departamentoId: depto['id'],
                                                        departamentoNombre: depto['nombre'] ?? 'Sin nombre',
                                                      ),
                                                    ));
                                                  },
                                                );
                                              },
                                            )
                                ],
                              ),
                            ),
                          ),
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
