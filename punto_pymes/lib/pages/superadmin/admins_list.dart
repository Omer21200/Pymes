import 'package:flutter/material.dart';
import 'widgets/superadmin_header.dart';
import '../../service/supabase_service.dart';
import 'creacionadmis.dart';
import 'admin_detalle.dart';

class AdminsList extends StatefulWidget {
  const AdminsList({super.key});

  @override
  State<AdminsList> createState() => _AdminsListState();
}

class _AdminsListState extends State<AdminsList> {
  List<Map<String, dynamic>> _admins = [];
  bool _isLoading = true;
  // Filters
  final TextEditingController _filterNameController = TextEditingController();
  DateTime? _filterFrom;
  DateTime? _filterTo;
  List<Map<String, dynamic>> _filteredAdmins = [];

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  @override
  void dispose() {
    _filterNameController.dispose();
    super.dispose();
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
      _applyFilters();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar admins: $e')));
      }
    }
  }

  Future<void> _confirmDeleteAdmin(String adminId, String? nombre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de eliminar al administrador "${nombre ?? 'Sin nombre'}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await SupabaseService.instance.client
            .from('profiles')
            .delete()
            .eq('id', adminId);
        await _loadAdmins();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Administrador eliminado'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _applyFilters() {
    final nameQ = _filterNameController.text.trim().toLowerCase();
    DateTime? from = _filterFrom;
    DateTime? to = _filterTo;

    List<Map<String, dynamic>> list = List.from(_admins);

    if (nameQ.isNotEmpty) {
      list = list.where((e) {
        final n = ('${e['nombres'] ?? ''} ${e['apellidos'] ?? ''}')
            .toString()
            .toLowerCase();
        return n.contains(nameQ);
      }).toList();
    }

    if (from != null || to != null) {
      list = list.where((e) {
        final created = e['created_at'];
        DateTime? dt;
        if (created is String) {
          dt = DateTime.tryParse(created);
        } else if (created is DateTime) {
          dt = created;
        }
        if (dt == null) return false;
        if (from != null && dt.isBefore(from)) return false;
        if (to != null) {
          final end = DateTime(to.year, to.month, to.day, 23, 59, 59);
          if (dt.isAfter(end)) return false;
        }
        return true;
      }).toList();
    }

    setState(() {
      _filteredAdmins = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Administradores',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 0, 0, 0),
                              ),
                            ),
                            SizedBox(height: 1),
                            Text(
                              'Lista completa de administradores registrados',
                              style: TextStyle(color: Colors.black54),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
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
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 6,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Filters: name search + date
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                // ignore: deprecated_member_use
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _filterNameController,
                            decoration: InputDecoration(
                              hintText: 'Buscar por nombre',
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Colors.grey,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (_) => _applyFilters(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _filterFrom = null;
                            _filterTo = null;
                            _filterNameController.clear();
                            _applyFilters();
                          });
                        },
                        child: const Text('Limpiar'),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _filterFrom ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now().add(
                              const Duration(days: 3650),
                            ),
                          );
                          if (picked != null) {
                            setState(() => _filterFrom = picked);
                            _applyFilters();
                          }
                        },
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Center(
                            child: Icon(
                              Icons.calendar_today,
                              color: const Color(0xFFD92344),
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

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
                                style: TextStyle(
                                  color: const Color.fromARGB(
                                    255,
                                    255,
                                    255,
                                    255,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ..._filteredAdmins.map((admin) {
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
                        color: Colors.white,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
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
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AdminDetallePage(admin: admin),
                              ),
                            );
                          },
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () => _confirmDeleteAdmin(
                                  admin['id'] as String,
                                  fullName,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        // ignore: deprecated_member_use
                                        color: Colors.black.withOpacity(0.06),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline,
                                    color: Color(0xFFD92344),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AdminDetallePage(admin: admin),
                                    ),
                                  );
                                },
                                child: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
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
