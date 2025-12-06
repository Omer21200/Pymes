import 'package:flutter/material.dart';
import '../service/supabase_service.dart';

class RegisterPageEmpleado extends StatefulWidget {
  final Map<String, dynamic>? empresa;
  const RegisterPageEmpleado({super.key, this.empresa});

  @override
  State<RegisterPageEmpleado> createState() => _RegisterPageEmpleadoState();
}

class _RegisterPageEmpleadoState extends State<RegisterPageEmpleado> {
  // Controladores
  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();
  
  // Estado
  bool _isLoading = false;
  bool _isPasswordVisible = false; // Control para ver contraseña
  String? _error;

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE REGISTRO (Misma lógica original) ---
  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final nombres = _nombresController.text.trim();
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
      // 1. RPC de Verificación
      final rpcOk = await SupabaseService.instance.registerEmployeeRequest(
        email: email, 
        code: code, 
        nombres: nombres, 
        apellidos: apellidos
      );

      if (!rpcOk) {
        throw Exception('Código de Empresa inválido o error en solicitud.');
      }
      
      // 2. Auth SignUp
      final res = await SupabaseService.instance.signUpEmail(email: email, password: password);
      
      // 3. Feedback
      if (res.session == null && res.user == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registro iniciado. Revisa tu correo.')));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registro completado exitosamente')));
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
            color: Colors.grey.withValues(alpha: 0.1),
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
    final empresaNombre = widget.empresa != null ? widget.empresa!['nombre'] ?? 'Empresa' : null;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
              
              // 1. TÍTULO
              const Text(
                'Registro de Empleado',
                style: TextStyle(
                  fontSize: 28, // Un poco más pequeño que Admin por ser subtítulo largo
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              
              // 2. CONTEXTO DE EMPRESA (Si existe)
              if (empresaNombre != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.business, size: 18, color: Colors.blue[800]),
                      const SizedBox(width: 8),
                      Text(
                        'Registrando en: $empresaNombre',
                        style: TextStyle(
                          color: Colors.blue[900],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else 
                Text(
                  'Crea tu cuenta para acceder al sistema.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),

              const SizedBox(height: 24),

              // 3. FORMULARIO DATOS PERSONALES
              _buildCustomTextField(
                controller: _nombresController,
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

              const SizedBox(height: 12),

              // 4. CAMPO ESPECIAL: CÓDIGO DE EMPRESA
              Container(
                decoration: BoxDecoration(
                  color: Colors.indigo[50], // Tono diferente para diferenciar
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.indigo.shade100),
                ),
                child: TextField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Código de Empresa',
                    prefixIcon: Icon(Icons.qr_code, color: Colors.indigo),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 5. MANEJO DE ERRORES
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
                      // Corrección aplicada: quitamos 'const' y usamos red[900]
                      Expanded(
                        child: Text(
                          _error!, 
                          style: TextStyle(color: Colors.red[900])
                        )
                      ),
                    ],
                  ),
                ),

              // 6. BOTÓN DE ACCIÓN
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
                          'Crear Cuenta',
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