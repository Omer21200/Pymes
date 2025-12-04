import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Servicio centralizado para operaciones con Supabase.
class SupabaseService {
  
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    _initialized = true;
  }

  SupabaseClient get client => Supabase.instance.client;

  // ==================== AUTH ====================
  Future<AuthResponse> signInEmail({required String email, required String password}) async {
    return await client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUpEmail({required String email, required String password}) async {
    return await client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Fuerza el refresco de la sesión para obtener el JWT actualizado
  Future<void> refreshSession() async {
    final session = client.auth.currentSession;
    if (session != null) {
      await client.auth.refreshSession();
    }
  }

  User? get currentUser => client.auth.currentUser;

  // ==================== QUERIES EJEMPLO ====================
  /// Obtiene lista de empresas (select *).
  Future<List<Map<String, dynamic>>> getEmpresas() async {
    final response = await client
      .from('empresas')
      .select()
      .order('created_at', ascending: false);
    final list = (response as List)
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
    return list;
  }

  /// Obtiene una empresa por id
  Future<Map<String, dynamic>?> getEmpresaById(String id) async {
    final response = await client
      .from('empresas')
      .select()
      .eq('id', id)
      .maybeSingle();
    return response == null ? null : Map<String, dynamic>.from(response);
  }

  /// Inserta una empresa (requiere RLS y permisos correctos).
  Future<Map<String, dynamic>> insertEmpresa({
    required String nombre,
    String? ruc,
  }) async {
    final response = await client.from('empresas').insert({
      'nombre': nombre,
      'ruc': ruc,
    }).select().single();
    return response;
  }

  /// Ejemplo de obtener perfil propio (depende de política RLS).
  Future<Map<String, dynamic>?> getMyProfile() async {
    if (currentUser == null) return null;
    final response = await client.from('profiles').select().eq('id', currentUser!.id).maybeSingle();
    return response;
  }

  // ==================== STORAGE ====================
  /// Sube un archivo al bucket 'fotos' en la carpeta especificada.
  /// Retorna la URL pública del archivo subido.
  Future<String> uploadFile({
    required String filePath,
    required String bucketName,
    required String destinationPath,
  }) async {
    try {
      await client.storage.from(bucketName).upload(
        destinationPath,
        File(filePath),
        fileOptions: const FileOptions(upsert: true),
      );
    } catch (e) {
      throw Exception('Storage upload failed (bucket: $bucketName, path: $destinationPath): $e');
    }

    // Obtener URL pública
    try {
      final publicUrl = client.storage.from(bucketName).getPublicUrl(destinationPath);
      return publicUrl;
    } catch (e) {
      throw Exception('Failed to get public URL for $bucketName/$destinationPath: $e');
    }
  }

  /// Elimina un archivo del storage.
  Future<void> deleteFile({
    required String bucketName,
    required String filePath,
  }) async {
    try {
      await client.storage.from(bucketName).remove([filePath]);
    } catch (e) {
      throw Exception('Storage delete failed (bucket: $bucketName, path: $filePath): $e');
    }
  }

  /// Mueve/renombra un archivo dentro del mismo bucket y retorna la nueva URL pública.
  Future<String> moveFile({
    required String bucketName,
    required String fromPath,
    required String toPath,
  }) async {
    try {
      await client.storage.from(bucketName).move(fromPath, toPath);
    } catch (e) {
      throw Exception('Storage move failed (bucket: $bucketName, from: $fromPath, to: $toPath): $e');
    }

    try {
      return client.storage.from(bucketName).getPublicUrl(toPath);
    } catch (e) {
      throw Exception('Failed to get public URL for moved file $bucketName/$toPath: $e');
    }
  }

  // ==================== EMPRESAS CRUD ====================
  /// Crea una nueva empresa.
  Future<Map<String, dynamic>> createEmpresa({
    required String nombre,
    String? ruc,
    String? direccion,
    String? telefono,
    String? correo,
    String? empresaFotoUrl,
    double? latitud,
    double? longitud,
    required String codigoAcceso,
  }) async {
    final response = await client.from('empresas').insert({
      'nombre': nombre,
      if (ruc != null) 'ruc': ruc,
      if (direccion != null) 'direccion': direccion,
      if (telefono != null) 'telefono': telefono,
      if (correo != null) 'correo': correo,
      if (empresaFotoUrl != null) 'empresa_foto_url': empresaFotoUrl,
      if (latitud != null) 'latitud': latitud,
      if (longitud != null) 'longitud': longitud,
      // La columna en la base es `codigo_acceso_empleado`.
      'codigo_acceso_empleado': codigoAcceso,
    }).select().single();
    return response;
  }

  /// Actualiza una empresa existente.
  Future<Map<String, dynamic>> updateEmpresa({
    required String empresaId,
    String? nombre,
    String? ruc,
    String? direccion,
    String? telefono,
    String? correo,
    String? empresaFotoUrl,
    double? latitud,
    double? longitud,
  }) async {
    final updates = <String, dynamic>{};
    if (nombre != null) updates['nombre'] = nombre;
    if (ruc != null) updates['ruc'] = ruc;
    if (direccion != null) updates['direccion'] = direccion;
    if (telefono != null) updates['telefono'] = telefono;
    if (correo != null) updates['correo'] = correo;
    if (empresaFotoUrl != null) updates['empresa_foto_url'] = empresaFotoUrl;
    if (latitud != null) updates['latitud'] = latitud;
    if (longitud != null) updates['longitud'] = longitud;

    final response = await client
        .from('empresas')
        .update(updates)
        .eq('id', empresaId)
        .select()
        .single();
    return response;
  }

  /// Elimina una empresa.
  Future<void> deleteEmpresa(String empresaId) async {
    await client.from('empresas').delete().eq('id', empresaId);
  }

  // ==================== REGISTRO EMPLEADO ====================

  /// RPC: Inserta una solicitud de registro de empleado (usa la tabla temporal registration_requests)
  /// Llamar ANTES de signUp (la app debe luego ejecutar signUp y esperar el trigger de confirmación).
  Future<bool> registerEmployeeRequest({
    required String email,
    required String code,
    String? nombres,
    String? apellidos,
  }) async {
    final res = await client.rpc('register_employee_rpc', params: {
      'p_email': email,
      'p_code': code,
      'p_nombres': nombres,
      'p_apellidos': apellidos,
    });
    return res as bool? ?? false;
  }

  /// RPC: Inserta una solicitud de registro de admin (pre-registrado por Super Admin)
  /// Llamar ANTES de signUp; valida email + access code.
  Future<bool> registerAdminRequest({
    required String email,
    required String accessCode,
  }) async {
    final res = await client.rpc('register_admin_request_rpc', params: {
      'p_email': email,
      'p_access_code': accessCode,
    });
    return res as bool? ?? false;
  }

  /// RPC: Super Admin crea empresa y agrega la fila de admin_registration_requests
  Future<String?> createCompanyAndAdminRequest({
    required String nombreEmpresa,
    required String codigoAccesoEmpleado,
    required String adminEmail,
    required String codigoAdmin,
    required String adminNombres,
    required String adminApellidos,
  }) async {
    final res = await client.rpc('create_company_and_admin_request', params: {
      'p_nombre_empresa': nombreEmpresa,
      'p_codigo_acceso_empleado': codigoAccesoEmpleado,
      'p_email_admin': adminEmail,
      'p_codigo_admin': codigoAdmin,
      'p_nombres_admin': adminNombres,
      'p_apellidos_admin': adminApellidos,
    });
    return res?.toString();
  }

  /// RPC: Pre-registra un administrador para una empresa existente.
  /// Esta RPC debe existir en la base: `create_admin_request_for_company(p_email, p_empresa_id, p_access_code, p_nombres, p_apellidos)`
  Future<bool> createAdminRequestForCompany({
    required String email,
    required String empresaId,
    required String accessCode,
    required String nombres,
    required String apellidos,
  }) async {
    final res = await client.rpc('create_admin_request_for_company', params: {
      'p_email': email,
      'p_empresa_id': empresaId,
      'p_access_code': accessCode,
      'p_nombres': nombres,
      'p_apellidos': apellidos,
    });
    return res as bool? ?? false;
  }

  // ==================== EMPLEADO ACTUAL ====================
  /// Obtiene datos consolidados del empleado autenticado.
  /// Usa perfiles y empleados (nombre preferente desde perfiles si existe).
  Future<Map<String, dynamic>?> getEmpleadoActual() async {
    final user = currentUser;
    if (user == null) return null;
    // Perfil
    final profile = await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    // Empleado (puede existir luego de `registerEmployeeRequest` y confirmación)
    final empleado = await client
        .from('empleados')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();
    if (profile == null && empleado == null) return null;
    final nombres = (profile?['nombres'] ?? empleado?['nombres'] ?? '').toString();
    final apellidos = (profile?['apellidos'] ?? empleado?['apellidos'] ?? '').toString();
    return {
      'nombres': nombres,
      'apellidos': apellidos,
      'nombre_completo': [nombres, apellidos].where((e) => e.isNotEmpty).join(' ').trim(),
      'empresa_id': profile?['empresa_id'] ?? empleado?['empresa_id'],
      'rol': profile?['rol'],
      'correo': empleado?['correo'] ?? user.email,
      'empleado_raw': empleado,
      'profile_raw': profile,
    };
  }

  /// Actualiza los campos del empleado asociado al usuario actual.
  Future<Map<String, dynamic>?> updateEmpleadoProfile({
    String? cedula,
    String? telefono,
    String? direccion,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final empleado = await client.from('empleados').select().eq('user_id', user.id).maybeSingle();
    if (empleado == null) throw Exception('Empleado no encontrado');

    final updates = <String, dynamic>{};
    if (cedula != null) updates['cedula'] = cedula;
    if (telefono != null) updates['telefono'] = telefono;
    if (direccion != null) updates['direccion'] = direccion;

    if (updates.isEmpty) return Map<String, dynamic>.from(empleado as Map);

    try {
      final dynamic res = await client.from('empleados').update(updates).eq('id', empleado['id']).select();
      // Postgrest suele devolver una lista de filas.
      if (res is List) {
        if (res.isEmpty) return null;
        return Map<String, dynamic>.from(res.first as Map);
      }
      if (res is Map) return Map<String, dynamic>.from(res);
      return null;
    } catch (e) {
      throw Exception('Error actualizando empleado: $e');
    }
  }

  /// Registra asistencia para el empleado autenticado.
  /// - Si no existe asistencia hoy: crea con `hora_entrada = now()`.
  /// - Si existe asistencia hoy con `hora_entrada` y sin `hora_salida`: actualiza `hora_salida = now()` (marca salida).
  /// - Si ya tiene entrada y salida, lanza excepción informando que ya registró ambos.
  Future<Map<String, dynamic>> registrarAsistencia({double? latitud, double? longitud, String? fotoUrl}) async {
    final user = currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    // Obtener fila de empleado
    final empleado = await client.from('empleados').select().eq('user_id', user.id).maybeSingle();
    if (empleado == null) throw Exception('Empleado no encontrado. Ejecuta el flujo de registro y confirmación primero.');
    final empleadoId = empleado['id'] as String;

    // Fecha de hoy (YYYY-MM-DD)
    final today = DateTime.now().toIso8601String().split('T').first;

    // Buscar asistencia de hoy
    final existing = await client.from('asistencias').select().eq('empleado_id', empleadoId).eq('fecha', today).maybeSingle();

    final now = DateTime.now();
    final horaNow = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    if (existing == null) {
      // Crear entrada
      final inserted = await client.from('asistencias').insert({
        'empleado_id': empleadoId,
        'fecha': today,
        'hora_entrada': horaNow,
        if (latitud != null) 'latitud': latitud,
        if (longitud != null) 'longitud': longitud,
        if (fotoUrl != null) 'foto_url': fotoUrl,
      }).select().maybeSingle();
      return Map<String, dynamic>.from(inserted as Map);
    }

    // Si existe, manejar salida/evitar duplicados
    final horaEntrada = existing['hora_entrada'];
    final horaSalida = existing['hora_salida'];
    if (horaEntrada != null && horaSalida == null) {
      // Registrar salida
      final updated = await client.from('asistencias').update({
        'hora_salida': horaNow,
        if (latitud != null) 'latitud': latitud,
        if (longitud != null) 'longitud': longitud,
        if (fotoUrl != null) 'foto_url': fotoUrl,
      }).eq('id', existing['id']).select().maybeSingle();
      return Map<String, dynamic>.from(updated as Map);
    }

    // Ya registró entrada y salida
    throw Exception('Ya registraste entrada y salida para hoy.');
  }

  // registrar_empleado_confirmado DEPRECATED: se mantiene comentado por referencia.
  // Preferir flujo: 1) `registerEmployeeRequest` (RPC) ANTES de 2) `signUpEmail`.
  // El trigger `handle_user_confirmed` creará el profile/empleado al confirmar.
}
