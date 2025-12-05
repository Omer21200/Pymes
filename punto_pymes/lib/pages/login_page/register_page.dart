import 'package:flutter/material.dart';
import '../../service/supabase_service.dart';

class RegisterPage extends StatefulWidget {
  final Map<String, dynamic>? empresa;
  const RegisterPage({super.key, this.empresa});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Controladores
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();
  
  // Estado
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE REGISTRO MEJORADA ---
  Future<void> _register() async {
    // Verificación de mounted al inicio del método asíncrono.
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();
    final code = _codeController.text.trim();

    if (email.isEmpty || password.isEmpty || code.isEmpty) {
      setState(() {
        _error = 'Por favor, completa todos los campos.';
        _isLoading = false;
      });
      return;
    }

    try {
      // 1. Validar el código de pre-registro
      final rpcOk = await SupabaseService.instance.registerAdminRequest(email: email, accessCode: code);
      if (!rpcOk) {
        throw Exception('Código de Administrador inválido o correo no pre‑registrado.');
      }
      
      // Si el widget sigue montado, procedemos con el registro
      if (!mounted) return;

      // 2. Registrar el usuario en Auth
      await SupabaseService.instance.signUpEmail(email: email, password: password);
      
      // Si el widget sigue montado, mostramos el resultado
      if (!mounted) return;

      // El trigger en Supabase se encargará de crear el perfil.
      // Mostramos un mensaje genérico de confirmación.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro iniciado. Revisa tu correo para confirmar la cuenta.'))
      );

      // Regresamos a la página anterior (login)
      Navigator.of(context).pop(true);

    } catch (e) {
      // Si el widget está montado, actualizamos el estado del error
      if (!mounted) return;
      setState(() {
        _error = e.toString().contains('Exception:') ? e.toString().split('Exception: ')[1] : e.toString();
      });
    } finally {
      // Si el widget está montado, nos aseguramos de detener el indicador de carga
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- WIDGETS DE DISEÑO ---

  // Método helper para crear Inputs consistentes
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
            color: Colors.grey.withAlpha(26), // Reemplazo de withOpacity
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
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
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
                'Crear Cuenta de Admin', // Título más específico
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ingresa tu correo, contraseña y el código de acceso que te proporcionaron.', // Texto simplificado
                style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.5),
              ),
              
              const SizedBox(height: 32),

              // 2. FORMULARIO CON ICONOS
              // Los campos de nombre y apellido se eliminaron porque son pre-registrados por el Super Admin
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
                  color: Colors.blue[50],
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
                          style: TextStyle(color: Colors.red[900]),
                        ),
                      ),
                    ],
                  ),
                ),

              // 4. BOTÓN DE ACCIÓN
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
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
