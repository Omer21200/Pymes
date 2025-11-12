import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

import '../widgets/profile_card.dart';
import 'empresa_details_page.dart';
import '../main.dart';

class EmpresasPage extends StatefulWidget {
  final String userName;
  // Callback optional que se dispara cuando una empresa cambia (creada/actualizada/eliminada)
  final VoidCallback? onCompanyChanged;

  const EmpresasPage({this.userName = 'Super Admin', this.onCompanyChanged, super.key});

  @override
  State<EmpresasPage> createState() => _EmpresasPageState();
}

class _EmpresasPageState extends State<EmpresasPage> {
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _rucCtrl = TextEditingController();
  final TextEditingController _direccionCtrl = TextEditingController();
  final TextEditingController _telefonoCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();

  final TextEditingController _horaEntradaCtrl = TextEditingController();
  final TextEditingController _horaSalidaCtrl = TextEditingController();
  final TextEditingController _horaAlmuerzoCtrl = TextEditingController();
  final TextEditingController _horaEntradaAlmuerzoCtrl = TextEditingController();
  final TextEditingController _toleranciaCtrl = TextEditingController(text: '15');

  XFile? _logoFile;
  String? _logoUrl;
  bool _isUploadingLogo = false;
  bool _isCreating = false;

  List<Map<String, dynamic>> _companies = [];

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    try {
      final res = await supabase.from('empresas').select().order('nombre');
      final List resList = res as List;
      setState(() {
        _companies = resList.map<Map<String, dynamic>>((e) => {
              'id': e['id'],
              'name': e['nombre'] ?? e['name'] ?? '',
              'ruc': e['ruc'] ?? '',
              'direccion': e['direccion'] ?? '',
              'telefono': e['telefono'] ?? '',
              'email': e['email'] ?? '',
              'codigo_empresa': e['codigo_empresa']?.toString() ?? '',
              'logo_url': e['logo_url']?.toString() ?? '',
              'hora_entrada': e['hora_entrada'] ?? '',
              'hora_salida': e['hora_salida'] ?? '',
              'hora_almuerzo': e['hora_almuerzo'] ?? '',
              'hota_entrada_almuerzo': e['hota_entrada_almuerzo'] ?? e['hora_entrada_almuerzo'] ?? '',
              'tolerancia_minutos': e['tolerancia_minutos'] ?? 0,
            }).toList();
      });
    } catch (e) {
      debugPrint('Error cargando empresas (EmpresasPage): $e');
    }
  }

  Future<void> _createEmpresa() async {
    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nombre es obligatorio'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isCreating = true);
    try {
      // Si hay logo seleccionado, subirlo primero y obtener URL pública
      if (_logoFile != null) {
        try {
          setState(() => _isUploadingLogo = true);
          final fileName = 'logos/${DateTime.now().millisecondsSinceEpoch}_${_logoFile!.name}';

          // Subida distinta para web y mobile
          if (kIsWeb) {
            // Nota: la API de Storage desde web puede requerir un método distinto
            // (uploadBinary) que no está garantizado en todas las versiones del SDK.
            // Para evitar fallos por tipo aquí, mostramos un mensaje y saltamos la
            // subida en entornos web; en mobile el flujo normal continuará.
            debugPrint('Subida de logo no soportada desde web en esta versión del cliente.');
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subida de logo no soportada desde web')));
          } else {
            // Mobile / desktop: subir desde path
            try {
              await supabase.storage.from('logos').upload(fileName, File(_logoFile!.path));
            } catch (e) {
              debugPrint('Error subiendo logo (mobile): $e');
              throw Exception('Error subiendo logo (mobile): $e');
            }
          }

          // obtener public url (manejar distintos formatos de retorno)
          final dynamic pub = supabase.storage.from('logos').getPublicUrl(fileName);
          String url = '';
          if (pub == null) {
            url = '';
          } else if (pub is String) {
            url = pub;
          } else if (pub is Map) {
            url = (pub['publicUrl'] ?? pub['publicURL'] ?? pub['url'] ?? '').toString();
          } else {
            url = pub.toString();
          }

          if (url.isEmpty) {
            debugPrint('getPublicUrl returned empty for $fileName -> $pub');
          }

          if (url.isNotEmpty) {
            _logoUrl = url;
            debugPrint('Logo uploaded and public url: $_logoUrl');
          } else {
            debugPrint('No se obtuvo URL pública para el logo de $fileName');
          }
        } catch (e) {
          debugPrint('Error subiendo logo: $e');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo subir el logo: ${e.toString()}'), backgroundColor: Colors.orange));
          // continuar sin logo
        } finally {
          if (mounted) setState(() => _isUploadingLogo = false);
        }
      }

      final payload = {
        'nombre': nombre,
        'ruc': _rucCtrl.text.trim().isNotEmpty ? _rucCtrl.text.trim() : null,
        'direccion': _direccionCtrl.text.trim().isNotEmpty ? _direccionCtrl.text.trim() : null,
        'telefono': _telefonoCtrl.text.trim().isNotEmpty ? _telefonoCtrl.text.trim() : null,
        'email': _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : null,
        'hora_entrada': _horaEntradaCtrl.text.trim().isNotEmpty ? _horaEntradaCtrl.text.trim() : null,
        'hora_salida': _horaSalidaCtrl.text.trim().isNotEmpty ? _horaSalidaCtrl.text.trim() : null,
        'hora_almuerzo': _horaAlmuerzoCtrl.text.trim().isNotEmpty ? _horaAlmuerzoCtrl.text.trim() : null,
        'hota_entrada_almuerzo': _horaEntradaAlmuerzoCtrl.text.trim().isNotEmpty ? _horaEntradaAlmuerzoCtrl.text.trim() : null,
        'logo_url': _logoUrl,
        'tolerancia_minutos': int.tryParse(_toleranciaCtrl.text) ?? 0,
      };

      final inserted = await supabase.from('empresas').insert([payload]).select().maybeSingle();
      if (inserted != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Empresa creada')));
        // limpiar form
        _nombreCtrl.clear();
        _rucCtrl.clear();
        _direccionCtrl.clear();
        _telefonoCtrl.clear();
        _emailCtrl.clear();
        _horaEntradaCtrl.clear();
        _horaSalidaCtrl.clear();
        _horaAlmuerzoCtrl.clear();
        _horaEntradaAlmuerzoCtrl.clear();
        _toleranciaCtrl.text = '15';
        _logoFile = null;
        _logoUrl = null;
        // recargar lista local y notificar al padre para que también actualice su estado
        await _loadCompanies();
        try {
          widget.onCompanyChanged?.call();
        } catch (e) {
          debugPrint('Error notifying parent about company creation: $e');
        }
      }
    } catch (e) {
      debugPrint('Error creando empresa (EmpresasPage): $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creando empresa: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _deleteCompany(String id) async {
    if (id.isEmpty) return;
    final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Confirmar'), content: const Text('¿Eliminar esta empresa?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar'))]));
    if (confirm != true) return;

    try {
      await supabase.from('empresas').delete().eq('id', id);
      await _loadCompanies();
      try {
        widget.onCompanyChanged?.call();
      } catch (e) {
        debugPrint('Error notifying parent after delete: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Empresa eliminada')));
    } catch (e) {
      debugPrint('Error eliminando empresa: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error eliminando empresa: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _editCompany(Map<String, dynamic> company) async {
    final TextEditingController nombreCtrl = TextEditingController(text: company['name']?.toString() ?? '');
    final TextEditingController rucCtrl = TextEditingController(text: company['ruc']?.toString() ?? '');
    final TextEditingController direccionCtrl = TextEditingController(text: company['direccion']?.toString() ?? '');
    final TextEditingController telefonoCtrl = TextEditingController(text: company['telefono']?.toString() ?? '');
    final TextEditingController emailCtrl = TextEditingController(text: company['email']?.toString() ?? '');
    final TextEditingController horaEntradaCtrl = TextEditingController(text: company['hora_entrada']?.toString() ?? '');
    final TextEditingController horaSalidaCtrl = TextEditingController(text: company['hora_salida']?.toString() ?? '');
    final TextEditingController horaAlmuerzoCtrl = TextEditingController(text: company['hora_almuerzo']?.toString() ?? '');
    final TextEditingController horaEntradaAlmuerzoCtrl = TextEditingController(text: company['hota_entrada_almuerzo']?.toString() ?? company['hora_entrada_almuerzo']?.toString() ?? '');
    final TextEditingController toleranciaCtrl = TextEditingController(text: (company['tolerancia_minutos'] ?? 0).toString());

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Editar Empresa', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextField(controller: nombreCtrl, decoration: InputDecoration(hintText: 'Nombre', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
                const SizedBox(height: 8),
                TextField(controller: rucCtrl, decoration: InputDecoration(hintText: 'RUC', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
                const SizedBox(height: 8),
                TextField(controller: telefonoCtrl, decoration: InputDecoration(hintText: 'Teléfono', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
                const SizedBox(height: 8),
                TextField(controller: emailCtrl, decoration: InputDecoration(hintText: 'Email', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: TextField(controller: horaEntradaCtrl, readOnly: true, decoration: InputDecoration(hintText: 'Hora Entrada', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))), onTap: () async {
                    final initial = TimeOfDay.now();
                    final picked = await showTimePicker(context: context, initialTime: initial);
                    if (picked != null) horaEntradaCtrl.text = picked.hour.toString().padLeft(2, '0') + ':' + picked.minute.toString().padLeft(2, '0');
                  })),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: horaSalidaCtrl, readOnly: true, decoration: InputDecoration(hintText: 'Hora Salida', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))), onTap: () async {
                    final initial = TimeOfDay.now();
                    final picked = await showTimePicker(context: context, initialTime: initial);
                    if (picked != null) horaSalidaCtrl.text = picked.hour.toString().padLeft(2, '0') + ':' + picked.minute.toString().padLeft(2, '0');
                  })),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: TextField(controller: horaAlmuerzoCtrl, readOnly: true, decoration: InputDecoration(hintText: 'Hora Almuerzo', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))), onTap: () async {
                    final initial = TimeOfDay.now();
                    final picked = await showTimePicker(context: context, initialTime: initial);
                    if (picked != null) horaAlmuerzoCtrl.text = picked.hour.toString().padLeft(2, '0') + ':' + picked.minute.toString().padLeft(2, '0');
                  })),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: horaEntradaAlmuerzoCtrl, readOnly: true, decoration: InputDecoration(hintText: 'Entrada Almuerzo', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))), onTap: () async {
                    final initial = TimeOfDay.now();
                    final picked = await showTimePicker(context: context, initialTime: initial);
                    if (picked != null) horaEntradaAlmuerzoCtrl.text = picked.hour.toString().padLeft(2, '0') + ':' + picked.minute.toString().padLeft(2, '0');
                  })),
                ]),
                const SizedBox(height: 8),
                TextField(controller: toleranciaCtrl, decoration: InputDecoration(hintText: 'Tolerancia (minutos)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD92344)), onPressed: () async {
                  final payload = {
                    'nombre': nombreCtrl.text.trim().isNotEmpty ? nombreCtrl.text.trim() : null,
                    'ruc': rucCtrl.text.trim().isNotEmpty ? rucCtrl.text.trim() : null,
                    'direccion': direccionCtrl.text.trim().isNotEmpty ? direccionCtrl.text.trim() : null,
                    'telefono': telefonoCtrl.text.trim().isNotEmpty ? telefonoCtrl.text.trim() : null,
                    'email': emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : null,
                    'hora_entrada': horaEntradaCtrl.text.trim().isNotEmpty ? horaEntradaCtrl.text.trim() : null,
                    'hora_salida': horaSalidaCtrl.text.trim().isNotEmpty ? horaSalidaCtrl.text.trim() : null,
                    'hora_almuerzo': horaAlmuerzoCtrl.text.trim().isNotEmpty ? horaAlmuerzoCtrl.text.trim() : null,
                    'hota_entrada_almuerzo': horaEntradaAlmuerzoCtrl.text.trim().isNotEmpty ? horaEntradaAlmuerzoCtrl.text.trim() : null,
                    'tolerancia_minutos': int.tryParse(toleranciaCtrl.text) ?? 0,
                  };
                  try {
                    await supabase.from('empresas').update(payload).eq('id', company['id']);
                    Navigator.pop(ctx);
                      await _loadCompanies();
                      try {
                        widget.onCompanyChanged?.call();
                      } catch (e) {
                        debugPrint('Error notifying parent after update: $e');
                      }
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Empresa actualizada')));
                  } catch (e) {
                    debugPrint('Error actualizando empresa: $e');
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error actualizando empresa: $e'), backgroundColor: Colors.red));
                  }
                }, child: const Text('Guardar'))),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _rucCtrl.dispose();
    _direccionCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _horaEntradaCtrl.dispose();
    _horaSalidaCtrl.dispose();
    _horaAlmuerzoCtrl.dispose();
    _horaEntradaAlmuerzoCtrl.dispose();
    _toleranciaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 120, left: 16, right: 16, top: 12),
      child: Column(
        children: [
          // Profile card with user info
          const SizedBox(height: 12),
          ProfileCard(userName: widget.userName, institutionName: 'NEXUS', role: 'Super Administrador'),
          const SizedBox(height: 12),

          // Form card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.apartment, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Nueva Empresa', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Logo picker (moved to appear first)
                  Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey.shade100),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _logoFile != null
                              ? kIsWeb
                                  ? FutureBuilder<Uint8List>(
                                      future: _logoFile!.readAsBytes(),
                                      builder: (context, snap) => snap.hasData ? Image.memory(snap.data!, fit: BoxFit.cover) : const SizedBox.shrink(),
                                    )
                                  : Image.file(File(_logoFile!.path), fit: BoxFit.cover)
                              : const Center(child: Icon(Icons.image, color: Colors.grey)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Seleccionar logo'),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD92344), foregroundColor: Colors.white),
                              onPressed: () async {
                                // Mostrar diálogo (solo opción Galería). ImagePicker will
                                // request any OS permissions as necessary.
                                final choice = await showModalBottomSheet<String>(context: context, builder: (ctx) {
                                  return SafeArea(
                                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                                      ListTile(
                                        leading: const Icon(Icons.photo_library),
                                        title: const Text('Seleccionar desde galería'),
                                        onTap: () => Navigator.pop(ctx, 'gallery'),
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.close),
                                        title: const Text('Cancelar'),
                                        onTap: () => Navigator.pop(ctx, null),
                                      )
                                    ]),
                                  );
                                });

                                if (choice == 'gallery') {
                                  try {
                                    final ImagePicker picker = ImagePicker();
                                    final XFile? picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 800);
                                    if (picked != null) setState(() => _logoFile = picked);
                                  } catch (e) {
                                    debugPrint('Error picking image: $e');
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo acceder a la galería')));
                                  }
                                }
                              },
                            ),
                            const SizedBox(height: 6),
                            if (_isUploadingLogo) const Text('Subiendo logo...', style: TextStyle(color: Colors.grey)),
                            if (_logoUrl != null) Text('Logo listo', style: TextStyle(color: Colors.green.shade700)),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nombreCtrl,
                    decoration: InputDecoration(hintText: 'Nombre de la Empresa', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _rucCtrl,
                    decoration: InputDecoration(hintText: 'RUC', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailCtrl,
                    decoration: InputDecoration(hintText: 'Email', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _telefonoCtrl,
                          decoration: InputDecoration(hintText: 'Teléfono', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _direccionCtrl,
                          decoration: InputDecoration(hintText: 'Dirección', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _horaEntradaCtrl,
                          readOnly: true,
                          onTap: () async {
                            // abrir selector de hora
                            TimeOfDay initial = TimeOfDay.now();
                            if (_horaEntradaCtrl.text.isNotEmpty) {
                              final parts = _horaEntradaCtrl.text.split(':');
                              if (parts.length == 2) {
                                final h = int.tryParse(parts[0]) ?? initial.hour;
                                final m = int.tryParse(parts[1]) ?? initial.minute;
                                initial = TimeOfDay(hour: h, minute: m);
                              }
                            }
                            final picked = await showTimePicker(context: context, initialTime: initial);
                            if (picked != null) {
                              final hh = picked.hour.toString().padLeft(2, '0');
                              final mm = picked.minute.toString().padLeft(2, '0');
                              _horaEntradaCtrl.text = '$hh:$mm';
                            }
                          },
                          decoration: InputDecoration(hintText: 'Hora de Entrada (HH:MM)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 110,
                        child: DropdownButtonFormField<String>(
                          value: _toleranciaCtrl.text,
                          items: ['0','5','10','15','20','30','45','60']
                              .map((m) => DropdownMenuItem<String>(value: m, child: Text('$m')))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _toleranciaCtrl.text = v);
                          },
                          decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Hora salida y horario de almuerzo
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _horaSalidaCtrl,
                          readOnly: true,
                          onTap: () async {
                            TimeOfDay initial = TimeOfDay.now();
                            if (_horaSalidaCtrl.text.isNotEmpty) {
                              final parts = _horaSalidaCtrl.text.split(':');
                              if (parts.length == 2) {
                                final h = int.tryParse(parts[0]) ?? initial.hour;
                                final m = int.tryParse(parts[1]) ?? initial.minute;
                                initial = TimeOfDay(hour: h, minute: m);
                              }
                            }
                            final picked = await showTimePicker(context: context, initialTime: initial);
                            if (picked != null) {
                              _horaSalidaCtrl.text = picked.hour.toString().padLeft(2, '0') + ':' + picked.minute.toString().padLeft(2, '0');
                            }
                          },
                          decoration: InputDecoration(hintText: 'Hora de Salida (HH:MM)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _horaAlmuerzoCtrl,
                          readOnly: true,
                          onTap: () async {
                            TimeOfDay initial = TimeOfDay.now();
                            if (_horaAlmuerzoCtrl.text.isNotEmpty) {
                              final parts = _horaAlmuerzoCtrl.text.split(':');
                              if (parts.length == 2) {
                                final h = int.tryParse(parts[0]) ?? initial.hour;
                                final m = int.tryParse(parts[1]) ?? initial.minute;
                                initial = TimeOfDay(hour: h, minute: m);
                              }
                            }
                            final picked = await showTimePicker(context: context, initialTime: initial);
                            if (picked != null) {
                              _horaAlmuerzoCtrl.text = picked.hour.toString().padLeft(2, '0') + ':' + picked.minute.toString().padLeft(2, '0');
                            }
                          },
                          decoration: InputDecoration(hintText: 'Hora Almuerzo (HH:MM)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Hora de entrada al almuerzo (inicio de almuerzo)
                  TextField(
                    controller: _horaEntradaAlmuerzoCtrl,
                    readOnly: true,
                    onTap: () async {
                      TimeOfDay initial = TimeOfDay.now();
                      if (_horaEntradaAlmuerzoCtrl.text.isNotEmpty) {
                        final parts = _horaEntradaAlmuerzoCtrl.text.split(':');
                        if (parts.length == 2) {
                          final h = int.tryParse(parts[0]) ?? initial.hour;
                          final m = int.tryParse(parts[1]) ?? initial.minute;
                          initial = TimeOfDay(hour: h, minute: m);
                        }
                      }
                      final picked = await showTimePicker(context: context, initialTime: initial);
                      if (picked != null) {
                        _horaEntradaAlmuerzoCtrl.text = picked.hour.toString().padLeft(2, '0') + ':' + picked.minute.toString().padLeft(2, '0');
                      }
                    },
                    decoration: InputDecoration(hintText: 'Entrada Almuerzo (HH:MM)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isCreating ? null : _createEmpresa,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD92344), foregroundColor: Colors.white),
                      child: _isCreating ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Crear Empresa'),
                    ),
                  )
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          // Heading for registered companies
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Empresas Registradas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                child: Text('${_companies.length} empresas', style: const TextStyle(color: Colors.red)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // List of companies
          Column(
            children: _companies.map((c) {
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Builder(builder: (context) {
                                final logo = c['logo_url']?.toString() ?? '';
                                if (logo.isNotEmpty) {
                                  return Image.network(logo, fit: BoxFit.cover);
                                }
                                return const Icon(Icons.apartment, color: Colors.red);
                              }),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                Text('RUC: ${c['ruc'] ?? ''}', style: const TextStyle(color: Colors.grey)),
                                const SizedBox(height: 8),
                                Builder(builder: (context) {
                                  final code = c['codigo_empresa']?.toString() ?? '';
                                  return Row(children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                                      child: Row(children: [
                                        Text(code.isNotEmpty ? code : '-', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                        const SizedBox(width: 8),
                                        if (code.isNotEmpty)
                                          GestureDetector(
                                            onTap: () async {
                                              await Clipboard.setData(ClipboardData(text: code));
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código copiado')));
                                            },
                                            child: const Icon(Icons.copy, size: 16, color: Colors.grey),
                                          ),
                                      ]),
                                    ),
                                    const SizedBox(width: 8),
                                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)), child: const Text('Código de Registro', style: TextStyle(fontSize: 12))),
                                  ]);
                                })
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            children: [
                              IconButton(onPressed: () => _editCompany(c), icon: const Icon(Icons.edit, color: Colors.red)),
                              IconButton(onPressed: () => _deleteCompany(c['id']?.toString() ?? ''), icon: const Icon(Icons.delete_forever, color: Colors.red)),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(child: Text(c['direccion'] ?? '', style: const TextStyle(color: Colors.grey))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(c['telefono'] ?? '', style: const TextStyle(color: Colors.grey)),
                          const SizedBox(width: 12),
                          const Icon(Icons.email, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(c['email'] ?? '', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Entrada: ${c['hora_entrada'] ?? '-'} (±${c['tolerancia_minutos'] ?? 0} min)', style: const TextStyle(color: Colors.grey)),
                          Text('Registrada: --', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EmpresaDetailsPage(company: c))), child: const Text('Ver Detalles')))
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
