import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

import 'widgets/empleado_header.dart';
import 'profile_page.dart';
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
  bool _isRegistering = false;

  void _handleRegister() {
    _registerAttendance();
  }

  Future<void> _registerAttendance() async {
    if (_isRegistering) return; // evitar reentradas
    setState(() => _isRegistering = true);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Iniciando registro...')));
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
            if (mounted) {
              NotificationHelper.showWarningNotification(
                context,
                title: 'Permisos desactivados',
                message: 'Activa permisos de ubicación en ajustes.',
              );
            }
            lat = null;
            lon = null;
          } else if (permission == LocationPermission.always ||
              permission == LocationPermission.whileInUse) {
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
              if (mounted) {
                NotificationHelper.showWarningNotification(
                  context,
                  title: 'Ubicación no disponible',
                  message:
                      'No se pudo obtener la ubicación (tiempo de espera). Se continuará sin ella.',
                );
              }
              // Registro de depuración
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
        if (mounted) {
          NotificationHelper.showWarningNotification(
            context,
            title: 'Error de ubicación',
            message: 'Error al obtener la ubicación. Se continuará sin ella.',
          );
        }
      }

      // 2) Tomar foto con cámara
      String? uploadedUrl;
      try {
        final picker = ImagePicker();
        final XFile? photo = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 75,
        );
        if (photo == null) {
          // User cancelled camera — abort the attendance registration
          if (mounted) {
            NotificationHelper.showWarningNotification(
              context,
              title: 'Registro cancelado',
              message: 'No se tomó la foto. Registro cancelado.',
            );
          }
          setState(() => _isRegistering = false);
          return;
        }

        // Subir la foto al storage: bucket 'fotos' en carpeta empleados/asistencias
        final user = SupabaseService.instance.currentUser;
        final filename =
            'empleados/asistencias/${user?.id ?? 'anon'}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        try {
          // Aplicar timeout al upload para no bloquear indefinidamente
          uploadedUrl = await SupabaseService.instance
              .uploadFile(
                filePath: photo.path,
                bucketName: 'fotos',
                destinationPath: filename,
              )
              .timeout(const Duration(seconds: 12));
        } on TimeoutException catch (_) {
          uploadedUrl = null;
          if (mounted) {
            NotificationHelper.showWarningNotification(
              context,
              title: 'Foto no subida',
              message: 'La subida tardó demasiado. Se continuará sin foto.',
            );
          }
        } catch (upErr) {
          uploadedUrl = null;
          if (mounted) {
            NotificationHelper.showErrorNotification(
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
      // Geofence check: if we have device coords and company coords, verify distance
      try {
        if (lat != null && lon != null) {
          final me = await SupabaseService.instance.getEmpleadoActual();
          final empresaId = me?['empresa_id']?.toString();
          if (empresaId != null && empresaId.isNotEmpty) {
            final empresa = await SupabaseService.instance.getEmpresaById(
              empresaId,
            );
            final eLatV = empresa?['latitud'];
            final eLngV = empresa?['longitud'];
            double? eLat = (eLatV is num)
                ? eLatV.toDouble()
                : double.tryParse('$eLatV');
            double? eLng = (eLngV is num)
                ? eLngV.toDouble()
                : double.tryParse('$eLngV');

            if (eLat != null && eLng != null) {
              // Determine radius (meters) from empresa if present or default to 50m
              double radiusMeters = 50.0;
              final radiusCandidates = [
                'allowed_radius_m',
                'radius_m',
                'radio',
                'geofence_radius',
                'rango',
                'radius',
              ];
              for (final k in radiusCandidates) {
                final rv = empresa?[k];
                if (rv != null) {
                  final parsed = rv is num
                      ? rv.toDouble()
                      : double.tryParse('$rv');
                  if (parsed != null && parsed > 0) {
                    radiusMeters = parsed;
                    break;
                  }
                }
              }

              double distanceMeters = _distanceBetweenMeters(
                lat,
                lon,
                eLat,
                eLng,
              );
              if (distanceMeters > radiusMeters) {
                // Report violation and abort registration
                final empleadoRaw =
                    me?['empleado_raw'] as Map<String, dynamic>?;
                final empleadoId = empleadoRaw?['id']?.toString();
                if (empleadoId != null) {
                  await SupabaseService.instance.reportAttendanceViolation(
                    empleadoId: empleadoId,
                    empresaId: empresaId,
                    latitud: lat,
                    longitud: lon,
                    distanceMeters: distanceMeters,
                  );
                }
                if (mounted) {
                  NotificationHelper.showWarningNotification(
                    context,
                    title: 'Fuera de rango',
                    message:
                        'No puedes registrar asistencia: estás fuera del radio permitido (${distanceMeters.toStringAsFixed(0)} m).',
                  );
                }
                return;
              }
            }
          }
        }
      } catch (ge) {
        // If geofence check fails for any reason, continue with normal flow
      }

      final resp = await SupabaseService.instance
          .registrarAsistencia(
            latitud: lat,
            longitud: lon,
            fotoUrl: uploadedUrl,
          )
          .timeout(const Duration(seconds: 12));
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
      if (e is TimeoutException) {
        if (mounted) {
          NotificationHelper.showErrorNotification(
            context,
            title: 'Tiempo de espera',
            message: 'El registro tardó demasiado. Reintenta.',
          );
        }
      } else {
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
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  double _distanceBetweenMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000; // meters
    double toRad(double deg) => deg * (math.pi / 180);
    final dLat = toRad(lat2 - lat1);
    final dLon = toRad(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(toRad(lat1)) *
            math.cos(toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
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
                    final loading =
                        snapshot.connectionState == ConnectionState.waiting;
                    final data = snapshot.data;
                    final nombre =
                        data?['nombre_completo'] ??
                        (loading ? 'Cargando...' : 'Sin nombre');
                    final rol = data?['rol'] ?? '';
                    final afiliacion = loading
                        ? 'Obteniendo datos'
                        : rol == 'EMPLEADO'
                        ? 'Empleado'
                        : (rol.isEmpty ? 'Rol desconocido' : rol);
                    final profileRaw =
                        data?['profile_raw'] as Map<String, dynamic>?;
                    final avatar = profileRaw?['foto_url'] as String?;
                    return EmpleadoHeader(
                      name: nombre,
                      affiliation: afiliacion,
                      avatarUrl: avatar,
                      onLogout: () => showLogoutConfirmation(
                        context,
                        afterRoute: '/access-selection',
                      ),
                      onProfile: () async {
                        // Abrir la página de perfil y refrescar al volver si se guardó
                        final res = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const EmpleadoProfilePage(),
                          ),
                        );
                        if (res == true) {
                          setState(() {});
                        }
                      },
                    );
                  },
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: EmpleadoSections(
                      key: _sectionsKey,
                      tabIndex: _selectedTab,
                      onNavigateTab: (tab) =>
                          setState(() => _selectedTab = tab),
                      onRegistrarAsistencia: _handleRegister,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
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
                onPressed: _isRegistering ? null : _handleRegister,
                backgroundColor: const Color(0xFFD92344),
                child: _isRegistering
                    ? const SizedBox(
                        height: 28,
                        width: 28,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
