import 'package:flutter/material.dart';
import '../main.dart';
import '../institucion_page/institucion_page.dart';
import '../superadmin/superadmin_page.dart';
import 'register_page.dart';

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

          if (storedPassword == password) {
            loginSuccess = true;
            userData = usuario;
            debugPrint('✅ Login por tabla usuarios (fallback plano) OK');
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
          // intenta ruta administrativa si existe, sino navegar a home
          try {
            Navigator.pushReplacementNamed(context, '/admin-general');
          } catch (_) {
            Navigator.pushReplacementNamed(context, '/home');
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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RegisterPage(selectedInstitution: widget.selectedInstitution)),
                  );
                },
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
