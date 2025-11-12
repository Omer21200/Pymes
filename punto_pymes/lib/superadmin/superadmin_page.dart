import 'package:flutter/material.dart';
import '../widgets/profile_card.dart';
import '../widgets/bottom_nav_pill.dart';
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

  // Mock data
  final List<Map<String, dynamic>> _metrics = [
    {'title': 'Empresas', 'value': '4'},
    {'title': 'Admins', 'value': '8'},
    {'title': 'Empleados', 'value': '324'},
    {'title': 'Activos Hoy', 'value': '298'},
  ];

  List<Map<String, dynamic>> _companies = [];

  final List<Map<String, String>> _activities = [
    {'title': 'Nueva empresa registrada: Banco Pichincha', 'subtitle': 'Hace 2 horas'},
    {'title': 'Nuevo admin creado para UTPL: Carlos Mendoza', 'subtitle': 'Hace 3 horas'},
    {'title': 'Alta actividad de registro en Coopmego', 'subtitle': 'Hace 5 horas'},
    {'title': '50 nuevos empleados registrados hoy', 'subtitle': 'Hace 6 horas'},
  ];

  @override
  void initState() {
    super.initState();
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
        _companies = resList.map<Map<String, dynamic>>((e) => {
              'id': e['id'],
              'name': e['nombre'] ?? e['name'] ?? '',
              'ruc': e['ruc'] ?? '',
              'direccion': e['direccion'] ?? '',
              'telefono': e['telefono'] ?? '',
              'email': e['email'] ?? '',
              'hora_entrada': e['hora_entrada'] ?? '',
              'tolerancia_minutos': e['tolerancia_minutos'] ?? 0,
            }).toList();
      });
    } catch (e) {
      debugPrint('Error cargando empresas: $e');
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
            onAction: () {
              // ejemplo: cerrar sesión o cambiar contexto
            },
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Resumen del Sistema', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          // Small metric cards grid
          Row(
            children: _metrics.map((m) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 4))]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m['title'].toString(), style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text(m['value'].toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('Estado de Empresas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Column(
            children: _companies.map((c) {
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.apartment, color: Colors.red),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Text('${c['employees']} empleados • ${c['admins']} admins', style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: (c['progress'] as double),
                                      minHeight: 8,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                                      backgroundColor: Colors.grey.shade200,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('${((c['progress'] as double) * 100).round()}%', style: const TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade400)),
                        child: const Text('Activa', style: TextStyle(color: Colors.green)),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('Actividad Reciente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._activities.map((a) => Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a['title']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(a['subtitle']!, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ))
        ],
      ),
    );
  }

  Widget _buildEmpresas() {
    return EmpresasPage(userName: widget.userName);
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
      backgroundColor: Colors.grey.shade50,
      body: Stack(
        children: [
          _buildBodyForIndex(),
          // Positioned bottom navigation pill
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: Center(
              child: SuperAdminNavPill(
                selectedIndex: _selectedIndex,
                onSelect: (i) => setState(() => _selectedIndex = i),
                onFloating: () {
                  // acción del botón flotante: abrir creación rápida
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
