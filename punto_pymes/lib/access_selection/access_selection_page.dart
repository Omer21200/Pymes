import 'package:flutter/material.dart';
import '../login_page/login_page.dart';
import '../main.dart';
import '../widgets/institution_card.dart';

class AccessSelectionPage extends StatefulWidget {
  const AccessSelectionPage({super.key});

  @override
  State<AccessSelectionPage> createState() => _AccessSelectionPageState();
}

class _AccessSelectionPageState extends State<AccessSelectionPage> {
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _institutions = [];
  // indica si ya intentamos cargar instituciones al menos una vez
  bool _hasLoaded = false;
  @override
  Widget build(BuildContext context) {
    // aseguramos que las empresas se carguen la primera vez
    // evitamos reintentar continuamente cuando la lista queda vacía
    if (!_isLoading && !_hasLoaded && _error == null) {
      // iniciar carga asíncrona sin bloquear el build
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadInstitutions());
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: const Color(0xFFD92344),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🖼️ Sección de Banner/Logo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 20),
              child: Image.asset(
                'assets/images/pymes.png',
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 50),
                    ),
                  );
                },
              ),
            ),

            // 📋 Contenedor principal con padding
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 🏢 Sección de selección de institución
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selecciona tu institución',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Buscar institución...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Mostrar carga / error / lista de instituciones obtenidas desde la BD
                        if (_isLoading)
                          const SizedBox(
                            width: double.infinity,
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          )
                        else if (_error != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Error cargando instituciones: $_error',
                              style: const TextStyle(color: Colors.red),
                            ),
                          )
                        else if (_institutions.isEmpty)
                          const Text(
                            'No hay instituciones registradas',
                            style: TextStyle(color: Colors.grey),
                          )
                        else
                          Wrap(
                            alignment: WrapAlignment.start,
                            spacing: 12,
                            runSpacing: 12,
                            children: _institutions.map((inst) {
                              final String name =
                                  (inst['nombre'] ?? inst['name'] ?? '—')
                                      .toString();
                              return InstitutionCard(
                                name: name,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LoginPage(
                                        selectedInstitution: name,
                                        selectedRole: 'Institución',
                                      ),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 🔘 Botón de acceso para Administrador General (siempre visible al final)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginPage(
                              selectedInstitution: '',
                              selectedRole: 'Administrador General',
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD92344),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Acceso Administrador General',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadInstitutions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await supabase
          .from('empresas')
          .select('id,nombre')
          .order('nombre');
      final List list = res as List? ?? [];
      setState(() {
        _institutions = list
            .map<Map<String, dynamic>>(
              (e) => {'id': e['id'], 'nombre': e['nombre'] ?? e['name'] ?? ''},
            )
            .toList();
      });
    } catch (e) {
      debugPrint('Error cargando instituciones: $e');
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
          _hasLoaded = true;
        });
    }
  }
}

// InstitutionCard moved to `lib/widgets/institution_card.dart`
