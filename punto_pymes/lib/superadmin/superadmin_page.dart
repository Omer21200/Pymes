import 'package:flutter/material.dart';
import '../widgets/profile_card.dart';
import '../widgets/superadmin_nav_pill.dart';
import 'empresas_page.dart';
import 'admins_page.dart';
import '../main.dart';

class SuperAdminPage extends StatefulWidget {
  final String userName;

  const SuperAdminPage({this.userName = 'Super Admin', super.key});

  @override
  State<SuperAdminPage> createState() => _SuperAdminPageState();
}

class _SuperAdminPageState extends State<SuperAdminPage> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> _metrics = [];

  List<Map<String, dynamic>> _companies = [];

  List<Map<String, String>> _activities = [];

  @override
  void initState() {
    super.initState();
    _loadResumenData();
    _loadCompanies();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadCompanies() async {
    try {
      final res = await supabase.from('empresas').select().order('nombre');
      final List resList = res as List;
      setState(() {
        _companies = resList
            .map<Map<String, dynamic>>(
              (e) => {
                'id': e['id'],
                'name': e['nombre'] ?? e['name'] ?? '',
                'ruc': e['ruc'] ?? '',
                'direccion': e['direccion'] ?? '',
                'telefono': e['telefono'] ?? '',
                'email': e['email'] ?? '',
                // placeholders for counts (will be set by _loadResumenData)
                'employees': 0,
                'admins': 0,
                'hora_entrada': e['hora_entrada'] ?? '',
                'tolerancia_minutos': e['tolerancia_minutos'] ?? 0,
              },
            )
            .toList();
      });
    } catch (e) {
      debugPrint('Error cargando empresas: $e');
    }
  }

  Future<void> _loadResumenData() async {
    try {
      // 1) counts: empresas, admins, empleados
      final empresasRes =
          await supabase.from('empresas').select() as List<dynamic>? ?? [];
      final usuariosRes =
          await supabase.from('usuarios').select('id,empresa_id,rol')
              as List<dynamic>? ??
          [];

      final int empresasCount = empresasRes.length;
      int adminsCount = 0;
      int empleadosCount = 0;

      final Map<String, Map<String, int>> perCompany = {};
      for (final u in usuariosRes) {
        final rol = (u['rol'] ?? '').toString();
        final empresaId = (u['empresa_id'] ?? '').toString();
        if (rol == 'admin') adminsCount++;
        if (rol == 'empleado') empleadosCount++;
        if (empresaId.isNotEmpty) {
          perCompany.putIfAbsent(empresaId, () => {'admin': 0, 'empleado': 0});
          if (rol == 'admin')
            perCompany[empresaId]!['admin'] =
                perCompany[empresaId]!['admin']! + 1;
          if (rol == 'empleado')
            perCompany[empresaId]!['empleado'] =
                perCompany[empresaId]!['empleado']! + 1;
        }
      }

      // 2) recent activities from notificaciones (fallback to empty)
      final acts =
          await supabase
                  .from('notificaciones')
                  .select()
                  .order('creado_en', ascending: false)
                  .limit(6)
              as List<dynamic>? ??
          [];
      final List<Map<String, String>> activities = [];
      for (final a in acts) {
        final title = (a['titulo'] ?? '').toString();
        final created = a['creado_en']?.toString() ?? '';
        activities.add({
          'title': title.isNotEmpty
              ? title
              : (a['contenido']?.toString() ?? ''),
          'subtitle': created,
        });
      }

      setState(() {
        _metrics = [
          {'title': 'Empresas', 'value': empresasCount.toString()},
          {'title': 'Admins', 'value': adminsCount.toString()},
          {'title': 'Empleados', 'value': empleadosCount.toString()},
        ];

        _activities = activities;

        // merge perCompany counts into _companies if already loaded
        if (_companies.isNotEmpty) {
          _companies = _companies.map((c) {
            final id = (c['id'] ?? '').toString();
            final data = perCompany[id];
            return {
              ...c,
              'employees': data != null
                  ? (data['empleado'] ?? 0)
                  : (c['employees'] ?? 0),
              'admins': data != null
                  ? (data['admin'] ?? 0)
                  : (c['admins'] ?? 0),
              'progress': (data != null && ((data['empleado'] ?? 0) > 0))
                  ? ((data['admin'] ?? 0) / ((data['empleado'] ?? 1)))
                  : 0.0,
            };
          }).toList();
        }
      });
    } catch (e) {
      debugPrint('Error cargando resumen: $e');
    }
  }

  Widget _buildResumen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 120, left: 16, right: 16, top: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          ProfileCard(
            userName: widget.userName,
            institutionName: 'NEXUS',
            role: 'Super Administrador',
            onAction: () async {
              await supabase.auth.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/access-selection',
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Resumen del Sistema',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          // Small metric cards grid
          Row(
            children: _metrics.map((m) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m['title'].toString(),
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        m['value'].toString(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text(
            'Estado de Empresas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Column(
            children: _companies.map((c) {
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.apartment, color: Colors.red),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c['name'].toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${c['employees']} empleados • ${c['admins']} admins',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Builder(
                                      builder: (context) {
                                        // Defensive parsing: progress may be null, int, double or string
                                        final raw = c['progress'];
                                        double progress;
                                        if (raw == null) {
                                          progress = 0.0;
                                        } else if (raw is double) {
                                          progress = raw;
                                        } else if (raw is int) {
                                          progress = raw.toDouble();
                                        } else {
                                          progress =
                                              double.tryParse(raw.toString()) ??
                                              0.0;
                                        }

                                        return LinearProgressIndicator(
                                          value: progress.clamp(0.0, 1.0),
                                          minHeight: 8,
                                          valueColor:
                                              const AlwaysStoppedAnimation<
                                                Color
                                              >(Colors.red),
                                          backgroundColor: Colors.grey.shade200,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Builder(
                                  builder: (context) {
                                    final raw = c['progress'];
                                    double progress;
                                    if (raw == null) {
                                      progress = 0.0;
                                    } else if (raw is double) {
                                      progress = raw;
                                    } else if (raw is int) {
                                      progress = raw.toDouble();
                                    } else {
                                      progress =
                                          double.tryParse(raw.toString()) ??
                                          0.0;
                                    }
                                    return Text(
                                      '${((progress.clamp(0.0, 1.0) * 100).round())}%',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade400),
                        ),
                        child: const Text(
                          'Activa',
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text(
            'Actividad Reciente',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ..._activities.map(
            (a) => Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a['title']!,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      a['subtitle']!,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpresas() {
    return EmpresasPage(
      userName: widget.userName,
      onCompanyChanged: () async {
        // cuando una empresa cambia en EmpresasPage, recargamos resumen y empresas del SuperAdmin
        await _loadResumenData();
        await _loadCompanies();
      },
    );
  }

  Widget _buildAdmins() {
    return AdminsPage(userName: widget.userName);
  }

  Widget _buildBodyForIndex() {
    switch (_selectedIndex) {
      case 0:
        return _buildResumen();
      case 1:
        return _buildEmpresas();
      case 2:
        return _buildAdmins();
      default:
        return _buildResumen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.grey.shade50,
      body: _buildBodyForIndex(),
      bottomNavigationBar: Material(
        elevation: 8,
        color: Colors.white,
        child: SafeArea(
          bottom: true,
          child: Container(
            // más altura para que el pill no se vea aplastado
            height: 96,
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 12.0,
            ),
            child: Center(
              // limitamos el ancho del pill para que tenga espacio lateral y quede visualmente centrado
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: SuperAdminNavPill(
                  selectedIndex: _selectedIndex,
                  onSelect: (i) => setState(() => _selectedIndex = i),
                  onFloating: () {
                    // acción del botón flotante: abrir creación rápida
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
