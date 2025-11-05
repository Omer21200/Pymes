import 'package:flutter/material.dart';

class AccessSelectionPage extends StatefulWidget {
  const AccessSelectionPage({super.key});

  @override
  State<AccessSelectionPage> createState() => _AccessSelectionPageState();
}

class _AccessSelectionPageState extends State<AccessSelectionPage> {
  String selectedRole = 'Usuario';
  String selectedInstitution = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: const Text(
                'Selecciona tu tipo de acceso',
                style: TextStyle(fontSize: 16), // Adjusted font size for mobile
              ),
            ),
            DropdownButton<String>(
              value: null,
              items: const [
                DropdownMenuItem(value: 'Usuario', child: Text('Usuario')),
                DropdownMenuItem(
                  value: 'Administrador',
                  child: Text('Administrador'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedRole = value!;
                });
              },
              icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
              underline: Container(),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFD92344),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Empleado - Selecciona tu institución',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar institución...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: MediaQuery.of(context).size.width * 0.05,
                    // Adjust spacing dynamically
                    runSpacing: MediaQuery.of(context).size.height * 0.02,
                    // Adjust run spacing dynamically
                    children: [
                      InstitutionCard(
                        name: 'Banco de Loja',
                        isSelected: selectedInstitution == 'Banco de Loja',
                        onTap: () {
                          setState(() {
                            selectedInstitution = 'Banco de Loja';
                          });
                        },
                      ),
                      InstitutionCard(
                        name: 'Coopmego',
                        isSelected: selectedInstitution == 'Coopmego',
                        onTap: () {
                          setState(() {
                            selectedInstitution = 'Coopmego';
                          });
                        },
                      ),
                      InstitutionCard(
                        name: 'UTPL',
                        isSelected: selectedInstitution == 'UTPL',
                        onTap: () {
                          setState(() {
                            selectedInstitution = 'UTPL';
                          });
                        },
                      ),
                      InstitutionCard(
                        name: 'UNL',
                        isSelected: selectedInstitution == 'UNL',
                        onTap: () {
                          setState(() {
                            selectedInstitution = 'UNL';
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              selectedRole == 'Administrador' ? 'Administrador' : 'Usuario',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  if (selectedRole == 'Usuario') {
                    Navigator.pushNamed(context, '/login');
                  } else if (selectedRole == 'Administrador') {
                    Navigator.pushNamed(context, '/admin-dashboard');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD92344),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Acceso $selectedRole',
                  style: const TextStyle(
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
    );
  }
}

class InstitutionCard extends StatelessWidget {
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const InstitutionCard({
    required this.name,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD92344) : const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.apartment,
              color: isSelected ? Colors.white : const Color(0xFFD92344),
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
