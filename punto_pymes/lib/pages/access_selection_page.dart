import 'package:flutter/material.dart';
import 'widgets/access_header.dart';
import 'widgets/search_institutions.dart';
import 'widgets/institutions_grid.dart';
import 'empresa_login_selection.dart';
import 'widgets/admin_button.dart';

class AccessSelectionPage extends StatefulWidget {
  const AccessSelectionPage({super.key});

  @override
  State<AccessSelectionPage> createState() => _AccessSelectionPageState();
}

class _AccessSelectionPageState extends State<AccessSelectionPage> {
  String _filter = '';

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

            // Contenido principal (scrollable)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
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
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Buscador con callback
                    SearchInstitutions(
                      onChanged: (v) => setState(() => _filter = v),
                    ),
                    const SizedBox(height: 18),

                    // Grid de empresas: calculamos una altura que muestre 2 filas (4 items)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final availableWidth = constraints.maxWidth;
                        // internal horizontal spacing in InstitutionsGrid is 12 (crossAxisSpacing)
                        final itemWidth = (availableWidth - 12) / 2;
                        const childAspectRatio = 1.2;
                        final itemHeight = itemWidth / childAspectRatio;
                        // 2 filas + spacing. Resto unos píxeles para evitar
                        // que se vea parcialmente el 5º elemento.
                        final gridHeight = itemHeight * 2 + 12 - 8.0;

                        return InstitutionsGrid(
                          filter: _filter,
                          height: gridHeight,
                          onEmpresaSelected: (empresa) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EmpresaLoginSelection(empresa: empresa),
                              ),
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Botón de admin al final
                    const AdminButton(),
                    const SizedBox(height: 20), // Espacio extra
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
