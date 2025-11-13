import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../main.dart';
import '../institucion_page/institucion_page.dart';
import '../superadmin/superadmin_page.dart';
import 'register_page.dart';
import '../admin_company/admin_company_page.dart';

class LoginPage extends StatefulWidget {
  final String selectedInstitution;
  final String selectedRole;

  const LoginPage({
    required this.selectedInstitution,
    this.selectedRole = 'Empleado',
    super.key,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _promptCompanyCodeAndProceed() async {
    // Si no se seleccionó institución (ej. Administrador General), ir directo a RegisterPage
    if (widget.selectedInstitution.isEmpty) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterPage(selectedInstitution: '')));
      return;
    }

    String code = '';
    bool isVerifying = false;
    String? localError;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx2, setStateSB) {
          return AlertDialog(
            title: const Text('Por favor ingrese el código de Empresa'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Solicita el código de 8 caracteres a tu empresa para continuar con el registro.'),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => code = v.trim(),
                  maxLength: 16,
                  decoration: const InputDecoration(hintText: 'Código de Empresa', counterText: ''),
                ),
                if (localError != null) ...[
                  const SizedBox(height: 8),
                  Text(localError!, style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: isVerifying ? null : () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: isVerifying
                    ? null
                    : () async {
                        if (code.isEmpty) {
                          setStateSB(() => localError = 'Ingresa el código de la empresa');
                          return;
                        }
                        setStateSB(() {
                          isVerifying = true;
                          localError = null;
                        });
                        try {
                          // Buscar la empresa por nombre y comparar su código
                          final res = await supabase.from('empresas').select('id,nombre,codigo_empresa').eq('nombre', widget.selectedInstitution).maybeSingle();
                          if (res == null) {
                            setStateSB(() => localError = 'No se encontró la institución en la base');
                            setStateSB(() => isVerifying = false);
                            return;
                          }
                          final dbCode = (res['codigo_empresa'] ?? '').toString().trim();
                          if (dbCode.isEmpty || dbCode.toLowerCase() != code.toLowerCase()) {
                            setStateSB(() => localError = 'Código inválido o no coincide');
                            setStateSB(() => isVerifying = false);
                            return;
                          }
                          // OK: cerrar diálogo y navegar a RegisterPage
                          Navigator.pop(ctx);
                          if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterPage(selectedInstitution: widget.selectedInstitution)));
                        } catch (e) {
                          setStateSB(() => localError = 'Error validando código');
                          setStateSB(() => isVerifying = false);
                        }
                      },
                child: isVerifying ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Validar Código'),
              )
            ],
          );
        });
      },
    );
  }

  Future<void> _handleLogin() async {
    // Validar campos
    if (_usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingresa tu usuario'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingresa tu contraseña'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String username = _usernameController.text.trim();
      String password = _passwordController.text;
      bool loginSuccess = false;
      dynamic userData;

      // 1) Intentar con Supabase Auth (recomendado)
      try {
        final authResp = await supabase.auth.signInWithPassword(
          email: username,
          password: password,
        );
        if (authResp.session != null) {
          // Login con Supabase Auth exitoso
          debugPrint('✅ Autenticación Supabase exitosa');
          // Buscar datos adicionales en tabla 'usuarios'
          try {
            final usuario = await supabase.from('usuarios').select().eq('email', username).maybeSingle();
            userData = usuario;
          } catch (_) {
            userData = null;
          }
          loginSuccess = true;
        } else {
          debugPrint('❌ signInWithPassword no retornó sesión');
        }
      } catch (authError) {
        debugPrint('❌ Supabase auth falló: $authError');
        // continuamos al fallback
      }

      // 2) Fallback: si Supabase Auth falla, intentamos validar contra la tabla
      //    `usuarios`. Algunos despliegues guardan la contraseña en texto plano
      //    (o en una columna llamada 'contraseña_hash' pero sin hash). Aquí
      //    comprobamos varias columnas posibles y comparamos en texto plano.
          if (!loginSuccess) {
        try {
          final usuario = await supabase.from('usuarios').select().eq('email', username).maybeSingle();
          if (usuario == null) throw Exception('Usuario no encontrado en tabla usuarios');

          String? storedPassword;
          // Probar varias columnas que podrían existir
          storedPassword ??= usuario['contraseña_hash']?.toString();
          storedPassword ??= usuario['password']?.toString();
          storedPassword ??= usuario['pass']?.toString();
          storedPassword ??= usuario['contraseña']?.toString();

          if (storedPassword == null) throw Exception('No se encontró campo de contraseña en la tabla usuarios');

          // Comparación segura: si la DB almacena hash (SHA256), comparamos hash(input) == stored
          final inputHash = sha256.convert(utf8.encode(password)).toString();
          if (storedPassword == password || storedPassword == inputHash) {
            loginSuccess = true;
            userData = usuario;
            debugPrint('✅ Login por tabla usuarios (fallback) OK');
          } else {
            throw Exception('Contraseña incorrecta (falló fallback tabla usuarios)');
          }
        } catch (e) {
          debugPrint('❌ Fallback tabla usuarios falló: $e');
          rethrow;
        }
      }

      // Si encontramos usuario y autenticación OK, navegar según rol
      if (loginSuccess && userData != null) {
        if (!mounted) return;
  final role = (userData['rol'] ?? userData['role'] ?? widget.selectedRole).toString();
  final nombre = (userData['nombre'] ?? userData['name'] ?? username).toString();
  final institutionNameFromUser = (userData['empresa'] ?? userData['nombre_empresa'] ?? userData['id_empresa'] ?? widget.selectedInstitution ?? 'Institución').toString();

        // Por ahora redirigimos a la pantalla de Institución para roles de empleado
        if (role == 'superadmin') {
          // Navegar a la pantalla específica de SuperAdmin
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => SuperAdminPage(userName: nombre)),
          );
        } else if (role == 'admin' || role.toLowerCase().contains('admin')) {
          // Verificar que el admin corresponde a la empresa seleccionada (si aplica)
          if (widget.selectedInstitution.isNotEmpty) {
            String? empresaIdFromUser;
            try {
              // intentar leer empresa_id directamente del objeto userData
              empresaIdFromUser = (userData['empresa_id'] ?? userData['empresa'] ?? userData['id_empresa'])?.toString();
              if (empresaIdFromUser == null) {
                // intentar consultar la tabla usuarios por email para obtener empresa_id
                final u = await supabase.from('usuarios').select('empresa_id').eq('email', username).maybeSingle();
                if (u != null && u['empresa_id'] != null) empresaIdFromUser = u['empresa_id'].toString();
              }
            } catch (e) {
              debugPrint('Error obteniendo empresa del usuario: $e');
            }

            // Obtener empresa_id por el nombre seleccionado
            String? empresaIdByName;
            try {
              final ent = await supabase.from('empresas').select('id').eq('nombre', widget.selectedInstitution).maybeSingle();
              if (ent != null && ent['id'] != null) empresaIdByName = ent['id'].toString();
            } catch (e) {
              debugPrint('Error buscando empresa por nombre: $e');
            }

            // Si no hay match, mostrar mensaje y cancelar navegación
            if (empresaIdFromUser == null || empresaIdByName == null || empresaIdFromUser != empresaIdByName) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No autorizado para esa empresa'), backgroundColor: Colors.red));
                return;
              }
            }
          }

            if (role == 'admin') {
              // Administrador de empresa (panel propio, diferente del Admin General)
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) =>
                  // pasar user id y nombre de empresa cuando estén disponibles
                  // si userData incluye 'id' y 'empresa_id' los usamos
                  AdminCompanyPage(
                    userId: (userData['id'] ?? supabase.auth.currentUser?.id ?? '').toString(),
                    companyName: (userData['empresa_nombre'] ?? userData['empresa'] ?? widget.selectedInstitution ?? '').toString(),
                  ),
                ),
              );
            } else {
              // fallback para otros tipos de admin, mantener ruta existente
              try {
                Navigator.pushReplacementNamed(context, '/admin-general');
              } catch (_) {
                Navigator.pushReplacementNamed(context, '/home');
              }
            }
        } else {
          // Navegar a InstitucionPage con el nombre de institución seleccionado
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => InstitucionPage(
                institutionName: widget.selectedInstitution.isNotEmpty ? widget.selectedInstitution : institutionNameFromUser,
                userName: nombre,
                role: role,
              ),
            ),
          );
        }
      } else {
        throw Exception('Usuario o contraseña incorrectos');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Error al iniciar sesión';

        if (e.toString().contains('Invalid login credentials') ||
            e.toString().contains('Usuario o contraseña incorrectos')) {
          errorMessage = 'Usuario o contraseña incorrectos';
        } else if (e.toString().contains('Network')) {
          errorMessage = 'Error de conexión. Verifica tu internet';
        } else if (e.toString().contains('timeout')) {
          errorMessage = 'Tiempo de espera agotado. Intenta de nuevo';
        } else {
          errorMessage = 'Error: ${e.toString().split(':').last.trim()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Volver'),
        backgroundColor: const Color(0xFFD92344),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'NEXUS',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD92344),
                ),
              ),
              if (widget.selectedInstitution.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  widget.selectedInstitution,
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
              const SizedBox(height: 24),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  hintText: 'Ingresa tu usuario o email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Ingresa tu contraseña',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD92344),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Ingresar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              
              const SizedBox(height: 16),
              
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _promptCompanyCodeAndProceed(),
                child: RichText(
                  text: TextSpan(
                    text: '¿No tienes una cuenta? ',
                    style: const TextStyle(
                      color: Colors.black, // Black for the first part
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(
                        text: 'Regístrate',
                        style: const TextStyle(
                          color: Color(0xFFD92344), // Red for 'Regístrate'
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
