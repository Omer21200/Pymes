import 'package:flutter/material.dart';
import 'widgets/superadmin_header.dart';
import '../../service/supabase_service.dart';
import 'creacionadmis.dart';

class AdminsList extends StatefulWidget {
  const AdminsList({super.key});

  @override
  State<AdminsList> createState() => _AdminsListState();
}

class _AdminsListState extends State<AdminsList> {
  List<Map<String, dynamic>> _admins = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  Future<void> _loadAdmins() async {
    setState(() => _isLoading = true);
    try {
      final admins = await SupabaseService.instance.client
          .from('profiles')
          .select('id,nombres,apellidos,rol,empresa_id, empresas(nombre)')
          .eq('rol', 'ADMIN_EMPRESA')
          .order('created_at', ascending: false);

      setState(() {
        _admins = List<Map<String, dynamic>>.from(admins);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar admins: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SuperadminHeader(),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Administradores',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Lista completa de administradores registrados',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 12),

                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final created = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CreacionAdmis(),
                          ),
                        );
                        if (created == true) await _loadAdmins();
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text('Crear Administrador'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD92344),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_admins.isEmpty)
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No hay administradores registrados',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ..._admins.map((admin) {
                      final empresaNombre = admin['empresas'] != null
                          ? admin['empresas']['nombre']
                          : 'Sin empresa';
                      final fullName =
                          '${admin['nombres'] ?? ''} ${admin['apellidos'] ?? ''}'
                              .trim();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFFFECEF),
                            child: const Icon(
                              Icons.person,
                              color: Color(0xFFD92344),
                            ),
                          ),
                          title: Text(
                            fullName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Empresa: $empresaNombre'),
                              Text('Rol: ${admin['rol']}'),
                            ],
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
