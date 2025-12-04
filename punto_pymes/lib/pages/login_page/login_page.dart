import 'package:flutter/material.dart';
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
  bool _isPasswordVisible = false; // Nuevo: Para ver/ocultar contraseña
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- LOGICA DE LOGIN (Mantenida intacta) ---
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

      debugPrint('signIn response: $response');

      if (response.session == null) {
        throw Exception('No se pudo iniciar sesión');
      }

      await SupabaseService.instance.refreshSession();

      final profile = await SupabaseService.instance.getMyProfile();
      
      if (profile == null) throw Exception('No se encontró el perfil del usuario');

      final rol = profile['rol'] as String?;

      if (!mounted) return;

      if (rol == 'SUPER_ADMIN') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const InicioSuperadmin()));
      } else if (rol == 'ADMIN_EMPRESA') {
        final empleadoDataAdmin = await SupabaseService.instance.getEmpleadoActual();
        final empleadoRawAdmin = empleadoDataAdmin?['empleado_raw'] as Map<String, dynamic>?;
        final cedulaAdmin = empleadoRawAdmin?['cedula'] as String?;
        if (cedulaAdmin == null || cedulaAdmin.isEmpty) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfileCompletionPage()));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bienvenido Admin Empresa')));
          // Aquí deberías navegar al dashboard de Admin si existe
        }
      } else if (rol == 'EMPLEADO') {
        final empleadoData = await SupabaseService.instance.getEmpleadoActual();
        final empleadoRaw = empleadoData?['empleado_raw'] as Map<String, dynamic>?;
        final cedula = empleadoRaw?['cedula'] as String?;
        if (cedula == null || cedula.isEmpty) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfileCompletionPage()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const EmpleadoPage()));
        }
      } else {
        throw Exception('Rol no reconocido');
      }
    } catch (e) {
      debugPrint('Login error: $e');

      if (!mounted) return;
      final msg = e.toString();
      setState(() {
        if (msg.contains('Database error querying schema')) {
          _errorMessage = 'Error de servidor. Intenta más tarde.';
        } else {
          _errorMessage = msg.replaceAll("Exception: ", "");
        }
        _isLoading = false;
      });
    }
  }

  // --- WIDGET HELPER PARA INPUTS ---
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
            color: Colors.grey.withOpacity(0.1),
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
                icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              ) 
            : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Datos de la empresa (si existen)
    final empresaNombre = widget.empresa != null ? widget.empresa!['nombre'] : 'NEXUS';
    final empresaFoto = widget.empresa != null ? widget.empresa!['empresa_foto_url'] as String? : null;
    
    // Color principal
    const primaryColor = Color(0xFFD92344);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () {
            // Verifica si puede hacer pop, si no redirige a selection
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
                // 1. LOGO O IMAGEN
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: empresaFoto != null
                        ? Image.network(
                            empresaFoto, 
                            fit: BoxFit.cover,
                            errorBuilder: (_,__,___) => const Icon(Icons.business, size: 50, color: primaryColor),
                          )
                        : Image.asset(
                            'assets/images/pymes.png', // Tu logo por defecto
                            fit: BoxFit.contain,
                            errorBuilder: (_,__,___) => const Icon(Icons.lock_person, size: 50, color: primaryColor),
                          ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // 2. TEXTOS DE BIENVENIDA
                Text(
                  'Bienvenido a $empresaNombre',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ingresa tus credenciales para continuar',
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
                        Icon(Icons.error_outline, color: Colors.red[900], size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red[900], fontSize: 13),
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

                // Olvidé mi contraseña (Visual, sin funcionalidad por ahora)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Acción para recuperar contraseña
                    },
                    child: const Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
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
                      shadowColor: primaryColor.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24, width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white, 
                              strokeWidth: 2.5
                            ),
                          )
                        : const Text(
                            'Ingresar',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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