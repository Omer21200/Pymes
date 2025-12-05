import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../service/supabase_service.dart';
import '../widgets/admin_empresa_header.dart';

class CreacionNoticiaPage extends StatefulWidget {
  final Map<String, dynamic>? noticia;

  const CreacionNoticiaPage({super.key, this.noticia});

  @override
  State<CreacionNoticiaPage> createState() => _CreacionNoticiaPageState();
}

class _CreacionNoticiaPageState extends State<CreacionNoticiaPage> {
  final _tituloController = TextEditingController();
  final _contenidoController = TextEditingController();
  
  bool _isSaving = false;
  File? _imagenSeleccionada;
  String? _imagenUrlExistente;
  bool _esImportante = false;
  String _tipoAudiencia = 'global';
  
  List<Map<String, dynamic>> _departamentosDisponibles = [];
  final Set<String> _departamentosSeleccionados = {};
  bool _loadingDeptos = true;
  String? _nombreAdmin;
  String? _nombreEmpresa;

  bool get isEditing => widget.noticia != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final noticia = widget.noticia!;
      _tituloController.text = noticia['titulo'] ?? '';
      _contenidoController.text = noticia['contenido'] ?? '';
      _esImportante = noticia['es_importante'] ?? false;
      _tipoAudiencia = noticia['tipo_audiencia'] ?? 'global';
      _imagenUrlExistente = noticia['imagen_url'];
    }

    _fetchDepartamentos();
    _loadHeaderData();
  }

  Future<void> _loadHeaderData() async {
    try {
      final datosEmpleado = await SupabaseService.instance.getEmpleadoActual();
      debugPrint('CreacionNoticiaPage: datosEmpleado -> $datosEmpleado');
      if (datosEmpleado != null) {
        final nombre = datosEmpleado['nombre_completo']?.toString();
        final empresaId = datosEmpleado['empresa_id']?.toString();
        String? empresaNombre;
        if (empresaId != null) {
          final empresa = await SupabaseService.instance.getEmpresaById(empresaId);
          debugPrint('CreacionNoticiaPage: empresa lookup -> $empresa');
          empresaNombre = empresa?['nombre']?.toString();
        }
        if (mounted) {
          setState(() {
            _nombreAdmin = nombre;
            _nombreEmpresa = empresaNombre;
          });
        }
      }
        debugPrint('CreacionNoticiaPage: getEmpleadoActual returned null');
        
    } catch (e) {
      debugPrint('Error cargando header admin: $e');
    }
  }

  Future<void> _fetchDepartamentos() async {
    try {
      final datosEmpleado = await SupabaseService.instance.getEmpleadoActual();

      if (datosEmpleado != null && datosEmpleado['empresa_id'] != null) {
        final empresaId = datosEmpleado['empresa_id'].toString();
        final deptos = await SupabaseService.instance.getDepartamentosPorEmpresa(empresaId);

        if (mounted) {
          setState(() {
            _departamentosDisponibles = deptos;
            _loadingDeptos = false;
          });
        }
        // Si estamos editando una noticia y la audiencia es por departamento,
        // cargamos los departamentos asociados para marcarlos en la UI.
        if (isEditing && _tipoAudiencia == 'departamento') {
          try {
            final noticiaId = widget.noticia!['id']?.toString();
            if (noticiaId != null) {
              final asignados = await SupabaseService.instance.getDepartamentosPorNoticia(noticiaId);
              final assignedIds = asignados.map((d) => d['id']?.toString()).whereType<String>().toSet();
              if (mounted) {
                setState(() {
                  _departamentosSeleccionados.clear();
                  _departamentosSeleccionados.addAll(assignedIds);
                });
              }
            }
          } catch (e) {
            debugPrint('Error cargando departamentos de la noticia: $e');
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo identificar la empresa del usuario.')),
          );
          setState(() => _loadingDeptos = false);
        }
      }
    } catch (e) {
      debugPrint('Error cargando departamentos: $e');
      if (mounted) setState(() => _loadingDeptos = false);
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _contenidoController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _imagenSeleccionada = File(pickedFile.path);
        _imagenUrlExistente = null;
      });
    }
  }

  Future<void> _guardarNoticia() async {
    if (_tituloController.text.isEmpty || _contenidoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El título y el contenido son obligatorios.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await SupabaseService.instance.upsertNoticia(
        noticiaId: widget.noticia?['id'],
        titulo: _tituloController.text,
        contenido: _contenidoController.text,
        esImportante: _esImportante,
        tipoAudiencia: _tipoAudiencia,
        departamentos: _departamentosSeleccionados,
        imagenPath: _imagenSeleccionada?.path,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Noticia ${isEditing ? 'actualizada' : 'creada'} con éxito'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      body: SafeArea(
        child: Column(
          children: [
            AdminEmpresaHeader(
              nombreAdmin: _nombreAdmin,
              nombreEmpresa: _nombreEmpresa,
              onLogout: null,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Título con botón cerrar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'Editar Noticia' : 'Crear Noticia',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.black54),
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Contenido Card
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFECEF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.newspaper, color: Color(0xFFD92344)),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Contenido',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _tituloController,
                              enabled: !_isSaving,
                              decoration: InputDecoration(
                                labelText: 'Título',
                                hintText: 'Ej: Día del Escudo',
                                prefixIcon: const Icon(Icons.title),
                                filled: true,
                                fillColor: const Color(0xFFF3F3F3),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _contenidoController,
                              enabled: !_isSaving,
                              maxLines: 6,
                              decoration: InputDecoration(
                                labelText: 'Contenido',
                                hintText: 'Escribe el contenido de la noticia...',
                                prefixIcon: const Icon(Icons.description),
                                filled: true,
                                fillColor: const Color(0xFFF3F3F3),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (_imagenUrlExistente != null && _imagenSeleccionada == null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    _imagenUrlExistente!,
                                    height: 150,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            if (_imagenSeleccionada != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _imagenSeleccionada!,
                                    height: 150,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.image),
                              label: Text(
                                _imagenUrlExistente != null || _imagenSeleccionada != null
                                    ? 'Cambiar Imagen'
                                    : 'Seleccionar Imagen',
                              ),
                              onPressed: _isSaving ? null : _seleccionarImagen,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SwitchListTile(
                              title: const Text('Noticia Importante'),
                              subtitle: const Text('Se fijará en la pantalla de inicio'),
                              value: _esImportante,
                              onChanged: _isSaving ? null : (val) => setState(() => _esImportante = val),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Audiencia Card
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE3F2FD),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.people, color: Color(0xFF1976D2)),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Audiencia',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: _isSaving ? null : () => setState(() => _tipoAudiencia = 'global'),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _tipoAudiencia == 'global' ? const Color(0xFF1976D2) : Colors.grey.shade300,
                                    width: _tipoAudiencia == 'global' ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: _tipoAudiencia == 'global'
                                      ? const Color(0xFF1976D2).withValues(alpha: 0.05)
                                      : Colors.transparent,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _tipoAudiencia == 'global' ? const Color(0xFF1976D2) : Colors.grey,
                                        ),
                                      ),
                                      child: _tipoAudiencia == 'global'
                                          ? Center(
                                              child: Container(
                                                width: 12,
                                                height: 12,
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Color(0xFF1976D2),
                                                ),
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Global',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            'Visible para toda la empresa',
                                            style: TextStyle(fontSize: 12, color: Colors.black54),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _isSaving ? null : () => setState(() => _tipoAudiencia = 'departamento'),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _tipoAudiencia == 'departamento' ? const Color(0xFF1976D2) : Colors.grey.shade300,
                                    width: _tipoAudiencia == 'departamento' ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: _tipoAudiencia == 'departamento'
                                      ? const Color(0xFF1976D2).withValues(alpha: 0.05)
                                      : Colors.transparent,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _tipoAudiencia == 'departamento' ? const Color(0xFF1976D2) : Colors.grey,
                                        ),
                                      ),
                                      child: _tipoAudiencia == 'departamento'
                                          ? Center(
                                              child: Container(
                                                width: 12,
                                                height: 12,
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Color(0xFF1976D2),
                                                ),
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Por Departamento',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            'Visible solo para departamentos seleccionados',
                                            style: TextStyle(fontSize: 12, color: Colors.black54),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_tipoAudiencia == 'departamento')
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: _loadingDeptos
                                    ? const Center(child: CircularProgressIndicator())
                                    : Column(
                                        children: _departamentosDisponibles.map((depto) {
                                          final deptoId = depto['id']?.toString() ?? '';
                                          final nombre = depto['nombre']?.toString() ?? '';
                                          return CheckboxListTile(
                                            title: Text(nombre),
                                            value: _departamentosSeleccionados.contains(deptoId),
                                            onChanged: _isSaving
                                                ? null
                                                : (val) {
                                                    setState(() {
                                                      if (val == true) {
                                                        _departamentosSeleccionados.add(deptoId);
                                                      } else {
                                                        _departamentosSeleccionados.remove(deptoId);
                                                      }
                                                    });
                                                  },
                                            contentPadding: EdgeInsets.zero,
                                          );
                                        }).toList(),
                                      ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botón guardar
                    SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: (_tituloController.text.isNotEmpty &&
                                _contenidoController.text.isNotEmpty &&
                                !_isSaving)
                            ? _guardarNoticia
                            : null,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(_isSaving
                            ? 'Guardando...'
                            : isEditing
                                ? 'Guardar Noticia'
                                : 'Publicar Noticia'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD92344),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
