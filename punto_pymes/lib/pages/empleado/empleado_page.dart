import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

import 'widgets/empleado_header.dart';
import '../../service/supabase_service.dart';
import 'widgets/empleado_nav.dart';
import 'widgets/empleado_sections.dart';
import 'widgets/notification_helper.dart';
import '../superadmin/logout_helper.dart';

class EmpleadoPage extends StatefulWidget {
  const EmpleadoPage({super.key});

  @override
  State<EmpleadoPage> createState() => _EmpleadoPageState();
}

class _EmpleadoPageState extends State<EmpleadoPage> {
  int _selectedTab = 0;
  final GlobalKey _sectionsKey = GlobalKey();

  void _handleRegister() {
    _registerAttendance();
  }

  Future<void> _registerAttendance() async {
    try {
      // 1) Capturar ubicación
      double? lat;
      double? lon;
      try {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          // Servicio de ubicación desactivado; no bloquear flujo
          lat = null;
          lon = null;
        } else {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.deniedForever) {
            // Permiso denegado permanentemente -> no bloquear, sugerir ajuste
            if (mounted) NotificationHelper.showWarningNotification(
              context,
              title: 'Permisos desactivados',
              message: 'Activa permisos de ubicación en ajustes.',
            );
            lat = null;
            lon = null;
          } else if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
            try {
              final pos = await Geolocator.getCurrentPosition(
                locationSettings: const LocationSettings(
                  accuracy: LocationAccuracy.high,
                  distanceFilter: 0,
                ),
              ).timeout(const Duration(seconds: 8));
              lat = pos.latitude;
              lon = pos.longitude;
            } catch (posErr) {
              // Timeout or error obtaining position; continue without blocking
              lat = null;
              lon = null;
            }
          } else {
            lat = null;
            lon = null;
          }
        }
      } catch (locErr) {
        // No bloquear flujo si falla la ubicación
        lat = null;
        lon = null;
      }

      // 2) Tomar foto con cámara
      String? uploadedUrl;
      try {
        final picker = ImagePicker();
        // Lanzamos la cámara; si el usuario cancela, abortamos el registro
        final XFile? photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 75);
        if (photo == null) {
          // Usuario canceló la toma de foto -> cancelar registro
          uploadedUrl = null;
          if (mounted) NotificationHelper.showWarningNotification(
            context,
            title: 'Registro cancelado',
            message: 'No se tomó la foto. El registro fue cancelado.',
          );
          return;
        }

        if (photo != null) {
          // Subir la foto al storage: bucket 'fotos' en carpeta empleados/asistencias
          final user = SupabaseService.instance.currentUser;
          final filename = 'empleados/asistencias/${user?.id ?? 'anon'}/${DateTime.now().millisecondsSinceEpoch}.jpg';
          try {
            uploadedUrl = await SupabaseService.instance.uploadFile(
              filePath: photo.path,
              bucketName: 'fotos',
              destinationPath: filename,
            );
          } catch (upErr) {
            uploadedUrl = null;
            if (mounted) NotificationHelper.showErrorNotification(
              context,
              title: 'Error en la foto',
              message: 'No se pudo subir. Continuando sin ella.',
            );
          }
        }
      } catch (camErr) {
        uploadedUrl = null;
      }

      // 3) Registrar asistencia enviando lat/lon y fotoUrl si disponibles
      final resp = await SupabaseService.instance.registrarAsistencia(latitud: lat, longitud: lon, fotoUrl: uploadedUrl);
      if (mounted) {
        final horaEntrada = resp['hora_entrada'] ?? '';
        final horaSalida = resp['hora_salida'];
        
        if (horaSalida != null) {
          NotificationHelper.showSuccessNotification(
            context,
            title: '¡Salida registrada!',
            message: 'Tu salida ha sido registrada a las $horaSalida',
          );
        } else {
          NotificationHelper.showSuccessNotification(
            context,
            title: '¡Entrada registrada!',
            message: 'Tu entrada ha sido registrada a las $horaEntrada',
          );
        }
        
        // Refrescar reportes después de registro exitoso
        (_sectionsKey.currentState as dynamic)?.refreshReportes();
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString();
        
        // Determinar si es un error de duplicado
        if (errorMessage.contains('registraste entrada y salida')) {
          NotificationHelper.showWarningNotification(
            context,
            title: 'Registro completo',
            message: 'Ya registraste entrada y salida para hoy.',
          );
        } else if (errorMessage.contains('Empleado no encontrado')) {
          NotificationHelper.showErrorNotification(
            context,
            title: 'Error de configuración',
            message: 'Completa tu perfil primero.',
          );
        } else {
          NotificationHelper.showErrorNotification(
            context,
            title: 'Error al registrar',
            message: 'Intenta de nuevo.',
          );
        }
      }
    }
  }

  void _handleTabChange(int index) {
    setState(() => _selectedTab = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Column(
              children: [
                FutureBuilder<Map<String, dynamic>?>(
                  future: SupabaseService.instance.getEmpleadoActual(),
                  builder: (context, snapshot) {
                    final loading = snapshot.connectionState == ConnectionState.waiting;
                    final data = snapshot.data;
                    final nombre = data?['nombre_completo'] ?? (loading ? 'Cargando...' : 'Sin nombre');
                    final rol = data?['rol'] ?? '';
                    final afiliacion = loading
                        ? 'Obteniendo datos'
                        : rol == 'EMPLEADO'
                            ? 'Empleado'
                            : (rol.isEmpty ? 'Rol desconocido' : rol);
                    return EmpleadoHeader(
                      name: nombre,
                      affiliation: afiliacion,
                      onLogout: () => showLogoutConfirmation(context),
                    );
                  },
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: EmpleadoSections(
                      key: _sectionsKey,
                      tabIndex: _selectedTab,
                      onNavigateTab: (tab) => setState(() => _selectedTab = tab),
                      onRegistrarAsistencia: _handleRegister,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: EmpleadoNav(
                    currentIndex: _selectedTab,
                    onTabSelected: _handleTabChange,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
            Positioned(
              right: 16,
              bottom: 96, // Levanta el botón para que quede arriba del nav
              child: FloatingActionButton(
                onPressed: _handleRegister,
                backgroundColor: const Color(0xFFD92344),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
