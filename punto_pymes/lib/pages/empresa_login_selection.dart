import 'package:flutter/material.dart';
import 'package:pymes2/pages/login_page/register_page.dart';
import 'login_page/login_page.dart';
import 'registro_empleado.dart';

class EmpresaLoginSelection extends StatelessWidget {
  final Map<String, dynamic> empresa;
  const EmpresaLoginSelection({super.key, required this.empresa});

  @override
  Widget build(BuildContext context) {
    final nombre = empresa['nombre'] ?? 'Empresa';
    final foto = empresa['empresa_foto_url'] as String?;
    
    // Color de marca (extraído de tu código original)
    const brandColor = Color(0xFFD92344);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Fondo gris muy suave
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87), // Flecha negra
      ),
      extendBodyBehindAppBar: true, // Permite que el diseño fluya detrás
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. LOGO DE LA EMPRESA CON SOMBRA
                Center(
                  child: Container(
                    height: 150,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(4), // Borde blanco alrededor de la imagen
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: foto != null
                          ? Image.network(
                              foto,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.apartment,
                                size: 80,
                                color: brandColor,
                              ),
                            )
                          : const Icon(
                              Icons.apartment,
                              size: 80,
                              color: brandColor,
                            ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // 2. NOMBRE Y BIENVENIDA
                Text(
                  nombre,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bienvenido',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500
                  ),
                ),

                const SizedBox(height: 48),

                // 3. BOTÓN PRINCIPAL (INICIAR SESIÓN)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => LoginPage(empresa: empresa)),
                    );
                  },
                  icon: const Icon(Icons.login_rounded),
                  label: const Text(
                    'Iniciar Sesión',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    shadowColor: brandColor.withOpacity(0.4),
                  ),
                ),

                const SizedBox(height: 32),

                // 4. DIVISOR DE SECCIÓN (Visualmente separa el login del registro)
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '¿No tienes cuenta?',
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                  ],
                ),

                const SizedBox(height: 24),

                // 5. BOTONES SECUNDARIOS (REGISTRO)
                
                // Registro Admin
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RegisterPage(empresa: empresa)),
                    );
                  },
                  icon: const Icon(Icons.verified_user_outlined),
                  label: const Text('Registrar Administrador'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 12),

                // Registro Empleado
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RegisterPageEmpleado(empresa: empresa)),
                    );
                  },
                  icon: const Icon(Icons.badge_outlined), // Icono de credencial
                  label: const Text('Registrar Empleado'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}