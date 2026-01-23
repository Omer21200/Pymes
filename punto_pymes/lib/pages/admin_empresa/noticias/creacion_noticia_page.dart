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
          final empresa = await SupabaseService.instance.getEmpresaById(
            empresaId,
          );
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
        final deptos = await SupabaseService.instance
            .getDepartamentosPorEmpresa(empresaId);

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
              final asignados = await SupabaseService.instance
                  .getDepartamentosPorNoticia(noticiaId);
              final assignedIds = asignados
                  .map((d) => d['id']?.toString())
                  .whereType<String>()
                  .toSet();
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
            const SnackBar(
              content: Text('No se pudo identificar la empresa del usuario.'),
            ),
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
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
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
        const SnackBar(
          content: Text('El título y el contenido son obligatorios.'),
          backgroundColor: Colors.red,
        ),
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
          content: Text(
            'Noticia ${isEditing ? 'actualizada' : 'creada'} con éxito',
          ),
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
    // Paleta alineada con la edición de departamento
    const Color brandRed = Color(0xFFE2183D);
    const Color accentBlue = Color(0xFF3F51B5);
    const Color surfaceSoft = Color(0xFFF5F6FA);
    const Color successGreen = Color(0xFF4CAF50);
    final Color accent = accentBlue;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        top: false,
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
                    const SizedBox(height: 4),
                    const Text(
                      'Completa la información para enviar un anuncio a tus empleados.',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 16),

                    // Contenido Card
                    Card(
                      color: surfaceSoft,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 6,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    Icons.article_outlined,
                                    color: accent,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Contenido de la noticia',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Título, mensaje principal e imagen opcional.',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Título',
                              style: TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _tituloController,
                              enabled: !_isSaving,
                              textAlignVertical: TextAlignVertical.center,
                              decoration: InputDecoration(
                                hintText: 'Ej: Día del Escudo',
                                prefixIcon: const Icon(Icons.title),
                                prefixIconConstraints: const BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 40,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 12,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF5F5F7),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: accent.withValues(alpha: 0.15),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: accent.withValues(alpha: 0.15),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: accent.withValues(alpha: 0.55),
                                    width: 1.6,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Contenido',
                              style: TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _contenidoController,
                              enabled: !_isSaving,
                              maxLines: 6,
                              textAlignVertical: TextAlignVertical.top,
                              decoration: InputDecoration(
                                hintText:
                                    'Escribe el contenido de la noticia...',
                                prefixIcon: const Icon(Icons.description),
                                prefixIconConstraints: const BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 40,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 12,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF5F5F7),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: accent.withValues(alpha: 0.15),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: accent.withValues(alpha: 0.15),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: accent.withValues(alpha: 0.55),
                                    width: 1.6,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (_imagenUrlExistente != null &&
                                _imagenSeleccionada == null)
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
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.image),
                                label: Text(
                                  _imagenUrlExistente != null ||
                                          _imagenSeleccionada != null
                                      ? 'Cambiar Imagen'
                                      : 'Seleccionar Imagen',
                                ),
                                onPressed: _isSaving
                                    ? null
                                    : _seleccionarImagen,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(
                                    color: accent.withValues(alpha: 0.4),
                                  ),
                                  foregroundColor: accent,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SwitchListTile(
                              title: const Text('Noticia Importante'),
                              subtitle: const Text(
                                'Se fijará en la pantalla de inicio',
                              ),
                              value: _esImportante,
                              onChanged: _isSaving
                                  ? null
                                  : (val) =>
                                        setState(() => _esImportante = val),
                              contentPadding: EdgeInsets.zero,
                              activeThumbColor: accent,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Audiencia Card
                    Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 6,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: brandRed.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.people_alt_outlined,
                                    color: brandRed,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Audiencia objetivo',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Define quién verá esta noticia en la app.',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: _isSaving
                                  ? null
                                  : () => setState(
                                      () => _tipoAudiencia = 'global',
                                    ),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _tipoAudiencia == 'global'
                                        ? accent
                                        : Colors.grey.shade300,
                                    width: _tipoAudiencia == 'global' ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: _tipoAudiencia == 'global'
                                      ? accent.withValues(alpha: 0.05)
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
                                          color: _tipoAudiencia == 'global'
                                              ? accent
                                              : Colors.grey,
                                        ),
                                      ),
                                      child: _tipoAudiencia == 'global'
                                          ? Center(
                                              child: Container(
                                                width: 12,
                                                height: 12,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: accent,
                                                ),
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Global',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'Visible para toda la empresa',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54,
                                            ),
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
                              onTap: _isSaving
                                  ? null
                                  : () => setState(
                                      () => _tipoAudiencia = 'departamento',
                                    ),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _tipoAudiencia == 'departamento'
                                        ? accent
                                        : Colors.grey.shade300,
                                    width: _tipoAudiencia == 'departamento'
                                        ? 2
                                        : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: _tipoAudiencia == 'departamento'
                                      ? accent.withValues(alpha: 0.05)
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
                                          color:
                                              _tipoAudiencia == 'departamento'
                                              ? accent
                                              : Colors.grey,
                                        ),
                                      ),
                                      child: _tipoAudiencia == 'departamento'
                                          ? Center(
                                              child: Container(
                                                width: 12,
                                                height: 12,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: accent,
                                                ),
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Por Departamento',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'Visible solo para departamentos seleccionados',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54,
                                            ),
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
                                    ? const Center(
                                        child: CircularProgressIndicator(),
                                      )
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: _departamentosDisponibles.map((
                                          depto,
                                        ) {
                                          final deptoId =
                                              depto['id']?.toString() ?? '';
                                          final nombre =
                                              depto['nombre']?.toString() ?? '';
                                          final bool seleccionado =
                                              _departamentosSeleccionados
                                                  .contains(deptoId);

                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 4,
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    nombre,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                                InkWell(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  onTap: _isSaving
                                                      ? null
                                                      : () {
                                                          setState(() {
                                                            if (seleccionado) {
                                                              _departamentosSeleccionados
                                                                  .remove(
                                                                    deptoId,
                                                                  );
                                                            } else {
                                                              _departamentosSeleccionados
                                                                  .add(deptoId);
                                                            }
                                                          });
                                                        },
                                                  child: Container(
                                                    width: 22,
                                                    height: 22,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                      border: Border.all(
                                                        color: seleccionado
                                                            ? successGreen
                                                            : Colors.black54,
                                                        width: 1,
                                                      ),
                                                      color: seleccionado
                                                          ? successGreen
                                                          : Colors.transparent,
                                                    ),
                                                    child: seleccionado
                                                        ? const Icon(
                                                            Icons.check,
                                                            size: 16,
                                                            color: Colors.white,
                                                          )
                                                        : null,
                                                  ),
                                                ),
                                              ],
                                            ),
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
                        onPressed:
                            (_tituloController.text.isNotEmpty &&
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
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          _isSaving
                              ? 'Guardando...'
                              : isEditing
                              ? 'Guardar Noticia'
                              : 'Publicar Noticia',
                        ),
                        style: ElevatedButton.styleFrom(
                          // Botón principal usa el rojo de referencia
                          backgroundColor: brandRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
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
