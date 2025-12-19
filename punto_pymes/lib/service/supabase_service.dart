import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../pages/empleado/widgets/hora_internet_ecuador.dart';

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

  /// Asegurar que la sesión está activa y refrescar si es necesario
  Future<void> ensureSessionValid() async {
    try {
      final session = client.auth.currentSession;
      if (session != null) {
        // Intentar refrescar la sesión
        await client.auth.refreshSession();
      }
    } catch (e) {
      print('⚠️ Error refrescando sesión: $e');
    }
  }

  // ==================== AUTH ====================
  Future<AuthResponse> signInEmail({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUpEmail({
    required String email,
    required String password,
  }) async {
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

  // ==================== HORA DE ECUADOR (LOJA) ====================
  /// Obtiene la hora actual de Ecuador desde worldtimeapi.org
  Future<DateTime> getEcuadorTime() async {
    try {
      final response = await http
          .get(Uri.parse('https://worldtimeapi.org/api/timezone/America/Guayaquil'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final datetimeStr = data['datetime'] as String;
        final dt = DateTime.parse(datetimeStr).toUtc();
        print('✓ Hora de Ecuador (internet): ${dt.hour}:${dt.minute}:${dt.second}');
        return dt;
      }
    } catch (e) {
      print('⚠️ Error obteniendo hora de Ecuador: $e');
    }
    return DateTime.now();
  }

  // ==================== QUERIES EJEMPLO ====================
  /// Obtiene lista de empresas (select *).
  Future<List<Map<String, dynamic>>> getEmpresas() async {
    try {
      // Refrescar sesión antes de hacer la consulta
      await ensureSessionValid();
      
      final response = await client
          .from('empresas')
          .select()
          .order('created_at', ascending: false);
      final list = (response as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      return list;
    } catch (e) {
      print('❌ Error en getEmpresas: $e');
      // Intentar refrescar sesión y reintentar una vez
      try {
        await client.auth.refreshSession();
        final response = await client
            .from('empresas')
            .select()
            .order('created_at', ascending: false);
        final list = (response as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        return list;
      } catch (retryError) {
        print('❌ Error en getEmpresas (reintento): $retryError');
        rethrow;
      }
    }
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

  // ==================== HELPER PRIVADO: OBTENER EMPRESA ID SEGURO ====================
  /// Busca el empresa_id directamente en la tabla 'profiles' (o 'empleados').
  /// Esto evita errores si el JWT (appMetadata) está desactualizado.
  Future<String> _getEmpresaIdSeguro() async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado.');

    // 1. Intentamos leer de 'profiles' que es la fuente de verdad rápida
    final profile = await client
        .from('profiles')
        .select('empresa_id')
        .eq('id', user.id)
        .maybeSingle();

    if (profile != null && profile['empresa_id'] != null) {
      return profile['empresa_id'] as String;
    }

    // 2. Fallback: Intentamos leer de 'empleados' por si acaso
    final empleado = await client
        .from('empleados')
        .select('empresa_id')
        .eq('user_id', user.id)
        .maybeSingle();

    if (empleado != null && empleado['empresa_id'] != null) {
      return empleado['empresa_id'] as String;
    }

    throw Exception('No se encontró una empresa asociada a este usuario.');
  }

  /// Inserta una empresa (requiere RLS y permisos correctos).
  Future<Map<String, dynamic>> insertEmpresa({
    required String nombre,
    String? ruc,
  }) async {
    final response = await client
        .from('empresas')
        .insert({'nombre': nombre, 'ruc': ruc})
        .select()
        .single();
    return response;
  }

  /// Ejemplo de obtener perfil propio (depende de política RLS).
  Future<Map<String, dynamic>?> getMyProfile() async {
    if (currentUser == null) return null;
    final response = await client
        .from('profiles')
        .select()
        .eq('id', currentUser!.id)
        .maybeSingle();
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
      await client.storage
          .from(bucketName)
          .upload(
            destinationPath,
            File(filePath),
            fileOptions: const FileOptions(upsert: true),
          );
    } catch (e) {
      throw Exception(
        'Storage upload failed (bucket: $bucketName, path: $destinationPath): $e',
      );
    }

    // Obtener URL pública
    try {
      final publicUrl = client.storage
          .from(bucketName)
          .getPublicUrl(destinationPath);
      return publicUrl;
    } catch (e) {
      throw Exception(
        'Failed to get public URL for $bucketName/$destinationPath: $e',
      );
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
      throw Exception(
        'Storage delete failed (bucket: $bucketName, path: $filePath): $e',
      );
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
      throw Exception(
        'Storage move failed (bucket: $bucketName, from: $fromPath, to: $toPath): $e',
      );
    }

    try {
      return client.storage.from(bucketName).getPublicUrl(toPath);
    } catch (e) {
      throw Exception(
        'Failed to get public URL for moved file $bucketName/$toPath: $e',
      );
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
    final response = await client
        .from('empresas')
        .insert({
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
        })
        .select()
        .single();
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

  // ==================== DEPARTAMENTOS CRUD ====================
  Future<void> createDepartamento({
    required String nombre,
    required String empresaId,
    String? descripcion,
  }) async {
    try {
      await client.from('departamentos').insert({
        'nombre': nombre,
        'empresa_id': empresaId,
        'descripcion': descripcion,
      });
    } catch (e) {
      // Manejar el error, por ejemplo, si el nombre ya existe para esa empresa
      // o si hay un problema de permisos.
      print('Error al crear el departamento: $e');
      throw Exception('No se pudo crear el departamento');
    }
  }

  Future<List<Map<String, dynamic>>> getDepartamentosPorEmpresa(
    String empresaId,
  ) async {
    final response = await client
        .from('departamentos')
        .select()
        .eq('empresa_id', empresaId)
        .order('nombre', ascending: true);
    return (response as List).map((e) => e as Map<String, dynamic>).toList();
  }

  /// Elimina un departamento por su id.
  Future<void> deleteDepartamento(String departamentoId) async {
    try {
      await client.from('departamentos').delete().eq('id', departamentoId);
    } catch (e) {
      throw Exception('No se pudo eliminar el departamento: $e');
    }
  }

  /// Obtiene un departamento por su id.
  Future<Map<String, dynamic>?> getDepartamentoById(
    String departamentoId,
  ) async {
    final response = await client
        .from('departamentos')
        .select()
        .eq('id', departamentoId)
        .maybeSingle();
    return response;
  }

  /// Actualiza los campos de un departamento.
  Future<Map<String, dynamic>?> updateDepartamento({
    required String departamentoId,
    String? nombre,
    String? descripcion,
  }) async {
    final updates = <String, dynamic>{};
    if (nombre != null) updates['nombre'] = nombre;
    if (descripcion != null) updates['descripcion'] = descripcion;

    if (updates.isEmpty) return null;

    final response = await client
        .from('departamentos')
        .update(updates)
        .eq('id', departamentoId)
        .select()
        .maybeSingle();

    if (response == null) return null;
    return Map<String, dynamic>.from(response as Map);
  }

  /// Obtiene los departamentos asociados a una noticia (ids y nombres).
  Future<List<Map<String, dynamic>>> getDepartamentosPorNoticia(
    String noticiaId,
  ) async {
    final response = await client
        .from('noticias_departamentos')
        .select('departamento_id, departamentos(nombre)')
        .eq('noticia_id', noticiaId);

    // La consulta puede devolver objetos con departamento_id y un campo 'departamentos'
    // que contiene los datos del departamento. Normalizamos a una lista simple.
    return (response as List).map((e) {
      final map = e as Map<String, dynamic>;
      final dep = <String, dynamic>{};
      dep['id'] = map['departamento_id']?.toString() ?? map['departamento_id'];
      if (map['departamentos'] != null && map['departamentos'] is Map) {
        dep['nombre'] = (map['departamentos'] as Map)['nombre'];
      }
      return dep;
    }).toList();
  }

  // ==================== HORARIOS CRUD ====================

  /// Obtiene el horario de un departamento.
  Future<Map<String, dynamic>?> getHorarioPorDepartamento(
    String departamentoId,
  ) async {
    final response = await client
        .from('horarios_departamento')
        .select()
        .eq('departamento_id', departamentoId)
        .maybeSingle();
    return response;
  }

  /// Crea o actualiza el horario de un departamento.
  Future<Map<String, dynamic>> upsertHorarioDepartamento({
    required String departamentoId,
    required bool lunes,
    required bool martes,
    required bool miercoles,
    required bool jueves,
    required bool viernes,
    required bool sabado,
    required bool domingo,
    required String horaEntrada, // Formato HH:mm:ss
    required String horaSalida, // Formato HH:mm:ss
    required int tolerancia,
  }) async {
    final response = await client
        .from('horarios_departamento')
        .upsert({
          'departamento_id': departamentoId,
          'lunes': lunes,
          'martes': martes,
          'miercoles': miercoles,
          'jueves': jueves,
          'viernes': viernes,
          'sabado': sabado,
          'domingo': domingo,
          'hora_entrada': horaEntrada,
          'hora_salida': horaSalida,
          'tolerancia_entrada_minutos': tolerancia,
          'updated_at': 'now()', // Actualiza el timestamp
        }, onConflict: 'departamento_id')
        .select()
        .single();
    return response;
  }

  // ==================== NOTICIAS CRUD ====================

  /// RPC: Obtiene las noticias del usuario autenticado con su estado de lectura.
  /// Filtra según el tipo de audiencia (global o departamento).
  Future<List<Map<String, dynamic>>> getNoticiasUsuario({
    int limite = 20,
  }) async {
    try {
      final response = await client.rpc(
        'get_noticias_usuario',
        params: {'p_limite': limite},
      );

      if (response == null) return [];

      return (response as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      throw Exception('Error obteniendo noticias: $e');
    }
  }

  /// RPC: Marca una noticia como leída por el usuario autenticado.
  Future<bool> marcarNoticiaLeida(String noticiaId) async {
    try {
      final response = await client.rpc(
        'marcar_noticia_leida',
        params: {'p_noticia_id': noticiaId},
      );
      return response as bool? ?? false;
    } catch (e) {
      print('Error marcando noticia como leída: $e');
      return false;
    }
  }

  /// Obtiene todas las noticias para el administrador de la empresa.
  Future<List<Map<String, dynamic>>> getNoticiasAdmin() async {
    // Obtenemos ID seguro
    final empresaId = await _getEmpresaIdSeguro();

    final response = await client
        .from('noticias')
        .select(
          'id, titulo, contenido, fecha_publicacion, es_importante, tipo_audiencia',
        )
        .eq('empresa_id', empresaId) // Filtro explícito
        .order('fecha_publicacion', ascending: false);
    return (response as List).map((e) => e as Map<String, dynamic>).toList();
  }

  /// Crea o actualiza una noticia (CORREGIDO: Usa ID seguro)
  Future<void> upsertNoticia({
    String? noticiaId,
    required String titulo,
    required String contenido,
    required bool esImportante,
    required String tipoAudiencia,
    Set<String> departamentos = const {},
    String? imagenPath,
  }) async {
    // 1. Obtener ID de empresa de la BD, no del token
    final empresaId = await _getEmpresaIdSeguro();

    String? imageUrl;
    if (imagenPath != null) {
      final fileName = 'noticia_${DateTime.now().millisecondsSinceEpoch}.jpg';
      imageUrl = await uploadFile(
        filePath: imagenPath,
        bucketName: 'fotos',
        destinationPath: 'noticias/$fileName',
      );
    }

    final noticiaData = {
      'empresa_id': empresaId,
      'creador_id': currentUser!.id,
      'titulo': titulo,
      'contenido': contenido,
      'es_importante': esImportante,
      'tipo_audiencia': tipoAudiencia,
      if (imageUrl != null) 'imagen_url': imageUrl,
    };

    Map<String, dynamic> upsertedNoticia;
    if (noticiaId != null) {
      upsertedNoticia = await client
          .from('noticias')
          .update(noticiaData)
          .eq('id', noticiaId)
          .select()
          .single();
    } else {
      upsertedNoticia = await client
          .from('noticias')
          .insert(noticiaData)
          .select()
          .single();
    }

    final newNoticiaId = upsertedNoticia['id'];

    // Gestión de departamentos (Igual que antes)
    await client
        .from('noticias_departamentos')
        .delete()
        .eq('noticia_id', newNoticiaId);

    if (tipoAudiencia == 'departamento' && departamentos.isNotEmpty) {
      final deptosData = departamentos
          .map(
            (deptoId) => {
              'noticia_id': newNoticiaId,
              'departamento_id': deptoId,
            },
          )
          .toList();
      await client.from('noticias_departamentos').insert(deptosData);
    }
  }

  /// Elimina una noticia y su imagen asociada del Storage.
  Future<void> deleteNoticia(String noticiaId) async {
    final noticia = await client
        .from('noticias')
        .select('imagen_url')
        .eq('id', noticiaId)
        .maybeSingle();

    await client.from('noticias').delete().eq('id', noticiaId);

    final imageUrl = noticia?['imagen_url'] as String?;
    if (imageUrl != null) {
      try {
        // Extraer el path del archivo desde la URL completa
        final path = imageUrl
            .substring(imageUrl.lastIndexOf('/noticias%2F') + 12)
            .replaceAll('%20', ' ');
        await deleteFile(bucketName: 'fotos', filePath: 'noticias/$path');
      } catch (e) {
        print('No se pudo eliminar la imagen del storage: $e');
      }
    }
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
    final res = await client.rpc(
      'register_employee_rpc',
      params: {
        'p_email': email,
        'p_code': code,
        'p_nombres': nombres,
        'p_apellidos': apellidos,
      },
    );
    return res as bool? ?? false;
  }

  /// RPC: Inserta una solicitud de registro de admin (pre-registrado por Super Admin)
  /// Llamar ANTES de signUp; valida email + access code.
  Future<bool> registerAdminRequest({
    required String email,
    required String accessCode,
  }) async {
    final res = await client.rpc(
      'register_admin_request_rpc',
      params: {'p_email': email, 'p_access_code': accessCode},
    );
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
    final res = await client.rpc(
      'create_company_and_admin_request',
      params: {
        'p_nombre_empresa': nombreEmpresa,
        'p_codigo_acceso_empleado': codigoAccesoEmpleado,
        'p_email_admin': adminEmail,
        'p_codigo_admin': codigoAdmin,
        'p_nombres_admin': adminNombres,
        'p_apellidos_admin': adminApellidos,
      },
    );
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
    final res = await client.rpc(
      'create_admin_request_for_company',
      params: {
        'p_email': email,
        'p_empresa_id': empresaId,
        'p_access_code': accessCode,
        'p_nombres': nombres,
        'p_apellidos': apellidos,
      },
    );
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
    final nombres = (profile?['nombres'] ?? empleado?['nombres'] ?? '')
        .toString();
    final apellidos = (profile?['apellidos'] ?? empleado?['apellidos'] ?? '')
        .toString();
    return {
      'nombres': nombres,
      'apellidos': apellidos,
      'nombre_completo': [
        nombres,
        apellidos,
      ].where((e) => e.isNotEmpty).join(' ').trim(),
      'empresa_id': profile?['empresa_id'] ?? empleado?['empresa_id'],
      'rol': profile?['rol'],
      'correo': empleado?['correo'] ?? user.email,
      'empleado_raw': empleado,
      'profile_raw': profile,
    };
  }

  /// Sube una foto de perfil para el usuario actual y retorna la URL pública.
  Future<String> uploadProfilePhoto({
    required String filePath,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Usuario no autenticado');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final destination = 'profiles/${user.id}_avatar_$timestamp.jpg';
    return await uploadFile(filePath: filePath, bucketName: 'fotos', destinationPath: destination);
  }

  /// Actualiza campos de la tabla `profiles` para el usuario actual.
  Future<Map<String, dynamic>?> updateMyProfile({
    String? nombres,
    String? apellidos,
    String? fotoUrl,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final updates = <String, dynamic>{};
    if (nombres != null) updates['nombres'] = nombres;
    if (apellidos != null) updates['apellidos'] = apellidos;
    if (fotoUrl != null) updates['foto_url'] = fotoUrl;

    if (updates.isEmpty) {
      final profile = await client.from('profiles').select().eq('id', user.id).maybeSingle();
      return profile == null ? null : Map<String, dynamic>.from(profile as Map);
    }

    try {
      final dynamic res = await client
          .from('profiles')
          .update(updates)
          .eq('id', user.id)
          .select();
      if (res is List) {
        if (res.isEmpty) return null;
        return Map<String, dynamic>.from(res.first as Map);
      }
      if (res is Map) return Map<String, dynamic>.from(res);
      return null;
    } catch (e) {
      throw Exception('Error actualizando profile: $e');
    }
  }

  /// Actualiza los campos del empleado asociado al usuario actual.
  Future<Map<String, dynamic>?> updateEmpleadoProfile({
    String? cedula,
    String? telefono,
    String? direccion,
    String? departamentoId,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final empleado = await client
        .from('empleados')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();
    if (empleado == null) throw Exception('Empleado no encontrado');

    final updates = <String, dynamic>{};
    if (cedula != null) updates['cedula'] = cedula;
    if (telefono != null) updates['telefono'] = telefono;
    if (direccion != null) updates['direccion'] = direccion;
    if (departamentoId != null) updates['departamento_id'] = departamentoId;

    if (updates.isEmpty) return Map<String, dynamic>.from(empleado as Map);

    try {
      final dynamic res = await client
          .from('empleados')
          .update(updates)
          .eq('id', empleado['id'])
          .select();
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
  /// - Usa la hora de Ecuador (America/Guayaquil) desde internet.
  Future<Map<String, dynamic>> registrarAsistencia({
    double? latitud,
    double? longitud,
    String? fotoUrl,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    // Obtener fila de empleado
    final empleado = await client
        .from('empleados')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();
    if (empleado == null)
      throw Exception(
        'Empleado no encontrado. Ejecuta el flujo de registro y confirmación primero.',
      );
    final empleadoId = empleado['id'] as String;

    // Obtener hora de Ecuador: primero desde EcuadorTimeManager (si está sincronizado)
    // Si no está disponible, hacer request a la API
    DateTime now = EcuadorTimeManager.getCurrentTime() ?? await getEcuadorTime();
    
    // Convertir de UTC a hora de Ecuador (UTC-5, es decir, restar 5 horas)
    final ecuadorTime = now.toUtc().subtract(const Duration(hours: 5));
    
    // Fecha de hoy (YYYY-MM-DD) usando hora de Ecuador
    final today = ecuadorTime.toIso8601String().split('T').first;

    // Buscar asistencia de hoy
    final existing = await client
        .from('asistencias')
        .select()
        .eq('empleado_id', empleadoId)
        .eq('fecha', today)
        .maybeSingle();

    final horaNow =
        '${ecuadorTime.hour.toString().padLeft(2, '0')}:${ecuadorTime.minute.toString().padLeft(2, '0')}:${ecuadorTime.second.toString().padLeft(2, '0')}';

    if (existing == null) {
      // Crear entrada
      final inserted = await client
          .from('asistencias')
          .insert({
            'empleado_id': empleadoId,
            'fecha': today,
            'hora_entrada': horaNow,
            if (latitud != null) 'latitud': latitud,
            if (longitud != null) 'longitud': longitud,
            if (fotoUrl != null) 'foto_url': fotoUrl,
          })
          .select()
          .maybeSingle();
      return Map<String, dynamic>.from(inserted as Map);
    }

    // Si existe, manejar salida/evitar duplicados
    final horaEntrada = existing['hora_entrada'];
    final horaSalida = existing['hora_salida'];
    if (horaEntrada != null && horaSalida == null) {
      // Registrar salida
      final updated = await client
          .from('asistencias')
          .update({
            'hora_salida': horaNow,
            if (latitud != null) 'latitud': latitud,
            if (longitud != null) 'longitud': longitud,
            if (fotoUrl != null) 'foto_url': fotoUrl,
          })
          .eq('id', existing['id'])
          .select()
          .maybeSingle();
      return Map<String, dynamic>.from(updated as Map);
    }

    // Ya registró entrada y salida
    throw Exception('Ya registraste entrada y salida para hoy.');
  }

  // registrar_empleado_confirmado DEPRECATED: se mantiene comentado por referencia.
  // Preferir flujo: 1) `registerEmployeeRequest` (RPC) ANTES de 2) `signUpEmail`.
  // El trigger `handle_user_confirmed` creará el profile/empleado al confirmar.

  // ==================== ADMIN DASHBOARD ====================

  /// Obtiene el resumen de datos para el dashboard del administrador.
  Future<Map<String, dynamic>> getAdminDashboardSummary() async {
    final response = await client.rpc('get_admin_dashboard_summary');
    return response as Map<String, dynamic>;
  }

  /// Obtiene los últimos registros de asistencia del día para la empresa del admin.
  Future<List<Map<String, dynamic>>> getUltimosRegistros() async {
    try {
      final empresaId = await _getEmpresaIdSeguro(); // Usamos el método seguro

      final response = await client.rpc(
        'get_asistencias_con_estado',
        params: {
          'p_empresa_id': empresaId,
          'p_fecha_desde': DateTime.now().toIso8601String().split('T').first,
          'p_fecha_hasta': DateTime.now().toIso8601String().split('T').first,
        },
      );

      // Si RPC retorna null o vacío, manejamos
      if (response == null) return [];

      // Ordenamos en Dart si el RPC no lo hizo
      final lista = (response as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
      // Opcional: ordenar por hora entrada desc
      return lista.take(5).toList();
    } catch (e) {
      print('Error en getUltimosRegistros: $e');
      return [];
    }
  }

  /// Obtiene el historial de asistencias del empleado autenticado.
  /// Retorna los últimos registros ordenados por fecha descendente.
  Future<List<Map<String, dynamic>>> getHistorialAsistencias({
    int limite = 30,
  }) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      // Obtener empleado_id del usuario actual
      final empleado = await client
          .from('empleados')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (empleado == null) throw Exception('Empleado no encontrado');
      final empleadoId = empleado['id'] as String;

      // Obtener asistencias del empleado
      final response = await client
          .from('asistencias')
          .select(
            'id, fecha, hora_entrada, hora_salida, foto_url, estado, observacion, latitud, longitud, created_at',
          )
          .eq('empleado_id', empleadoId)
          .order('fecha', ascending: false)
          .limit(limite);

      return (response as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      print('Error en getHistorialAsistencias: $e');
      return [];
    }
  }

  // ==================== ESTADÍSTICAS DEL EMPLEADO ====================

  /// Obtiene estadísticas de asistencia del empleado actual
  Future<Map<String, dynamic>> getEmpleadoEstadisticas() async {
    try {
      final user = client.auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      // Obtener empleado_id
      final empleado = await client
          .from('empleados')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (empleado == null) throw Exception('Empleado no encontrado');
      final empleadoId = empleado['id'] as String;

      // Obtener asistencias del mes actual
      final ahora = DateTime.now();
      final primerDiaDelMes = DateTime(ahora.year, ahora.month, 1);
      final ultimoDiaDelMes = DateTime(ahora.year, ahora.month + 1, 0);

      final asistencias = await client
          .from('asistencias')
          .select('fecha, hora_entrada, hora_salida')
          .eq('empleado_id', empleadoId)
          .gte('fecha', primerDiaDelMes.toIso8601String().split('T')[0])
          .lte('fecha', ultimoDiaDelMes.toIso8601String().split('T')[0]);

      // Calcular estadísticas
      int diasAsistidos = 0;
      int aTiempo = 0;
      int tardanzas = 0;

      for (final asistencia in asistencias) {
        if (asistencia['hora_entrada'] != null) {
          diasAsistidos++;

          // Obtener hora de entrada
          final horaEntrada = asistencia['hora_entrada'] as String;

          // Comparar si fue a tiempo (simple: si llegó antes del mediodía)
          // En producción, esto debería compararse contra el horario del departamento
          if (horaEntrada.compareTo('12:00:00') < 0) {
            aTiempo++;
          } else {
            tardanzas++;
          }
        }
      }

      return {
        'dias_asistidos': diasAsistidos,
        'a_tiempo': aTiempo,
        'tardanzas': tardanzas,
        'total_registros': asistencias.length,
      };
    } catch (e) {
      print('Error en getEmpleadoEstadisticas: $e');
      return {
        'dias_asistidos': 0,
        'a_tiempo': 0,
        'tardanzas': 0,
        'total_registros': 0,
      };
    }
  }
}
