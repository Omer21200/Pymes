import 'package:flutter/material.dart';
import '../service/profile_service.dart';
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
      final ok = await ProfileService.instance.saveProfile(
        cedula: cedula,
        telefono: telefono.isEmpty ? null : telefono,
        direccion: direccion.isEmpty ? null : direccion,
      );

      if (!ok) throw Exception('No se pudo actualizar el perfil');

      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const EmpleadoPage()));
    } catch (e) {
      setState(() { _error = e.toString(); });
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
