import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../main.dart';

class CaptureAttendancePage extends StatefulWidget {
  final String? userId;
  final String? institutionName;
  const CaptureAttendancePage({this.userId, this.institutionName, super.key});

  @override
  State<CaptureAttendancePage> createState() => _CaptureAttendancePageState();
}

class _CaptureAttendancePageState extends State<CaptureAttendancePage> {
  XFile? _picked;
  bool _isPicking = false;

  Future<void> _capture() async {
    setState(() => _isPicking = true);
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 80, maxWidth: 1280);
      if (photo != null) {
        setState(() => _picked = photo);
        // after capture, request location and show confirmation
        await _afterCaptureFlow();
      }
    } catch (e) {
      debugPrint('Error capturing image: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al capturar foto'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<Position?> _getLocation() async {
    try {
      // Check if location services are enabled (GPS on)
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Ask the user to enable location services
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Ubicación desactivada'),
            content: const Text('Por favor active la ubicación del dispositivo para capturar coordenadas.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
              TextButton(onPressed: () async { Navigator.of(ctx).pop(true); await Geolocator.openLocationSettings(); }, child: const Text('Abrir ajustes')),
            ],
          ),
        );
        // After returning from settings, re-check
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        // Permission permanently denied, prompt to open app settings
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Permiso denegado permanentemente'),
            content: const Text('Debe habilitar el permiso de ubicación desde la configuración de la aplicación.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cerrar')),
              TextButton(onPressed: () async { Navigator.of(ctx).pop(); await Geolocator.openAppSettings(); }, child: const Text('Abrir ajustes')),
            ],
          ),
        );
        return null;
      }

      if (permission == LocationPermission.denied) {
        // user denied permission
        return null;
      }

      // Get the current position (includes altitude when available)
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      return pos;
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  Future<void> _afterCaptureFlow() async {
    // try to get location, with a few retries and options to open settings
    Position? pos;
    int attempts = 0;
    const int maxAttempts = 3;
    while (attempts < maxAttempts) {
      pos = await _getLocation();
      if (pos != null) break;

      // Ask user what to do: retry, open settings, or cancel
      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('No se obtuvo ubicación'),
          content: const Text('No se pudo obtener la ubicación. ¿Quieres reintentar o abrir los ajustes para habilitar la ubicación?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop('cancel'), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.of(ctx).pop('settings'), child: const Text('Abrir ajustes')),
            TextButton(onPressed: () => Navigator.of(ctx).pop('retry'), child: const Text('Reintentar')),
          ],
        ),
      );

      if (action == 'retry') {
        attempts++;
        continue;
      }
      if (action == 'settings') {
        // open app settings so user can enable permissions/services
        await Geolocator.openAppSettings();
        attempts++;
        continue;
      }

      // cancel or null -> stop flow and clear preview
      setState(() => _picked = null);
      return;
    }

    double? lat = pos?.latitude;
    double? lon = pos?.longitude;
    double? alt = pos?.altitude;

    // show confirmation dialog with preview and coords
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: StatefulBuilder(builder: (ctx2, setStateSB) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Confirmar Registro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                  child: ClipRRect(borderRadius: BorderRadius.circular(8), child: kIsWeb ? FutureBuilder<Uint8List>(future: _picked!.readAsBytes(), builder: (context, snap) => snap.hasData ? Image.memory(snap.data!, fit: BoxFit.cover) : const SizedBox.shrink()) : Image.file(File(_picked!.path), fit: BoxFit.cover)),
                ),
                const SizedBox(height: 12),
                Row(children: [const Icon(Icons.location_on, color: Colors.red), const SizedBox(width: 8), Expanded(child: Text('Lat: ${lat?.toStringAsFixed(6) ?? '-'}, Lng: ${lon?.toStringAsFixed(6) ?? '-'}'))]),
                if (alt != null) Padding(padding: const EdgeInsets.only(top: 6), child: Row(children: [const Icon(Icons.alt_route, color: Colors.grey), const SizedBox(width: 8), Text('Alt: ${alt.toStringAsFixed(2)} m')])),
                const SizedBox(height: 12),
                Row(children: [Expanded(child: OutlinedButton(onPressed: () { Navigator.pop(ctx); setState(() => _picked = null); }, child: const Text('Tomar otra'))), const SizedBox(width: 12), Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD92344)), onPressed: () async {
                  // confirmar: upload + insert registro
                  Navigator.pop(ctx);
                  await _saveRegistro(lat, lon, alt);
                }, child: const Text('Confirmar')))]),
                const SizedBox(height: 12),
              ]),
            );
          }),
        );
      },
    );
  }

  Future<void> _saveRegistro(double? lat, double? lon, double? alt) async {
    if (_picked == null) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guardando registro...')));
    String? photoUrl;
    try {
      final fileName = 'asistencias/${DateTime.now().millisecondsSinceEpoch}_${_picked!.name}';
      if (kIsWeb) {
        // web upload not supported reliably here; skip upload and set null
        debugPrint('Web upload skipped for attendance photo');
      } else {
        await supabase.storage.from('asistencias').upload(fileName, File(_picked!.path));
        final pub = supabase.storage.from('asistencias').getPublicUrl(fileName);
        photoUrl = pub.toString();
      }

      // determinar usuario y empresa
      final String? userId = widget.userId ?? supabase.auth.currentUser?.id;
      String? empresaId;

      // Si hay un usuario autenticado en Supabase, intentar obtener su empresa desde la tabla 'usuarios'
      if (userId != null) {
        try {
          final usuario = await supabase.from('usuarios').select('empresa_id').eq('id', userId).maybeSingle();
          if (usuario != null && usuario['empresa_id'] != null) {
            empresaId = usuario['empresa_id'].toString();
          }
        } catch (e) {
          debugPrint('No se pudo obtener empresa desde usuarios: $e');
        }
      }

      // Si no se obtuvo empresa desde 'usuarios', intentar por nombre de institución (fallback)
      if (empresaId == null && widget.institutionName != null && widget.institutionName!.isNotEmpty) {
        final e = await supabase.from('empresas').select('id').eq('nombre', widget.institutionName!).maybeSingle();
        if (e != null && e['id'] != null) empresaId = e['id'].toString();
      }

      final dispositivo = {
        'platform': kIsWeb ? 'web' : (Platform.operatingSystem),
        'timestamp': DateTime.now().toIso8601String(),
      };

      final payload = {
        if (userId != null) 'usuario_id': userId,
        if (empresaId != null) 'empresa_id': empresaId,
        'tipo': 'entrada',
        'latitud': lat,
        'longitud': lon,
        'capturado_en': DateTime.now().toUtc().toIso8601String(),
        'foto_url': photoUrl,
        'dispositivo': dispositivo,
      };

      final inserted = await supabase.from('registros_asistencia').insert([payload]).select().maybeSingle();
      if (inserted != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registro guardado')));
        setState(() => _picked = null);
      } else {
        throw Exception('No se obtuvo respuesta del insert');
      }
    } catch (e) {
      debugPrint('Error saving registro: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error guardando registro: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capturar Asistencia'),
        backgroundColor: Colors.black87,
        actions: [IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))],
      ),
      backgroundColor: const Color(0xFF0F1720),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _picked == null
                    ? Column(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
                          child: const Center(child: Icon(Icons.camera_alt, color: Colors.white70, size: 48)),
                        ),
                        const SizedBox(height: 12),
                        const Text('Vista previa de la cámara', style: TextStyle(color: Colors.white70)),
                      ])
                    : Builder(builder: (context) {
                        if (kIsWeb) {
                          return FutureBuilder<Uint8List>(
                            future: _picked!.readAsBytes(),
                            builder: (context, snap) {
                              if (!snap.hasData) return const SizedBox.shrink();
                              return Image.memory(snap.data!, fit: BoxFit.contain);
                            },
                          );
                        } else {
                          return Image.file(File(_picked!.path), fit: BoxFit.contain);
                        }
                      }),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF0B1220),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD92344), padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: _isPicking ? null : _capture,
                  icon: const Icon(Icons.camera_alt),
                  label: _isPicking ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Capturar Foto'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
