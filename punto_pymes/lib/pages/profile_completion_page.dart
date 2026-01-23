// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../service/supabase_service.dart';
import '../theme.dart';
import '../widgets/department_selector_card.dart';
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
  // Departamentos
  List<Map<String, dynamic>> _departamentos = [];
  String? _selectedDepartamentoId;
  bool _isLoadingDepartamentos = false;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _cedulaController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadDepartamentos();
  }

  Future<void> _loadDepartamentos() async {
    setState(() {
      _isLoadingDepartamentos = true;
    });
    try {
      final empleado = await SupabaseService.instance.getEmpleadoActual();
      final empresaId = empleado?['empresa_id']?.toString();
      if (empresaId == null) {
        setState(() {
          _error = 'No se encontró empresa asociada al usuario.';
          _departamentos = [];
        });
        return;
      }

      final deps = await SupabaseService.instance.getDepartamentosPorEmpresa(
        empresaId,
      );
      setState(() {
        _departamentos = deps;
      });
    } catch (e) {
      setState(() {
        _error = 'Error cargando departamentos: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDepartamentos = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final cedula = _cedulaController.text.trim();
    final telefono = _telefonoController.text.trim();
    final direccion = _direccionController.text.trim();

    if (cedula.isEmpty) {
      setState(() {
        _error = 'La cédula es obligatoria';
        _isLoading = false;
      });
      return;
    }

    if (_selectedDepartamentoId == null) {
      setState(() {
        _error = 'Selecciona el departamento al que perteneces';
        _isLoading = false;
      });
      return;
    }

    try {
      await SupabaseService.instance.updateEmpleadoProfile(
        cedula: cedula,
        telefono: telefono.isEmpty ? null : telefono,
        direccion: direccion.isEmpty ? null : direccion,
        departamentoId: _selectedDepartamentoId,
      );

      // Verificamos que quedó guardado el empleado con la cédula
      final empleadoData = await SupabaseService.instance.getEmpleadoActual();
      final cedulaGuardada =
          (empleadoData?['empleado_raw'] as Map<String, dynamic>?)?['cedula']
              as String?;
      if (cedulaGuardada == null || cedulaGuardada.isEmpty) {
        setState(() {
          _error =
              'No se pudo guardar tus datos. Intenta de nuevo o revisa conexión.';
          _isLoading = false;
        });
        return;
      }

      // Es crucial verificar si el widget sigue "montado" después de una operación asíncrona.
      if (!mounted) return;

      // Obtenemos el perfil actualizado para saber a dónde redirigir
      final profile = await SupabaseService.instance.getMyProfile();
      final rol = profile?['rol'] as String?;

      // Volvemos a verificar antes de usar el BuildContext para la navegación.
      if (!mounted) return;

      switch (rol) {
        case 'ADMIN_EMPRESA':
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AdminEmpresaPage()),
            (route) => false,
          );
          break;
        case 'EMPLEADO':
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const EmpleadoPage()),
            (route) => false,
          );
          break;
        default:
          // Fallback por si acaso, aunque no debería ocurrir
          await SupabaseService.instance.signOut();
          if (!mounted) return; // Verificamos una última vez.
          Navigator.pushReplacementNamed(context, '/access-selection');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
        });
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
      appBar: AppBar(title: const Text('Completar Perfil')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                'Completa tu perfil para continuar',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),

              // Card wrapper for fields + departamento selector + submit
              Container(
                decoration: BoxDecoration(
                  // card should be white
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _cedulaController,
                      decoration: InputDecoration(
                        labelText: 'Cédula / Documento',
                        labelStyle: const TextStyle(color: Colors.black54),
                        filled: true,
                        fillColor: AppColors.surfaceSoft,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _telefonoController,
                      decoration: InputDecoration(
                        labelText: 'Teléfono',
                        labelStyle: const TextStyle(color: Colors.black54),
                        filled: true,
                        fillColor: AppColors.surfaceSoft,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _direccionController,
                      decoration: InputDecoration(
                        labelText: 'Dirección',
                        labelStyle: const TextStyle(color: Colors.black54),
                        filled: true,
                        fillColor: AppColors.surfaceSoft,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Departamento selector
                    if (_isLoadingDepartamentos)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: CircularProgressIndicator(),
                      )
                    else
                      DepartmentSelectorCard(
                        departamentos: _departamentos,
                        departamentoId: _selectedDepartamentoId,
                        onChanged: (v) =>
                            setState(() => _selectedDepartamentoId = v),
                        enabled: true,
                        label: 'Departamento',
                      ),
                    const SizedBox(height: 18),
                    if (_error != null)
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandRed,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('Guardar y continuar'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
