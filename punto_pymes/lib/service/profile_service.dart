import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

class ProfileService {
  ProfileService._();
  static final ProfileService instance = ProfileService._();

  /// Comprueba si el empleado actual tiene la información mínima (cedula) completada.
  Future<bool> hasProfile() async {
    final empleado = await SupabaseService.instance.getEmpleadoActual();
    final empleadoRaw = empleado?['empleado_raw'] as Map<String, dynamic>?;
    final cedula = empleadoRaw?['cedula'] as String?;
    return cedula != null && cedula.isNotEmpty;
  }

  /// Guarda los campos del empleado en la tabla `empleados`.
  Future<bool> saveProfile({
    required String cedula,
    String? telefono,
    String? direccion,
  }) async {
    try {
      final updated = await SupabaseService.instance.updateEmpleadoProfile(
        cedula: cedula,
        telefono: telefono,
        direccion: direccion,
      );
      return updated != null;
    } catch (e, st) {
      if (kDebugMode) debugPrint('saveProfile error: $e\n$st');
      rethrow;
    }
  }
}
