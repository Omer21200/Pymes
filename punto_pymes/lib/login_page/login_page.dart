import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  final String selectedInstitution;

  const LoginPage({required this.selectedInstitution, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Volver'),
        backgroundColor: const Color(0xFFD92344),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'NEXUS',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD92344),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Acceso Empleado',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                selectedInstitution,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Ingresa tu usuario',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Ingresa tu contraseña',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    // Handle login
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD92344),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Ingresar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: const [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('O continuar con'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: Image.network(
                      'data:image/png;base64,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',
                      width: 50,
                      height: 50,
                    ),
                    label: const Text('Continuar con Google'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(
                        255,
                        255,
                        255,
                        255,
                      ), // Google blue
                      foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  // Handle registration
                },
                child: RichText(
                  text: TextSpan(
                    text: '¿No tienes una cuenta? ',
                    style: const TextStyle(
                      color: Colors.black, // Black for the first part
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(
                        text: 'Regístrate',
                        style: const TextStyle(
                          color: Color(0xFFD92344), // Red for 'Regístrate'
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
