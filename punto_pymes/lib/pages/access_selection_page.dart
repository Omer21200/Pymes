import 'package:flutter/material.dart';
import 'widgets/access_header.dart';
import 'widgets/search_institutions.dart';
import 'widgets/institutions_grid.dart';
import 'empresa_login_selection.dart';
import 'widgets/admin_button.dart';

class AccessSelectionPage extends StatelessWidget {
  const AccessSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header fijo arriba
            const AccessHeader(),
            
            // Contenido desplazable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      'Selecciona tu tipo de acceso',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14, 
                        color: Colors.black87,
                        fontWeight: FontWeight.w500
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Buscador
                    const SearchInstitutions(),
                    const SizedBox(height: 18),
                    
                    // Grid de empresas (Aquí se verán tus tarjetas nuevas)
                    InstitutionsGrid(
                      onEmpresaSelected: (empresa) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EmpresaLoginSelection(empresa: empresa),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Botón de admin al final
                    const AdminButton(),
                    const SizedBox(height: 20), // Espacio extra al final para scroll
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}