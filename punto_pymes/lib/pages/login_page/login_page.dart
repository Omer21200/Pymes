import 'package:flutter/material.dart';
import '../admin_empresa/admin_empresa_page.dart';
import '../superadmin/iniciosuperadmin.dart';
import '../empleado/empleado_page.dart';
import '../../service/supabase_service.dart';
import '../profile_completion_page.dart';

class LoginPage extends StatefulWidget {
  final Map<String, dynamic>? empresa;
  const LoginPage({super.key, this.empresa});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Lógica de inicio de sesión mejorada con validación de rol y empresa.
  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor ingresa correo y contraseña';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await SupabaseService.instance.signInEmail(
        email: email,
        password: password,
      );

      if (response.session == null) {
        throw Exception(
          'No se pudo iniciar sesión. Verifica tus credenciales.',
        );
      }

      // Obtenemos el perfil para verificar el rol
      await SupabaseService.instance.refreshSession();
      final profile = await SupabaseService.instance.getMyProfile();

      if (profile == null) {
        throw Exception('No se encontró el perfil del usuario.');
      }

      final rol = profile['rol'] as String?;
      final userEmpresaId = profile['empresa_id'] as String?;

      // --- VALIDACIÓN DE ACCESO ---
      final bool isSuperAdminLogin = widget.empresa == null;

      if (isSuperAdminLogin) {
        if (rol != 'SUPER_ADMIN') {
          await SupabaseService.instance.signOut();
          throw Exception('Esta cuenta no es de Super Administrador.');
        }
      } else {
        // Es un login de empresa
        if (rol == 'SUPER_ADMIN') {
          await SupabaseService.instance.signOut();
          throw Exception(
            'El Super Admin solo puede ingresar por la pantalla principal.',
          );
        }
        if (userEmpresaId != widget.empresa!['id']) {
          await SupabaseService.instance.signOut();
          throw Exception(
            'Esta cuenta no pertenece a la empresa seleccionada.',
          );
        }
      }
      // --- FIN DE VALIDACIÓN ---

      if (!mounted) return;

      // Redirección según el rol verificado
      switch (rol) {
        case 'SUPER_ADMIN':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const InicioSuperadmin()),
          );
          break;
        case 'ADMIN_EMPRESA':
        case 'EMPLEADO':
          final empleadoData = await SupabaseService.instance
              .getEmpleadoActual();
          if (!mounted) return;

          final cedula =
              (empleadoData?['empleado_raw']
                      as Map<String, dynamic>?)?['cedula']
                  as String?;

          if (cedula == null || cedula.isEmpty) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ProfileCompletionPage()),
            );
          } else {
            if (rol == 'ADMIN_EMPRESA') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AdminEmpresaPage()),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const EmpleadoPage()),
              );
            }
          }
          break;
        default:
          throw Exception('Rol no reconocido');
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      setState(() {
        if (msg.contains('invalid_grant')) {
          _errorMessage = 'Credenciales incorrectas.';
        } else if (msg.contains('Database error querying schema')) {
          _errorMessage = 'Error de servidor. Intenta más tarde.';
        } else {
          _errorMessage = msg.replaceAll("Exception: ", "");
        }
        _isLoading = false;
      });
    }
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26), // Corrección de withOpacity
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? !_isPasswordVisible : false,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isSuperAdminLogin = widget.empresa == null;
    const primaryColor = Color(0xFFD92344);

    // --- Definimos el contenido basado en el contexto ---
    final String title;
    final String subtitle;
    final Widget logoWidget;

    if (isSuperAdminLogin) {
      title = 'Acceso Super Admin';
      subtitle = 'Ingresa tus credenciales maestras';
      logoWidget = Image.asset(
        'assets/images/logo.png', // Logo principal de la app
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.shield_outlined, size: 50, color: primaryColor),
      );
    } else {
      final empresaNombre = widget.empresa!['nombre'];
      final empresaFoto = widget.empresa!['empresa_foto_url'] as String?;
      title = 'Bienvenido a $empresaNombre';
      subtitle = 'Ingresa tus credenciales para continuar';

      if (empresaFoto != null && empresaFoto.isNotEmpty) {
        logoWidget = Image.network(
          empresaFoto,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.business, size: 50, color: primaryColor),
        );
      } else {
        logoWidget = const Icon(Icons.business, size: 50, color: primaryColor);
      }
    }
    // --- Fin de la definición de contenido ---

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/access-selection');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. LOGO (Dinámico)
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(26),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.zero,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: logoWidget,
                  ),
                ),

                const SizedBox(height: 24),

                // 2. TEXTOS DE BIENVENIDA (Dinámicos)
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),

                const SizedBox(height: 32),

                // 3. MENSAJE DE ERROR
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red[900],
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red[900],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 4. CAMPOS DE TEXTO
                _buildCustomTextField(
                  controller: _emailController,
                  label: 'Correo Electrónico',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),

                _buildCustomTextField(
                  controller: _passwordController,
                  label: 'Contraseña',
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),

                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 5. BOTÓN DE LOGIN
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: primaryColor.withAlpha(
                        102,
                      ), // Corrección de withOpacity
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Ingresar',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}