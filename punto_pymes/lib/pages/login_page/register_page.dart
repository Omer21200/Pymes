import 'package:flutter/material.dart';
import '../../service/supabase_service.dart';
// Asumo que esta es la ruta a tu página de empleado/dashboard
import '../empleado/empleado_page.dart'; 

class RegisterPage extends StatefulWidget {
  final Map<String, dynamic>? empresa;
  const RegisterPage({super.key, this.empresa});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Controladores
  final _nameController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();
  
  // Estado
  final bool _isAdmin = true; 
  bool _isLoading = false;
  bool _isPasswordVisible = false; // Nuevo: Para controlar el "ojo" de la contraseña
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _apellidosController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE REGISTRO (Misma lógica, sin cambios funcionales) ---
  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final nombres = _nameController.text.trim();
    final apellidos = _apellidosController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();
    final code = _codeController.text.trim();

    if (nombres.isEmpty || apellidos.isEmpty || email.isEmpty || password.isEmpty || code.isEmpty) {
      setState(() {
        _error = 'Por favor, completa todos los campos.';
        _isLoading = false;
      });
      return;
    }

    try {
      final rpcOk = await SupabaseService.instance.registerAdminRequest(email: email, accessCode: code);

      if (!rpcOk) {
        throw Exception('Código de Administrador inválido o no existe pre‑registro.');
      }
      
      final res = await SupabaseService.instance.signUpEmail(email: email, password: password);
      
      if (res.session == null && res.user == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registro iniciado. Revisa tu correo.')));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registro completado con éxito')));
      }

      if (mounted) Navigator.of(context).pop(true);

    } catch (e) {
      setState(() {
        _error = e.toString().contains('Exception:') ? e.toString().split('Exception: ')[1] : e.toString();
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- WIDGETS DE DISEÑO ---

  // Método helper para crear Inputs consistentes y bonitos
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
            borderSide: BorderSide.none, // Quitamos el borde por defecto para usar el del Container
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
    // Usamos el color primario del tema o uno por defecto
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Fondo gris muy claro, moderno
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              // 1. TÍTULO Y SUBTÍTULO
              const Text(
                'Crear Cuenta',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ingresa tus datos y código de administrador para registrarte en el sistema.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.5),
              ),
              
              const SizedBox(height: 32),

              // 2. FORMULARIO CON ICONOS
              _buildCustomTextField(
                controller: _nameController,
                label: 'Nombres',
                icon: Icons.person_outline,
              ),
              _buildCustomTextField(
                controller: _apellidosController,
                label: 'Apellidos',
                icon: Icons.person_outline,
              ),
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
              
              // Input especial para el código
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue[50], // Un color diferente para resaltar que es importante
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: TextField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Código de Admin',
                    prefixIcon: Icon(Icons.vpn_key, color: Colors.blue),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 3. MANEJO DE ERRORES VISUAL
              if (_error != null) 
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade100)
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 10),
                      Expanded(
  child: Text(
    _error!, 
    style: TextStyle(color: Colors.red[900]), // Usamos red[900] y quitamos 'const'
  ),
),
                    ],
                  ),
                ),

              // 4. BOTÓN DE ACCIÓN
              SizedBox(
                width: double.infinity,
                height: 55, // Más alto para fácil toque
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor, // Usa tu color definido en theme.dart
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading 
                      ? const SizedBox(
                          height: 24, width: 24, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                        ) 
                      : const Text(
                          'Registrar Administrador',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}