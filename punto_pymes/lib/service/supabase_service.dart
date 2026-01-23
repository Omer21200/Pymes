import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:developer' as developer;
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

  Map<String, dynamic> _toMap(dynamic v) {
    if (v == null) return {};
    if (v is Map) return Map<String, dynamic>.from(v);
    try {
      return Map<String, dynamic>.from(jsonDecode(jsonEncode(v)));
    } catch (_) {
      return {};
    }
  }

  List<Map<String, dynamic>> _listFromResponse(dynamic r) {
    if (r == null) return [];
    if (r is List) return r.map((e) => Map<String, dynamic>.from(e)).toList();
    try {
      final encoded = jsonEncode(r);
      final decoded = jsonDecode(encoded);
      if (decoded is List) {
        return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Asegurar que la sesión está activa y refrescar si es necesario
  Future<void> ensureSessionValid() async {
    try {
      final session = client.auth.currentSession;
      developer.log(
        'ensureSessionValid: currentSession=${session != null}',
        name: 'SupabaseService',
      );
      if (session != null) {
        developer.log(
          'ensureSessionValid: refreshing session...',
          name: 'SupabaseService',
        );
        try {
          await client.auth.refreshSession().timeout(
            const Duration(seconds: 8),
          );
          developer.log(
            'ensureSessionValid: refreshSession completed',
            name: 'SupabaseService',
          );
        } on TimeoutException catch (_) {
          developer.log(
            'ensureSessionValid: refreshSession timed out',
            name: 'SupabaseService',
          );
        } catch (e) {
          developer.log(
            'ensureSessionValid: refreshSession error: $e',
            name: 'SupabaseService',
          );
        }
      }
    } catch (e) {
      developer.log('⚠️ Error refrescando sesión: $e', name: 'SupabaseService');
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

  // Caché breve para la hora de Ecuador para evitar múltiples llamadas seguidas
  DateTime? _cachedEcuadorTime;
  DateTime? _cachedEcuadorTimeFetchedAt;
  static const Duration _ecuadorTimeCacheDuration = Duration(seconds: 10);

  // ==================== HORA DE ECUADOR (LOJA) ====================
  /// Obtiene la hora actual de Ecuador desde worldtimeapi.org
  Future<DateTime> getEcuadorTime({bool throwOnFailure = false}) async {
    // Return cached value when still fresh
    try {
      if (_cachedEcuadorTime != null && _cachedEcuadorTimeFetchedAt != null) {
        final age = DateTime.now().difference(_cachedEcuadorTimeFetchedAt!);
        if (age < _ecuadorTimeCacheDuration) {
          developer.log(
            'Usando hora de cache (age: ${age.inSeconds}s)',
            name: 'SupabaseService',
          );
          return _cachedEcuadorTime!.toUtc();
        }
      }
    } catch (_) {}

    // Prefer RPC on Supabase which returns the DB server time in 'America/Guayaquil'.
    try {
      await ensureSessionValid();
      final rpcResult = await client
          .rpc('get_ecuador_time')
          .timeout(const Duration(seconds: 5));

      // RPC may return different shapes depending on driver; normalize.
      DateTime? parsed;
      if (rpcResult == null) {
        parsed = null;
      } else if (rpcResult is String) {
        parsed = DateTime.tryParse(rpcResult);
      } else if (rpcResult is Map) {
        // Example: {get_ecuador_time: "2026-01-22 21:00:00"}
        final firstVal = rpcResult.values.first;
        parsed = DateTime.tryParse(firstVal?.toString() ?? '');
      } else if (rpcResult is List && rpcResult.isNotEmpty) {
        final first = rpcResult.first;
        if (first is Map) {
          final val = first.values.first;
          parsed = DateTime.tryParse(val?.toString() ?? '');
        } else {
          parsed = DateTime.tryParse(first.toString());
        }
      }

      if (parsed != null) {
        // Assume DB returned local Ecuador time; convert to UTC for internal use.
        final utc = parsed.toUtc();
        // Update cache
        _cachedEcuadorTime = utc;
        _cachedEcuadorTimeFetchedAt = DateTime.now();
        developer.log(
          '✓ Hora Ecuador (RPC): ${utc.toIso8601String()}',
          name: 'SupabaseService',
        );
        return utc;
      } else {
        developer.log(
          'RPC get_ecuador_time returned unexpected payload: $rpcResult',
          name: 'SupabaseService',
        );
      }
    } catch (e, st) {
      developer.log('RPC get_ecuador_time failed: $e', name: 'SupabaseService');
      developer.log('Stack: $st', name: 'SupabaseService');
    }

    // RPC failed — fallback to trusted external providers (retry with backoff).
    final uris = [
      Uri.parse('https://worldtimeapi.org/api/timezone/America/Guayaquil'),
      Uri.parse(
        'https://timeapi.io/api/Time/current/zone?timeZone=America/Guayaquil',
      ),
    ];

    for (final uri in uris) {
      for (var attempt = 0; attempt < 3; attempt++) {
        try {
          final response = await http
              .get(uri)
              .timeout(const Duration(seconds: 6));
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            String? datetimeStr;
            if (uri.host.contains('worldtimeapi')) {
              datetimeStr = data['datetime'] as String?;
            } else if (uri.host.contains('timeapi.io')) {
              datetimeStr =
                  data['dateTime'] as String? ?? data['date_time'] as String?;
            }
            if (datetimeStr != null && datetimeStr.isNotEmpty) {
              final dt = DateTime.tryParse(datetimeStr);
              if (dt != null) {
                final utc = dt.toUtc();
                _cachedEcuadorTime = utc;
                _cachedEcuadorTimeFetchedAt = DateTime.now();
                developer.log(
                  '✓ Hora de Ecuador (fallback): ${utc.toIso8601String()}',
                  name: 'SupabaseService',
                );
                return utc;
              }
            }
          }
        } catch (_) {
          if (attempt < 2) {
            await Future.delayed(Duration(milliseconds: 300 * (1 << attempt)));
          }
        }
      }
    }

    developer.log(
      '⚠️ No se pudo obtener hora remota (RPC + fallbacks)',
      name: 'SupabaseService',
    );
    if (throwOnFailure) throw Exception('No se pudo obtener hora remota');
    return DateTime.now().toUtc();
  }

  // ==================== QUERIES EJEMPLO ====================
  /// Obtiene lista de empresas (select *).
  Future<List<Map<String, dynamic>>> getEmpresas() async {
    try {
      // Refrescar sesión antes de hacer la consulta
      await ensureSessionValid(); // Ensure session is valid before querying

      final response = await client
          .from('empresas')
          .select()
          .order('created_at', ascending: false);
      final list = _listFromResponse(response);
      return list;
    } catch (e) {
      developer.log('❌ Error en getEmpresas: $e', name: 'SupabaseService');
      // Intentar refrescar sesión y reintentar una vez
      try {
        await client.auth.refreshSession();
        final response = await client
            .from('empresas')
            .select()
            .order('created_at', ascending: false);
        final list = (response)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        return list;
      } catch (retryError) {
        developer.log(
          '❌ Error en getEmpresas (reintento): $retryError',
          name: 'SupabaseService',
        );
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

  /// Geocode an address using Nominatim (OpenStreetMap).
  /// Returns a map with keys 'lat' and 'lng' as doubles, or null if not found.
  Future<Map<String, double>?> geocodeAddress(String address) async {
    try {
      final encoded = Uri.encodeComponent(address);
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$encoded&format=json&limit=1',
      );
      final resp = await http
          .get(url, headers: {'User-Agent': 'pymes-app/1.0'})
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List<dynamic>;
        if (data.isNotEmpty) {
          final first = data.first as Map<String, dynamic>;
          final lat = double.tryParse(first['lat']?.toString() ?? '');
          final lon = double.tryParse(first['lon']?.toString() ?? '');
          if (lat != null && lon != null) return {'lat': lat, 'lng': lon};
        }
      }
    } catch (e) {
      developer.log('Geocode error: $e', name: 'SupabaseService');
    }
    return null;
  }

  /// Search for address/place suggestions using Nominatim (OpenStreetMap).
  /// Returns a list of maps with keys: 'display_name', 'lat', 'lon'.
  Future<List<Map<String, dynamic>>> geocodeSearch(
    String query, {
    int limit = 5,
  }) async {
    try {
      final q = query.trim();
      if (q.isEmpty) return [];

      final encoded = Uri.encodeComponent(q);
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$encoded&format=json&limit=$limit&addressdetails=1&accept-language=es',
      );
      final resp = await http
          .get(url, headers: {'User-Agent': 'pymes-app/1.0'})
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List<dynamic>;
        final list = (data).map((e) => Map<String, dynamic>.from(e)).toList();

        if (list.isEmpty) return [];

        // Boost exact-country and country-type matches so searching "Ecuador"
        // returns the country and not unrelated smaller places.
        final qLower = q.toLowerCase();
        list.sort((a, b) {
          var scoreA = 0;
          var scoreB = 0;

          final aType = (a['type']?.toString() ?? '').toLowerCase();
          final bType = (b['type']?.toString() ?? '').toLowerCase();
          if (aType == 'country') scoreA += 200;
          if (bType == 'country') scoreB += 200;

          final aAddrRaw = a['address'];
          final bAddrRaw = b['address'];
          final aAddr = aAddrRaw is Map
              ? Map<String, dynamic>.from(aAddrRaw)
              : <String, dynamic>{};
          final bAddr = bAddrRaw is Map
              ? Map<String, dynamic>.from(bAddrRaw)
              : <String, dynamic>{};
          if ((aAddr['country']?.toString().toLowerCase() ?? '') == qLower) {
            scoreA += 100;
          }
          if ((bAddr['country']?.toString().toLowerCase() ?? '') == qLower) {
            scoreB += 100;
          }

          final aDisp = (a['display_name']?.toString().toLowerCase() ?? '');
          final bDisp = (b['display_name']?.toString().toLowerCase() ?? '');
          if (aDisp == qLower) scoreA += 80;
          if (bDisp == qLower) scoreB += 80;

          final impA = double.tryParse(a['importance']?.toString() ?? '') ?? 0;
          final impB = double.tryParse(b['importance']?.toString() ?? '') ?? 0;
          scoreA += (impA * 10).toInt();
          scoreB += (impB * 10).toInt();

          return scoreB - scoreA;
        });

        return list;
      }
    } catch (e) {
      developer.log('Geocode search error: $e', name: 'SupabaseService');
    }
    return [];
  }

  /// Convenience method to update empresa coordinates by id.
  Future<Map<String, dynamic>?> updateEmpresaCoordinates(
    String empresaId,
    double lat,
    double lng,
  ) async {
    final res = await updateEmpresa(
      empresaId: empresaId,
      latitud: lat,
      longitud: lng,
    );
    return res;
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
    double? radiusMeters,
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
          if (radiusMeters != null) 'radius_m': radiusMeters,
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
    String? jornadaEntrada,
    String? jornadaSalidaAlmuerzo,
    String? jornadaRegresoAlmuerzo,
    String? jornadaSalida,
    double? radiusMeters,
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
    if (jornadaEntrada != null) updates['jornada_entrada'] = jornadaEntrada;
    if (jornadaSalidaAlmuerzo != null) {
      updates['jornada_salida_almuerzo'] = jornadaSalidaAlmuerzo;
    }
    if (jornadaRegresoAlmuerzo != null) {
      updates['jornada_regreso_almuerzo'] = jornadaRegresoAlmuerzo;
    }
    if (jornadaSalida != null) updates['jornada_salida'] = jornadaSalida;
    if (radiusMeters != null) updates['radius_m'] = radiusMeters;

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
      developer.log(
        'Error al crear el departamento: $e',
        name: 'SupabaseService',
      );
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
    return _listFromResponse(response);
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
    return Map<String, dynamic>.from(response);
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
    return (response).map((e) {
      final map = Map<String, dynamic>.from(e);
      final dep = <String, dynamic>{};
      dep['id'] = map['departamento_id']?.toString() ?? map['departamento_id'];
      final deptos = map['departamentos'];
      if (deptos is Map) {
        dep['nombre'] = deptos['nombre'];
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
    String? horaSalidaAlmuerzo,
    String? horaRegresoAlmuerzo,
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
          // Always include lunch fields in upsert so we can set them to NULL when needed.
          'hora_salida_almuerzo': horaSalidaAlmuerzo,
          'hora_regreso_almuerzo': horaRegresoAlmuerzo,
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
      // Add a timeout to avoid indefinite hangs that can freeze the UI
      final response = await client
          .rpc('get_noticias_usuario', params: {'p_limite': limite})
          .timeout(const Duration(seconds: 12));

      return _listFromResponse(response);
    } on TimeoutException catch (e) {
      throw Exception('Timeout obteniendo noticias: $e');
    } catch (e) {
      throw Exception('Error obteniendo noticias: $e');
    }
  }

  /// Obtiene las últimas noticias creadas por el usuario autenticado.
  Future<List<Map<String, dynamic>>> getMisUltimasNoticias({
    int limite = 4,
  }) async {
    try {
      final user = currentUser;
      if (user == null) return [];
      final response = await client
          .from('noticias')
          .select(
            'id, titulo, contenido, imagen_url, es_importante, fecha_publicacion, tipo_audiencia',
          )
          .eq('creador_id', user.id)
          .order('fecha_publicacion', ascending: false)
          .limit(limite);
      return _listFromResponse(response);
    } catch (e) {
      developer.log(
        'Error obteniendo mis noticias: $e',
        name: 'SupabaseService',
      );
      return [];
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
      developer.log(
        'Error marcando noticia como leída: $e',
        name: 'SupabaseService',
      );
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
    return _listFromResponse(response);
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
        developer.log(
          'No se pudo eliminar la imagen del storage: $e',
          name: 'SupabaseService',
        );
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
  Future<String> uploadProfilePhoto({required String filePath}) async {
    final user = currentUser;
    if (user == null) throw Exception('Usuario no autenticado');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final destination = 'profiles/${user.id}_avatar_$timestamp.jpg';
    return await uploadFile(
      filePath: filePath,
      bucketName: 'fotos',
      destinationPath: destination,
    );
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
      final profile = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      return profile == null ? null : Map<String, dynamic>.from(profile);
    }

    try {
      final dynamic res = await client
          .from('profiles')
          .update(updates)
          .eq('id', user.id)
          .select();
      if (res is List) {
        if (res.isEmpty) return null;
        return Map<String, dynamic>.from(res.first);
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

    final profile = await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    Map<String, dynamic>? empleado = await client
        .from('empleados')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    // Si el empleado no existe (caso de cuentas nuevas que no completaron el alta), lo creamos.
    if (empleado == null) {
      final empresaId = profile?['empresa_id'];
      if (empresaId == null) {
        throw Exception('Empleado no encontrado');
      }

      final baseRow = <String, dynamic>{
        'user_id': user.id,
        'empresa_id': empresaId,
        'correo': user.email,
        'nombres': profile?['nombres'],
        'apellidos': profile?['apellidos'],
      };

      if (cedula != null) baseRow['cedula'] = cedula;
      if (telefono != null) baseRow['telefono'] = telefono;
      if (direccion != null) baseRow['direccion'] = direccion;
      if (departamentoId != null) baseRow['departamento_id'] = departamentoId;

      final inserted = await client
          .from('empleados')
          .insert(baseRow)
          .select()
          .maybeSingle();

      if (inserted == null) {
        throw Exception('No se pudo crear el empleado');
      }

      empleado = Map<String, dynamic>.from(inserted);
    }

    final updates = <String, dynamic>{};
    if (cedula != null) updates['cedula'] = cedula;
    if (telefono != null) updates['telefono'] = telefono;
    if (direccion != null) updates['direccion'] = direccion;
    if (departamentoId != null) updates['departamento_id'] = departamentoId;

    if (updates.isEmpty) return Map<String, dynamic>.from(empleado);

    try {
      // Hacemos el update sin `select()` para evitar políticas RLS que bloqueen el retorno de filas.
      await client.from('empleados').update(updates).eq('id', empleado['id']);

      // Releemos la fila para confirmar que se guardó.
      final refreshed = await client
          .from('empleados')
          .select()
          .eq('id', empleado['id'])
          .maybeSingle();

      if (refreshed == null) {
        throw Exception('No se actualizó el empleado');
      }

      return Map<String, dynamic>.from(refreshed);
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
    if (empleado == null) {
      throw Exception(
        'Empleado no encontrado. Ejecuta el flujo de registro y confirmación primero.',
      );
    }
    final empleadoId = empleado['id']?.toString();
    if (empleadoId == null) {
      throw Exception('Empleado sin id');
    }

    // Obtener hora de Ecuador: primero desde EcuadorTimeManager (si está sincronizado)
    // Si no está disponible, hacer request a la API
    DateTime now =
        EcuadorTimeManager.getCurrentTime() ??
        await getEcuadorTime(throwOnFailure: true);

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
      // No crear noticia pública por marcas de asistencia.
      return _toMap(inserted);
    }

    // Si existe, manejar la secuencia de 4 marcas:
    // 1) hora_entrada
    // 2) hora_salida_almuerzo
    // 3) hora_regreso_almuerzo
    // 4) hora_salida
    final horaEntrada = existing['hora_entrada'];
    final horaSalidaAlm = existing['hora_salida_almuerzo'];
    final horaRegresoAlm = existing['hora_regreso_almuerzo'];
    final horaSalidaFinal = existing['hora_salida'];

    if (horaEntrada != null && horaSalidaAlm == null) {
      // Registrar salida al almuerzo
      final updated = await client
          .from('asistencias')
          .update({
            'hora_salida_almuerzo': horaNow,
            'estado': 'completado',
            if (latitud != null) 'latitud': latitud,
            if (longitud != null) 'longitud': longitud,
            if (fotoUrl != null) 'foto_url': fotoUrl,
          })
          .eq('id', existing['id'])
          .select()
          .maybeSingle();
      // No crear noticia por salida a almuerzo.
      return _toMap(updated);
    }

    if (horaEntrada != null &&
        horaSalidaAlm != null &&
        horaRegresoAlm == null) {
      // Registrar regreso del almuerzo
      final updated = await client
          .from('asistencias')
          .update({
            'hora_regreso_almuerzo': horaNow,
            'estado': 'completado',
            if (latitud != null) 'latitud': latitud,
            if (longitud != null) 'longitud': longitud,
            if (fotoUrl != null) 'foto_url': fotoUrl,
          })
          .eq('id', existing['id'])
          .select()
          .maybeSingle();
      // No crear noticia por regreso de almuerzo.
      return _toMap(updated);
    }

    if (horaEntrada != null &&
        horaSalidaAlm != null &&
        horaRegresoAlm != null &&
        horaSalidaFinal == null) {
      // Registrar salida final
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
      // No crear noticia por salida final.
      return _toMap(updated);
    }

    // Si no hay hora_entrada aún, eso se maneja arriba en existing == null branch.
    // Si ya registró las 4 marcas, lanzar excepción para evitar duplicados
    throw Exception('Ya registraste todas las marcas para hoy.');
  }

  /// Reporta una violación de geofence (empleado fuera del radio permitido).
  /// Inserta una fila en la tabla `attendance_violations` (si existe).
  Future<void> reportAttendanceViolation({
    required String empleadoId,
    required String empresaId,
    double? latitud,
    double? longitud,
    required double distanceMeters,
  }) async {
    try {
      // Insert violation and request the inserted row so we can get its id
      final inserted = await client
          .from('attendance_violations')
          .insert({
            'empleado_id': empleadoId,
            'empresa_id': empresaId,
            'latitud': latitud,
            'longitud': longitud,
            'distance_m': distanceMeters,
            'created_at': DateTime.now().toUtc().toIso8601String(),
          })
          .select()
          .maybeSingle();

      final violationId = inserted == null
          ? null
          : (inserted['id']?.toString());

      // No crear una 'noticia' para violaciones de geofence: esto no debe
      // aparecer como noticia para el empleado. Mantenemos el registro en
      // `attendance_violations` y marcamos la asistencia con `violation_reported`.

      // Best-effort: update today's asistencias row to point to this violation or set flag
      try {
        // Compute Ecuador date (reuse existing helpers)
        DateTime now =
            EcuadorTimeManager.getCurrentTime() ?? await getEcuadorTime();
        final ecuadorTime = now.toUtc().subtract(const Duration(hours: 5));
        final today = ecuadorTime.toIso8601String().split('T').first;

        final updates = <String, dynamic>{'violation_reported': true};
        if (violationId != null) updates['last_violation_id'] = violationId;

        await client
            .from('asistencias')
            .update(updates)
            .eq('empleado_id', empleadoId)
            .eq('fecha', today);
      } catch (u) {
        developer.log(
          'No pudo actualizar asistencias con la violación: $u',
          name: 'SupabaseService',
        );
      }
    } catch (e) {
      developer.log(
        'Error reporting attendance violation: $e',
        name: 'SupabaseService',
      );
      // Do not throw: failure to report should not block the client flow.
    }
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
      developer.log(
        'getUltimosRegistros: empresaId=$empresaId',
        name: 'SupabaseService',
      );
      try {
        final uid = client.auth.currentUser?.id;
        developer.log(
          'getUltimosRegistros: currentUser.id=$uid',
          name: 'SupabaseService',
        );
      } catch (_) {}

      // Compute 'today' using Ecuador time (consistent with registrarAsistencia)
      DateTime nowForList =
          EcuadorTimeManager.getCurrentTime() ?? await getEcuadorTime();
      final ecuadorTimeForList = nowForList.toUtc().subtract(
        const Duration(hours: 5),
      );
      final todayForList = ecuadorTimeForList
          .toIso8601String()
          .split('T')
          .first;

      developer.log(
        'Using todayForList=$todayForList',
        name: 'SupabaseService',
      );
      final response = await client.rpc(
        'get_asistencias_con_estado',
        params: {
          'p_empresa_id': empresaId,
          'p_fecha_desde': todayForList,
          'p_fecha_hasta': todayForList,
        },
      );

      developer.log(
        'get_asistencias_con_estado RPC response type=${response.runtimeType}',
        name: 'SupabaseService',
      );
      developer.log(
        'get_asistencias_con_estado RPC response preview=${response is List ? (response).take(3).toList() : response}',
        name: 'SupabaseService',
      );

      // Si RPC retorna null o vacío, manejamos
      if (response is! List || (response).isEmpty) {
        // Fallback: consultar directamente la tabla `asistencias` y enriquecer con empleado/departamento
        try {
          // The `asistencias` table may not have `empresa_id`. Instead fetch
          // empleados for the company and query asistencias by empleado_id.
          final empresaId = await _getEmpresaIdSeguro();
          final today = todayForList;

          final empleadosResp = await client
              .from('empleados')
              .select('id')
              .eq('empresa_id', empresaId);
          final empleadoIds = <String>[];
          if (empleadosResp.isNotEmpty) {
            for (final e in empleadosResp) {
              try {
                final id = (e['id'] != null) ? e['id'].toString() : null;
                if (id != null) empleadoIds.add(id);
              } catch (_) {}
            }
          }

          developer.log(
            'Fallback: found ${empleadoIds.length} empleados for empresa',
            name: 'SupabaseService',
          );
          if (empleadoIds.isEmpty) return [];

          // If there's only one empleado, query with .eq which is simpler and avoids
          // PostgREST 'in' string formatting issues. For multiple empleados use
          // an OR expression supported by PostgREST.
          dynamic asistencias;
          if (empleadoIds.length == 1) {
            developer.log(
              'Fallback querying asistencias for empleado_id=${empleadoIds.first} and fecha=$today',
              name: 'SupabaseService',
            );
            asistencias = await client
                .from('asistencias')
                .select()
                .eq('empleado_id', empleadoIds.first)
                .eq('fecha', today)
                .order('hora_entrada', ascending: false)
                .limit(5);
          } else {
            final orCond = empleadoIds
                .map((id) => 'empleado_id.eq.$id')
                .join(',');
            developer.log(
              'Fallback will query asistencias using OR: $orCond and fecha=$today',
              name: 'SupabaseService',
            );
            asistencias = await client
                .from('asistencias')
                .select()
                .or(orCond)
                .eq('fecha', today)
                .order('hora_entrada', ascending: false)
                .limit(5);
          }

          developer.log(
            'Fallback asistencias count=${asistencias is List ? (asistencias).length : 0}',
            name: 'SupabaseService',
          );
          developer.log(
            'Fallback asistencias preview=${asistencias is List ? (asistencias).take(3).toList() : asistencias}',
            name: 'SupabaseService',
          );

          // If none found for today, perform a diagnostic query (no fecha filter)
          // to check whether the empleado(s) have any recent asistencias at all.
          if (asistencias is List && asistencias.isEmpty) {
            try {
              developer.log(
                'Debug: no asistencias for today, querying recent asistencias without fecha filter',
                name: 'SupabaseService',
              );
              dynamic recent;
              if (empleadoIds.length == 1) {
                recent = await client
                    .from('asistencias')
                    .select()
                    .eq('empleado_id', empleadoIds.first)
                    .order('fecha', ascending: false)
                    .order('hora_entrada', ascending: false)
                    .limit(10);
              } else {
                final orAll = empleadoIds
                    .map((id) => 'empleado_id.eq.$id')
                    .join(',');
                recent = await client
                    .from('asistencias')
                    .select()
                    .or(orAll)
                    .order('fecha', ascending: false)
                    .order('hora_entrada', ascending: false)
                    .limit(10);
              }
              developer.log(
                'Debug recent asistencias count=${recent is List ? (recent).length : 0}',
                name: 'SupabaseService',
              );
              developer.log(
                'Debug recent asistencias preview=${recent is List ? (recent).take(5).toList() : recent}',
                name: 'SupabaseService',
              );
            } catch (dbgErr) {
              developer.log(
                'Debug recent asistencias query error: $dbgErr',
                name: 'SupabaseService',
              );
            }
            return [];
          }
          final asistenciasList = asistencias;

          final List<Map<String, dynamic>> lista = [];
          for (final a in asistenciasList) {
            final Map<String, dynamic> row = Map<String, dynamic>.from(a);
            final empleadoId = row['empleado_id']?.toString();
            String empleadoNombre = 'N/A';
            String departamentoNombre = 'Sin departamento';
            if (empleadoId != null) {
              final empleado = await client
                  .from('empleados')
                  .select('nombres,apellidos,departamento_id')
                  .eq('id', empleadoId)
                  .maybeSingle();
              if (empleado != null) {
                final noms = empleado['nombres']?.toString() ?? '';
                final apes = empleado['apellidos']?.toString() ?? '';
                empleadoNombre = [
                  noms,
                  apes,
                ].where((s) => s.isNotEmpty).join(' ').trim();
                final depId = empleado['departamento_id']?.toString();
                if (depId != null) {
                  final dep = await client
                      .from('departamentos')
                      .select('nombre')
                      .eq('id', depId)
                      .maybeSingle();
                  if (dep != null) {
                    departamentoNombre =
                        dep['nombre']?.toString() ?? departamentoNombre;
                  }
                }
              }
            }

            lista.add({
              'empleado_nombre': empleadoNombre,
              'hora_entrada': row['hora_entrada']?.toString(),
              'estado': row['estado']?.toString(),
              'departamento': departamentoNombre,
            });
          }
          return lista;
        } catch (fallbackErr) {
          developer.log(
            'Fallback getUltimosRegistros error: $fallbackErr',
            name: 'SupabaseService',
          );
          return [];
        }
      }
      final lista = (response)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      // Opcional: ordenar por hora entrada desc
      developer.log(
        'getUltimosRegistros: lista length=${lista.length}',
        name: 'SupabaseService',
      );
      developer.log(
        'getUltimosRegistros preview=${lista.take(3).toList()}',
        name: 'SupabaseService',
      );

      if (lista.isEmpty) {
        // Debug fallback: try to return last 5 asistencias globally (no empresa filter)
        try {
          developer.log(
            'getUltimosRegistros: lista empty, attempting global fallback',
            name: 'SupabaseService',
          );
          final globalAsistencias = await client
              .from('asistencias')
              .select()
              .order('fecha', ascending: false)
              .order('hora_entrada', ascending: false)
              .limit(5);
          developer.log(
            'Global fallback asistencias count=${(globalAsistencias as List).length}',
            name: 'SupabaseService',
          );
          if (globalAsistencias.isNotEmpty) {
            final List<Map<String, dynamic>> globalLista = [];
            for (final a in globalAsistencias) {
              final Map<String, dynamic> row = Map<String, dynamic>.from(a);
              final empleadoId = row['empleado_id']?.toString();
              String empleadoNombre = 'N/A';
              String departamentoNombre = 'Sin departamento';
              if (empleadoId != null) {
                final empleado = await client
                    .from('empleados')
                    .select('nombres,apellidos,departamento_id')
                    .eq('id', empleadoId)
                    .maybeSingle();
                if (empleado != null) {
                  final noms = empleado['nombres']?.toString() ?? '';
                  final apes = empleado['apellidos']?.toString() ?? '';
                  empleadoNombre = [
                    noms,
                    apes,
                  ].where((s) => s.isNotEmpty).join(' ').trim();
                  final depId = empleado['departamento_id']?.toString();
                  if (depId != null) {
                    final dep = await client
                        .from('departamentos')
                        .select('nombre')
                        .eq('id', depId)
                        .maybeSingle();
                    if (dep != null) {
                      departamentoNombre =
                          dep['nombre']?.toString() ?? departamentoNombre;
                    }
                  }
                }
              }
              globalLista.add({
                'empleado_nombre': empleadoNombre,
                'hora_entrada': row['hora_entrada']?.toString(),
                'estado': row['estado']?.toString(),
                'departamento': departamentoNombre,
              });
            }
            developer.log(
              'Returning global fallback lista length=${globalLista.length}',
              name: 'SupabaseService',
            );
            return globalLista;
          }
        } catch (globalErr) {
          developer.log(
            'Global fallback error: $globalErr',
            name: 'SupabaseService',
          );
        }
      }

      return lista.take(5).toList();
    } catch (e) {
      developer.log(
        'Error en getUltimosRegistros: $e',
        name: 'SupabaseService',
      );
      return [];
    }
  }

  /// Obtiene los últimos registros de asistencia para un empleado específico.
  /// Devuelve hasta `limite` filas ordenadas por fecha/hora descendente y
  /// ya normalizadas a `List<Map<String, dynamic>>` con campos:
  /// `empleado_nombre`, `hora_entrada`, `estado`, `departamento`.
  Future<List<Map<String, dynamic>>> getUltimosRegistrosPorEmpleado(
    String empleadoId, {
    int limite = 4,
  }) async {
    try {
      await ensureSessionValid();
      final resp = await client
          .from('asistencias')
          .select()
          .eq('empleado_id', empleadoId)
          .order('fecha', ascending: false)
          .order('hora_entrada', ascending: false)
          .limit(limite);

      if (resp.isEmpty) return [];
      final asistencias = (resp)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      // Fetch empleado name and departamento once
      String empleadoNombre = 'N/A';
      String departamentoNombre = 'Sin departamento';
      try {
        final empleado = await client
            .from('empleados')
            .select('nombres,apellidos,departamento_id')
            .eq('id', empleadoId)
            .maybeSingle();
        if (empleado != null) {
          final noms = empleado['nombres']?.toString() ?? '';
          final apes = empleado['apellidos']?.toString() ?? '';
          empleadoNombre = [
            noms,
            apes,
          ].where((s) => s.isNotEmpty).join(' ').trim();
          final depId = empleado['departamento_id']?.toString();
          if (depId != null) {
            final dep = await client
                .from('departamentos')
                .select('nombre')
                .eq('id', depId)
                .maybeSingle();
            if (dep != null) {
              departamentoNombre =
                  dep['nombre']?.toString() ?? departamentoNombre;
            }
          }
        }
      } catch (_) {}

      final List<Map<String, dynamic>> lista = [];
      for (final a in asistencias) {
        final Map<String, dynamic> row = Map<String, dynamic>.from(a);
        lista.add({
          'empleado_nombre': empleadoNombre,
          'hora_entrada': row['hora_entrada']?.toString(),
          'estado': row['estado']?.toString(),
          'departamento': departamentoNombre,
        });
      }

      return lista;
    } catch (e) {
      developer.log(
        'Error en getUltimosRegistrosPorEmpleado: $e',
        name: 'SupabaseService',
      );
      return [];
    }
  }

  /// Obtiene los últimos registros de asistencia para la empresa del usuario
  /// autenticado. Internamente obtiene el `empresaId` seguro y devuelve hasta
  /// `limite` filas ordenadas por fecha/hora descendente, normalizadas.
  Future<List<Map<String, dynamic>>> getUltimosRegistrosEmpresa({
    int limite = 4,
  }) async {
    try {
      final empresaId = await _getEmpresaIdSeguro();
      // Obtener empleados de la empresa
      final empleadosResp = await client
          .from('empleados')
          .select('id')
          .eq('empresa_id', empresaId);
      final empleadoIds = <String>[];
      if (empleadosResp.isNotEmpty) {
        for (final e in empleadosResp) {
          try {
            final id = (e['id'] != null) ? e['id'].toString() : null;
            if (id != null) empleadoIds.add(id);
          } catch (_) {}
        }
      }

      developer.log(
        'getUltimosRegistrosEmpresa: empresaId=$empresaId, empleadoCount=${empleadoIds.length}',
        name: 'SupabaseService',
      );

      if (empleadoIds.isEmpty) return [];

      dynamic asistencias;
      if (empleadoIds.length == 1) {
        asistencias = await client
            .from('asistencias')
            .select()
            .eq('empleado_id', empleadoIds.first)
            .order('fecha', ascending: false)
            .order('hora_entrada', ascending: false)
            .limit(limite);
        developer.log(
          'getUltimosRegistrosEmpresa: querying asistencias for empleado_id=${empleadoIds.first} limit=$limite',
          name: 'SupabaseService',
        );
      } else {
        final orCond = empleadoIds.map((id) => 'empleado_id.eq.$id').join(',');
        developer.log(
          'getUltimosRegistrosEmpresa: querying asistencias with OR: $orCond limit=$limite',
          name: 'SupabaseService',
        );
        asistencias = await client
            .from('asistencias')
            .select()
            .or(orCond)
            .order('fecha', ascending: false)
            .order('hora_entrada', ascending: false)
            .limit(limite);
      }

      developer.log(
        'getUltimosRegistrosEmpresa: asistencias response type=${asistencias.runtimeType}',
        name: 'SupabaseService',
      );
      developer.log(
        'getUltimosRegistrosEmpresa: asistencias preview=${asistencias is List ? (asistencias).take(3).toList() : asistencias}',
        name: 'SupabaseService',
      );

      if (asistencias is! List || asistencias.isEmpty) return [];
      final asistenciasList = (asistencias)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final List<Map<String, dynamic>> lista = [];
      for (final a in asistenciasList) {
        final row = Map<String, dynamic>.from(a);
        final empleadoId = row['empleado_id']?.toString();
        String empleadoNombre = 'N/A';
        String departamentoNombre = 'Sin departamento';
        if (empleadoId != null) {
          try {
            final empleado = await client
                .from('empleados')
                .select('nombres,apellidos,departamento_id')
                .eq('id', empleadoId)
                .maybeSingle();
            if (empleado != null) {
              final noms = empleado['nombres']?.toString() ?? '';
              final apes = empleado['apellidos']?.toString() ?? '';
              empleadoNombre = [
                noms,
                apes,
              ].where((s) => s.isNotEmpty).join(' ').trim();
              final depId = empleado['departamento_id']?.toString();
              if (depId != null) {
                final dep = await client
                    .from('departamentos')
                    .select('nombre')
                    .eq('id', depId)
                    .maybeSingle();
                if (dep != null) {
                  departamentoNombre =
                      dep['nombre']?.toString() ?? departamentoNombre;
                }
              }
            }
          } catch (_) {}
        }

        lista.add({
          'empleado_nombre': empleadoNombre,
          'hora_entrada': row['hora_entrada']?.toString(),
          'estado': row['estado']?.toString(),
          'departamento': departamentoNombre,
        });
      }

      return lista;
    } catch (e) {
      developer.log(
        'Error en getUltimosRegistrosEmpresa: $e',
        name: 'SupabaseService',
      );
      return [];
    }
  }

  /// Obtiene los registros de asistencias de la empresa del usuario autenticado.
  /// Permite filtrar por rango de fechas `desde` / `hasta`. Si no se proveen,
  /// devuelve hasta `limit` filas más recientes.
  Future<List<Map<String, dynamic>>> getRegistrosEmpresa({
    DateTime? desde,
    DateTime? hasta,
    int limit = 200,
    int offset = 0,
  }) async {
    try {
      final empresaId = await _getEmpresaIdSeguro();
      developer.log(
        'getRegistrosEmpresa: empresaId=$empresaId',
        name: 'SupabaseService',
      );

      // Obtener empleados de la empresa
      final empleadosResp = await client
          .from('empleados')
          .select('id')
          .eq('empresa_id', empresaId);
      final empleadoIds = <String>[];
      if (empleadosResp.isNotEmpty) {
        for (final e in empleadosResp) {
          try {
            final id = (e['id'] != null) ? e['id'].toString() : null;
            if (id != null) empleadoIds.add(id);
          } catch (_) {}
        }
      }

      developer.log(
        'getRegistrosEmpresa: empleadoCount=${empleadoIds.length}',
        name: 'SupabaseService',
      );

      if (empleadoIds.isEmpty) return [];

      // Construir consulta base
      // Traer todas las columnas para no perder latitud/longitud ni futuros campos
      final q = client.from('asistencias').select('*');

      if (empleadoIds.length == 1) {
        q.eq('empleado_id', empleadoIds.first);
      } else {
        final orCond = empleadoIds.map((id) => 'empleado_id.eq.$id').join(',');
        developer.log(
          'getRegistrosEmpresa: orCond=$orCond',
          name: 'SupabaseService',
        );
        q.or(orCond);
      }

      if (desde != null) {
        final s = desde.toIso8601String().split('T').first;
        q.gte('fecha', s);
      }
      if (hasta != null) {
        final h = hasta.toIso8601String().split('T').first;
        q.lte('fecha', h);
      }

      q
          .order('fecha', ascending: false)
          .order('hora_entrada', ascending: false);

      if (limit > 0) q.limit(limit);
      if (offset > 0) q.range(offset, offset + limit - 1);

      final resp = await q;
      developer.log(
        'getRegistrosEmpresa: raw resp type=${resp.runtimeType}',
        name: 'SupabaseService',
      );
      final rows = _listFromResponse(resp);
      try {
        if (rows.isNotEmpty) {
          developer.log(
            'getRegistrosEmpresa first row keys=${rows.first.keys}',
            name: 'SupabaseService',
          );
        }
      } catch (_) {}
      developer.log(
        'getRegistrosEmpresa: rowsCount=${rows.length} preview=${rows.take(3).toList()}',
        name: 'SupabaseService',
      );

      // Enriquecer con nombre de empleado y departamento
      final List<Map<String, dynamic>> result = [];
      for (final r in rows) {
        final row = Map<String, dynamic>.from(r);
        final empleadoId = row['empleado_id']?.toString();
        String empleadoNombre = 'N/A';
        String departamentoNombre = 'Sin departamento';
        if (empleadoId != null) {
          try {
            final empleado = await client
                .from('empleados')
                .select('nombres,apellidos,departamento_id')
                .eq('id', empleadoId)
                .maybeSingle();
            if (empleado != null) {
              final noms = empleado['nombres']?.toString() ?? '';
              final apes = empleado['apellidos']?.toString() ?? '';
              final full = [
                noms,
                apes,
              ].where((s) => s.isNotEmpty).join(' ').trim();
              if (full.isNotEmpty) empleadoNombre = full;
              final depId = empleado['departamento_id']?.toString();
              if (depId != null) {
                final dep = await client
                    .from('departamentos')
                    .select('nombre')
                    .eq('id', depId)
                    .maybeSingle();
                if (dep != null) {
                  departamentoNombre =
                      dep['nombre']?.toString() ?? departamentoNombre;
                }
              }
            }
          } catch (_) {}
        }

        result.add({
          'id': row['id']?.toString(),
          'fecha': row['fecha']?.toString(),
          'hora_entrada': row['hora_entrada']?.toString(),
          'hora_salida': row['hora_salida']?.toString(),
          'estado': row['estado']?.toString(),
          'observacion': row['observacion']?.toString(),
          'empresa_id': row['empresa_id']?.toString(),
          // Pasar coordenadas crudas para el marcador del empleado
          'latitud': row['latitud']?.toString(),
          'longitud': row['longitud']?.toString(),
          // Por si vienen variantes
          'lat': row['lat']?.toString(),
          'lng': row['lng']?.toString(),
          'empleado_id': empleadoId,
          'empleado_nombre': empleadoNombre,
          'departamento': departamentoNombre,
          'created_at': row['created_at']?.toString(),
        });
      }

      return result;
    } catch (e) {
      developer.log(
        'Error en getRegistrosEmpresa: $e',
        name: 'SupabaseService',
      );
      return [];
    }
  }

  /// Actualiza solo el campo `observacion` de una asistencia por id.
  Future<bool> updateObservacionAsistencia({
    required String id,
    required String observacion,
    String? empleadoId,
  }) async {
    try {
      await ensureSessionValid();
      final parsedId = int.tryParse(id);
      final filterValue = parsedId ?? id;

      final q = client
          .from('asistencias')
          .update({'observacion': observacion})
          .eq('id', filterValue);

      if (empleadoId != null && empleadoId.isNotEmpty) {
        q.eq('empleado_id', empleadoId);
      }

      final response = await q.select('id, observacion, empleado_id').limit(1);

      final updated =
          (response.isNotEmpty) || (response is Map && response.isNotEmpty);
      developer.log(
        'updateObservacionAsistencia: respType=${response.runtimeType} updated=$updated value=$response',
        name: 'SupabaseService',
      );

      if (!updated) {
        try {
          final precheck = await client
              .from('asistencias')
              .select('id, empleado_id')
              .eq('id', filterValue)
              .maybeSingle();
          developer.log(
            'updateObservacionAsistencia: precheck row visible=${precheck != null} value=$precheck',
            name: 'SupabaseService',
          );
        } catch (e) {
          developer.log(
            'updateObservacionAsistencia: precheck failed: $e',
            name: 'SupabaseService',
          );
        }
        developer.log(
          'updateObservacionAsistencia: no rows updated for id=$id empleadoId=$empleadoId (posible RLS sin permisos, id inexistente o empleado no coincide)',
          name: 'SupabaseService',
        );
      }
      return updated;
    } catch (e) {
      developer.log(
        'Error updateObservacionAsistencia: $e',
        name: 'SupabaseService',
      );
      return false;
    }
  }

  /// Obtiene el historial de asistencias del empleado autenticado.
  /// Retorna los últimos registros ordenados por fecha descendente.
  Future<List<Map<String, dynamic>>> getHistorialAsistencias({
    int limite = 30,
  }) async {
    developer.log(
      'getHistorialAsistencias: start (limite=$limite)',
      name: 'SupabaseService',
    );
    try {
      final user = currentUser;
      developer.log(
        'getHistorialAsistencias: currentUser=${user?.id}',
        name: 'SupabaseService',
      );
      if (user == null) throw Exception('Usuario no autenticado');

      // Obtener empleado_id del usuario actual
      final empleado = await client
          .from('empleados')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (empleado == null) throw Exception('Empleado no encontrado');
      final empleadoId = empleado['id']?.toString();
      if (empleadoId == null) throw Exception('Empleado sin id');

      // Ensure session valid before querying
      await ensureSessionValid();

      // Obtener asistencias del empleado con timeout y medición para evitar colgar la UI
      dynamic response;
      final sw = Stopwatch()..start();
      try {
        final future = client
            .from('asistencias')
            .select(
              'id, fecha, hora_entrada, hora_salida, hora_salida_almuerzo, hora_regreso_almuerzo, foto_url, estado, observacion, latitud, longitud, created_at',
            )
            .eq('empleado_id', empleadoId)
            .order('fecha', ascending: false)
            .limit(limite);

        // Apply a timeout that throws so we can catch and log it distinctly
        response = await future.timeout(
          const Duration(seconds: 12),
          onTimeout: () =>
              throw TimeoutException('getHistorialAsistencias query timed out'),
        );

        sw.stop();
        developer.log(
          'getHistorialAsistencias: query completed in ${sw.elapsedMilliseconds} ms',
          name: 'SupabaseService',
        );
      } on TimeoutException catch (te) {
        sw.stop();
        developer.log(
          'getHistorialAsistencias: query timed out after ${sw.elapsedMilliseconds} ms: $te',
          name: 'SupabaseService',
        );
        return [];
      } catch (qe) {
        sw.stop();
        developer.log(
          'getHistorialAsistencias: query exception after ${sw.elapsedMilliseconds} ms: $qe',
          name: 'SupabaseService',
        );
        return [];
      }

      final list = _listFromResponse(response);
      developer.log(
        'getHistorialAsistencias: fetched ${list.length} rows',
        name: 'SupabaseService',
      );
      return list;
    } catch (e) {
      developer.log(
        'Error en getHistorialAsistencias: $e',
        name: 'SupabaseService',
      );
      return [];
    }
  }

  /// Obtiene las últimas violaciones de asistencia (attendance_violations)
  /// relacionadas con el empleado autenticado.
  Future<List<Map<String, dynamic>>> getMisViolaciones({int limite = 5}) async {
    try {
      final user = currentUser;
      if (user == null) return [];

      final empleado = await client
          .from('empleados')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();
      if (empleado == null) return [];
      final empleadoId = empleado['id']?.toString();
      if (empleadoId == null) return [];

      final response = await client
          .from('attendance_violations')
          .select('id, latitud, longitud, distance_m, created_at')
          .eq('empleado_id', empleadoId)
          .order('created_at', ascending: false)
          .limit(limite);
      return _listFromResponse(response);
    } catch (e) {
      developer.log(
        'Error obteniendo violaciones de asistencia: $e',
        name: 'SupabaseService',
      );
      return [];
    }
  }

  /// Obtiene violaciones de asistencia para una empresa (uso por admin de empresa)
  Future<List<Map<String, dynamic>>> getViolationsForCompany(
    String empresaId, {
    int limit = 10,
  }) async {
    try {
      final response = await client
          .from('attendance_violations')
          .select(
            'id, empleado_id, latitud, longitud, distance_m, created_at, empleados(nombres,apellidos)',
          )
          .eq('empresa_id', empresaId)
          .order('created_at', ascending: false)
          .limit(limit);
      return _listFromResponse(response);
    } catch (e) {
      developer.log(
        'Error obteniendo violaciones por empresa: $e',
        name: 'SupabaseService',
      );
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
      final empleadoId = empleado['id']?.toString();
      if (empleadoId == null) throw Exception('Empleado sin id');

      // Obtener asistencias del mes actual
      final ahora = DateTime.now();
      final primerDiaDelMes = DateTime(ahora.year, ahora.month, 1);
      final ultimoDiaDelMes = DateTime(ahora.year, ahora.month + 1, 0);

      final asistencias = await client
          .from('asistencias')
          .select(
            'fecha, hora_entrada, hora_salida, hora_salida_almuerzo, hora_regreso_almuerzo',
          )
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
          final horaEntrada = asistencia['hora_entrada']?.toString() ?? '';

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
      developer.log(
        'Error en getEmpleadoEstadisticas: $e',
        name: 'SupabaseService',
      );
      return {
        'dias_asistidos': 0,
        'a_tiempo': 0,
        'tardanzas': 0,
        'total_registros': 0,
      };
    }
  }
}
