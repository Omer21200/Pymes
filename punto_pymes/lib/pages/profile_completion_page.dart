import 'package:flutter/material.dart';
import '../service/supabase_service.dart';
import 'admin_empresa/admin_empresa_page.dart';
import 'empleado/empleado_page.dart';

class ProfileCompletionPage extends StatefulWidget {
  const ProfileCompletionPage({super.key});

  @override
  State<ProfileCompletionPage> createState() => _ProfileCompletionPageState();
}

class _ProfileCompletionPageState extends State<ProfileCompletionPage> {
  final _cedulaController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _cedulaController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { _isLoading = true; _error = null; });

    final cedula = _cedulaController.text.trim();
    final telefono = _telefonoController.text.trim();
    final direccion = _direccionController.text.trim();

    if (cedula.isEmpty) {
      setState(() { _error = 'La cédula es obligatoria'; _isLoading = false; });
      return;
    }

    try {
      await SupabaseService.instance.updateEmpleadoProfile(
        cedula: cedula,
        telefono: telefono.isEmpty ? null : telefono,
        direccion: direccion.isEmpty ? null : direccion,
      );

      // Es crucial verificar si el widget sigue "montado" después de una operación asíncrona.
      if (!mounted) return;
      
      // Obtenemos el perfil actualizado para saber a dónde redirigir
      final profile = await SupabaseService.instance.getMyProfile();
      final rol = profile?['rol'] as String?;
      
      // Volvemos a verificar antes de usar el BuildContext para la navegación.
      if (!mounted) return;

      switch (rol) {
        case 'ADMIN_EMPRESA':
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminEmpresaPage()));
          break;
        case 'EMPLEADO':
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const EmpleadoPage()));
          break;
        default:
          // Fallback por si acaso, aunque no debería ocurrir
          await SupabaseService.instance.signOut();
          if (!mounted) return; // Verificamos una última vez.
          Navigator.pushReplacementNamed(context, '/access-selection');
      }

    } catch (e) {
      if (mounted) {
        setState(() { _error = e.toString().replaceAll('Exception: ', ''); });
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Completar Perfil')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text('Completa tu perfil para continuar', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              TextField(controller: _cedulaController, decoration: const InputDecoration(labelText: 'Cédula / Documento')),
              const SizedBox(height: 8),
              TextField(controller: _telefonoController, decoration: const InputDecoration(labelText: 'Teléfono')),
              const SizedBox(height: 8),
              TextField(controller: _direccionController, decoration: const InputDecoration(labelText: 'Dirección')),
              const SizedBox(height: 16),
              if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) : const Text('Guardar y continuar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
