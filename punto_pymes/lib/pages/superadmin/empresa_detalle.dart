import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../service/supabase_service.dart';
import 'package:pymes2/theme.dart'; // Importamos el tema para los colores
import 'creacion_departamentos.dart';
import 'departamento_detalle.dart';

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

  // Controladores
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

  // --- LOGICA DE DATOS (Mantenida igual para no romper funcionalidad) ---
  Future<void> _fetch() async {
    try {
      final data = await SupabaseService.instance.getEmpresaById(widget.empresaId);
      if (data != null) {
        _setEmpresa(data);
      }
    } catch (e) {
      if (mounted) _showSnack('Error al cargar empresa: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchDepartamentos() async {
    if (!mounted) return;
    setState(() => _loadingDepartamentos = true);
    try {
      final data = await SupabaseService.instance.getDepartamentosPorEmpresa(widget.empresaId);
      if (mounted) setState(() => _departamentos = data);
    } catch (e) {
       // Silent error or debugPrint
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
    _currentLogoUrl = e['empresa_foto_url'] as String?;
    if (mounted) setState(() {});
  }

  Future<void> _pickLogo() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 80);
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

      if (mounted) _showSnack('Cambios guardados correctamente');
      await _fetch();
      setState(() => _newLogoLocalPath = null);
    } catch (e) {
      if (moved && finalPath != null) {
        try { await SupabaseService.instance.deleteFile(bucketName: 'fotos', filePath: finalPath); } catch (_) {}
      }
      if (mounted) _showSnack('Error al guardar: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg), 
        backgroundColor: isError ? AppTheme.errorColor : Colors.green
      ),
    );
  }

  // --- INTERFAZ DE USUARIO ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      
      // 1. APPBAR (Reemplaza al Header antiguo)
      appBar: AppBar(
        title: const Text('Detalle de Empresa', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Botón Guardar integrado en la barra
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _saving 
              ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
              : IconButton(
                  icon: const Icon(Icons.save_rounded, size: 28),
                  onPressed: _save,
                  tooltip: 'Guardar Cambios',
                ),
          )
        ],
      ),

      body: _loading 
          ? const Center(child: CircularProgressIndicator()) 
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  
                  // 2. SECCIÓN DEL LOGO (Avatar grande)
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))
                            ],
                            border: Border.all(color: Colors.grey.shade200, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: _newLogoLocalPath != null
                                ? Image.file(File(_newLogoLocalPath!), fit: BoxFit.cover)
                                : (_currentLogoUrl != null
                                    ? Image.network(_currentLogoUrl!, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.business, size: 50, color: Colors.grey))
                                    : const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)),
                          ),
                        ),
                        // Botón flotante para editar foto
                        Positioned(
                          bottom: -5,
                          right: -5,
                          child: GestureDetector(
                            onTap: _saving ? null : _pickLogo,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black26)]
                              ),
                              child: const Icon(Icons.edit, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. TARJETA DE CÓDIGO DE ACCESO (Destacado)
                  if (_empresa?['codigo_acceso_empleado'] != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE), // Fondo rojizo muy suave
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade100),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.vpn_key_rounded, color: AppTheme.primaryColor),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Código de Acceso Empleados',
                                style: TextStyle(fontSize: 12, color: Colors.red.shade800, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${_empresa!['codigo_acceso_empleado']}',
                                style: const TextStyle(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  // 4. FORMULARIO ORGANIZADO
                  _buildSectionTitle('Información General'),
                  _buildCustomTextField(controller: _nombre, label: 'Nombre Comercial', icon: Icons.store),
                  _buildCustomTextField(controller: _ruc, label: 'RUC', icon: Icons.badge_outlined),
                  _buildCustomTextField(controller: _direccion, label: 'Dirección', icon: Icons.location_on_outlined),

                  const SizedBox(height: 12),
                  _buildSectionTitle('Contacto'),
                  _buildCustomTextField(controller: _telefono, label: 'Teléfono', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
                  _buildCustomTextField(controller: _correo, label: 'Correo Electrónico', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),

                  const SizedBox(height: 12),
                  _buildSectionTitle('Ubicación GPS'),
                  Row(
                    children: [
                      Expanded(child: _buildCustomTextField(controller: _lat, label: 'Latitud', icon: Icons.map, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildCustomTextField(controller: _lng, label: 'Longitud', icon: Icons.map, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true))),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Divider(color: Colors.grey.shade300),
                  const SizedBox(height: 24),
                  
                  // 5. SECCIÓN DE DEPARTAMENTOS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('Departamentos', noPadding: true),
                      TextButton.icon(
                        onPressed: () async {
                          final result = await Navigator.of(context).push<bool>(MaterialPageRoute(
                            builder: (_) => CreacionDepartamentos(empresaId: widget.empresaId),
                          ));
                          if (result == true) _fetchDepartamentos();
                        },
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: const Text('Añadir'),
                        style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),

                  _loadingDepartamentos
                    ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                    : _departamentos.isEmpty
                      ? _buildEmptyDepartments()
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _departamentos.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final depto = _departamentos[index];
                            return _buildDepartmentTile(depto);
                          },
                        ),
                  
                  const SizedBox(height: 50),
                ],
              ),
            ),
    );
  }

  // --- WIDGETS DE DISEÑO ---

  Widget _buildSectionTitle(String title, {bool noPadding = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12, left: noPadding ? 0 : 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.secondaryColor,
        ),
      ),
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        enabled: !_saving,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: AppTheme.primaryColor.withOpacity(0.7), size: 22),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDepartmentTile(Map<String, dynamic> depto) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8)
          ),
          child: Icon(Icons.work_outline, color: Colors.blue[800], size: 20),
        ),
        title: Text(depto['nombre'] ?? 'Sin nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: depto['descripcion'] != null 
          ? Text(depto['descripcion'], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey[600])) 
          : null,
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[400]),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => DepartamentoDetallePage(
              departamentoId: depto['id'],
              departamentoNombre: depto['nombre'] ?? 'Sin nombre',
            ),
          ));
        },
      ),
    );
  }

  Widget _buildEmptyDepartments() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(Icons.domain_disabled_outlined, size: 40, color: Colors.grey[300]),
          const SizedBox(height: 8),
          Text('No hay departamentos', style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}