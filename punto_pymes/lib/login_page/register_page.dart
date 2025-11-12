import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../main.dart';

class RegisterPage extends StatefulWidget {
  final String selectedInstitution;

  const RegisterPage({
    this.selectedInstitution = '',
    super.key,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final nombre = _nombreController.text.trim();
    final apellido = _apellidoController.text.trim();
    final email = _emailController.text.trim();
  // Nota: el campo teléfono está en el formulario pero actualmente no se inserta en la tabla 'usuarios'
    final password = _passwordController.text;

    setState(() => _isSubmitting = true);

    try {
      // Buscar empresa por nombre para obtener empresa_id (uuid)
      String? empresaId;
      if (widget.selectedInstitution.isNotEmpty) {
        final empresa = await supabase.from('empresas').select('id').eq('nombre', widget.selectedInstitution).maybeSingle();
        if (empresa != null && empresa['id'] != null) {
          empresaId = empresa['id'].toString();
        }
      }

      // Preparar datos a insertar
      // 1) Intentar crear cuenta en Supabase Auth (más seguro)
      Map<String, dynamic>? authUser;
      try {
        final signUpResp = await supabase.auth.signUp(email: email, password: password);
        debugPrint('signUpResp: $signUpResp');
        // Dependiendo de la versión del cliente, user puede venir en signUpResp.user
        if (signUpResp.user != null) {
          authUser = {
            'id': signUpResp.user!.id,
          };
        }
      } catch (e) {
        // Si falla signUp (por ejemplo ya existe), seguimos intentando insertar metadata
        debugPrint('Supabase signUp error: $e');
      }

  // 2) Insertar metadata en tabla 'usuarios'
      // Ajustar campos para que coincidan con el schema real (ver base.sql):
      // columnas: id, empresa_id, nombre_completo, email, contraseña_hash, rol, telefono, avatar_url, estado
      // Hashear la contraseña con SHA256 y guardarla en la columna contraseña_hash
      final hashed = sha256.convert(utf8.encode(password)).toString();

      final userInsert = {
        if (authUser != null && authUser['id'] != null) 'id': authUser['id'],
        if (empresaId != null) 'empresa_id': empresaId,
        'nombre_completo': '$nombre ${apellido.isNotEmpty ? apellido : ''}'.trim(),
        'email': email,
        // Guardar hash de la contraseña para compatibilidad con login por tabla si es necesario
        'contraseña_hash': hashed,
        'rol': 'empleado',
        if (_telefonoController.text.trim().isNotEmpty) 'telefono': _telefonoController.text.trim(),
        'estado': true,
      };

      try {
        final inserted = await supabase.from('usuarios').insert([userInsert]).select().maybeSingle();
        debugPrint('inserted: $inserted');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cuenta creada correctamente')));
      } catch (e) {
        debugPrint('Error inserting usuario: $e');
        // Re-throw para que caiga al catch externo y muestre mensaje al usuario
        throw e;
      }

      // Volver al login
      if (mounted) Navigator.pop(context);
    } catch (e) {
      String message = 'Error al crear la cuenta';
      if (e.toString().contains('duplicate') || e.toString().contains('unique')) {
        message = 'Ya existe una cuenta con ese correo';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                const Text('NEXUS', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFD92344))),
                const SizedBox(height: 8),
                Text(widget.selectedInstitution.isNotEmpty ? widget.selectedInstitution : 'Selecciona institución', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _nombreController,
                        decoration: InputDecoration(hintText: 'Tu nombre', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _apellidoController,
                        decoration: InputDecoration(hintText: 'Tu apellido', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(hintText: 'correo@ejemplo.com', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Obligatorio';
                    if (!RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$").hasMatch(v.trim())) return 'Email inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _telefonoController,
                  decoration: InputDecoration(hintText: '+593 999 999 999', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(hintText: 'Crea una contraseña', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmController,
                  obscureText: true,
                  decoration: InputDecoration(hintText: 'Confirma tu contraseña', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  validator: (v) => (v != _passwordController.text) ? 'No coincide' : null,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD92344),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white70,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Crear Cuenta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
