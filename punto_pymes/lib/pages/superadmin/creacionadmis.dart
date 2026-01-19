import 'package:flutter/material.dart';
import '../../theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'widgets/superadmin_header.dart';
import '../../service/supabase_service.dart';

class CreacionAdmis extends StatefulWidget {
  const CreacionAdmis({super.key});

  @override
  State<CreacionAdmis> createState() => _CreacionAdmisState();
}

class _CreacionAdmisState extends State<CreacionAdmis> {
  final TextEditingController _nombresController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codigoAdminController = TextEditingController();
  // password is not stored here; admins receive invite to confirm and set password via email.
  String? _selectedCompanyId;

  List<Map<String, dynamic>> _empresas = [];
  bool _isLoadingEmpresas = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadEmpresas();
  }

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _emailController.dispose();
    _codigoAdminController.dispose();
    super.dispose();
  }

  Future<void> _loadEmpresas() async {
    try {
      final empresas = await SupabaseService.instance.getEmpresas();
      setState(() {
        _empresas = empresas;
        _isLoadingEmpresas = false;
      });
    } catch (e) {
      setState(() => _isLoadingEmpresas = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar empresas: $e')));
      }
    }
  }

  // helper removed: we don't generate passwords here for invited admins

  bool get _canCreate =>
      _nombresController.text.trim().isNotEmpty &&
      _apellidosController.text.trim().isNotEmpty &&
      _emailController.text.trim().isNotEmpty &&
      // password not required for pre-registration (invite flow)
      _codigoAdminController.text.trim().isNotEmpty &&
      _selectedCompanyId != null;

  Future<void> _createAdmin() async {
    if (!_canCreate) return;

    setState(() => _isCreating = true);

    try {
      // Pre-register admin request for the selected company. The admin will receive an email and confirm.
      final ok = await SupabaseService.instance.createAdminRequestForCompany(
        email: _emailController.text.trim(),
        empresaId: _selectedCompanyId!,
        accessCode: _codigoAdminController.text.trim(),
        nombres: _nombresController.text.trim(),
        apellidos: _apellidosController.text.trim(),
      );

      if (!ok) {
        throw Exception(
          'No se pudo crear la solicitud de admin. Verifica permisos o el código.',
        );
      }

      // Limpiar formulario
      _nombresController.clear();
      _apellidosController.clear();
      _emailController.clear();
      setState(() {
        _selectedCompanyId = null;
        _codigoAdminController.clear();
        _isCreating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Solicitud de administrador creada. El invitado deberá confirmar su correo.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _isCreating = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al crear admin: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SuperadminHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: 120.h, top: 8.h),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Gestión de Administradores',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            icon: Icon(
                              Icons.close,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Crea y administra los admins de cada empresa',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 12),

                      Card(
                        color: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceSoft,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.person_add,
                                      color: AppColors.accentBlue,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Nuevo Administrador',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Crea credenciales para un admin de empresa',
                                style: TextStyle(color: Colors.black54),
                              ),
                              const SizedBox(height: 12),

                              // Nombres
                              TextField(
                                controller: _nombresController,
                                enabled: !_isCreating,
                                decoration: InputDecoration(
                                  labelText: 'Nombres',
                                  prefixIcon: const Icon(Icons.person),
                                  filled: true,
                                  fillColor: AppColors.surfaceSoft,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 8),

                              // Apellidos
                              TextField(
                                controller: _apellidosController,
                                enabled: !_isCreating,
                                decoration: InputDecoration(
                                  labelText: 'Apellidos',
                                  prefixIcon: const Icon(Icons.person_outline),
                                  filled: true,
                                  fillColor: AppColors.surfaceSoft,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 8),

                              // Email
                              TextField(
                                controller: _emailController,
                                enabled: !_isCreating,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  filled: true,
                                  fillColor: AppColors.surfaceSoft,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 8),

                              // Empresa selector
                              DropdownButtonFormField<String>(
                                value: _selectedCompanyId,
                                onChanged: _isCreating
                                    ? null
                                    : (v) async {
                                        setState(() => _selectedCompanyId = v);
                                      },
                                items: _empresas
                                    .map(
                                      (empresa) => DropdownMenuItem<String>(
                                        value: empresa['id'],
                                        child: Text(
                                          empresa['nombre'] ?? 'Sin nombre',
                                        ),
                                      ),
                                    )
                                    .toList(),
                                decoration: InputDecoration(
                                  labelText: 'Empresa',
                                  prefixIcon: const Icon(
                                    Icons.apartment_outlined,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.surfaceSoft,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Código de admin (pre-registro)
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _codigoAdminController,
                                      enabled: !_isCreating,
                                      decoration: InputDecoration(
                                        labelText: 'Código de Admin',
                                        hintText: 'ADMIN-1234',
                                        prefixIcon: const Icon(
                                          Icons.vpn_key_outlined,
                                        ),
                                        filled: true,
                                        fillColor: AppColors.surfaceSoft,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: _isCreating
                                        ? null
                                        : () {
                                            final code =
                                                'ADM-${DateTime.now().millisecondsSinceEpoch % 100000}';
                                            _codigoAdminController.text = code;
                                            if (mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Código generado',
                                                  ),
                                                ),
                                              );
                                            }
                                            setState(() {});
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.accentBlue,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('Generar'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              SizedBox(
                                height: 44,
                                child: ElevatedButton.icon(
                                  onPressed: (_canCreate && !_isCreating)
                                      ? _createAdmin
                                      : null,
                                  icon: _isCreating
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : const Icon(Icons.save),
                                  label: Text(
                                    _isCreating
                                        ? 'Creando...'
                                        : 'Crear Administrador',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accentBlue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
