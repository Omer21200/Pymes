import 'package:flutter/material.dart';
import '../../service/supabase_service.dart';
// search_institutions.dart removed from this screen on user request

/// Muestra las empresas registradas desde Supabase en forma de grilla.
class InstitutionsGrid extends StatefulWidget {
  final void Function(Map<String, dynamic> empresa)? onEmpresaSelected;
  final String? filter;
  final double? height;

  const InstitutionsGrid({
    super.key,
    this.onEmpresaSelected,
    this.filter,
    this.height,
  });

  @override
  State<InstitutionsGrid> createState() => _InstitutionsGridState();
}

class _InstitutionsGridState extends State<InstitutionsGrid> {
  late Future<List<Map<String, dynamic>>> _futureEmpresas;

  @override
  void initState() {
    super.initState();
    _futureEmpresas = SupabaseService.instance.getEmpresas();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),

        // Grid of institutions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _futureEmpresas,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return SizedBox(
                  height: 220,
                  child: Center(
                    child: Text(
                      'Error al cargar instituciones: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                );
              }

              final empresas = snapshot.data ?? [];
              if (empresas.isEmpty) {
                return const SizedBox(
                  height: 220,
                  child: Center(
                    child: Text(
                      'No hay instituciones registradas',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              // Apply simple client-side filter by nombre
              final lowerFilter = (widget.filter ?? '').trim().toLowerCase();
              final filtered = lowerFilter.isEmpty
                  ? empresas
                  : empresas.where((e) {
                      final nombre = (e['nombre'] ?? '')
                          .toString()
                          .toLowerCase();
                      return nombre.contains(lowerFilter);
                    }).toList();

              final grid = GridView.builder(
                shrinkWrap: false,
                physics: const AlwaysScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final e = filtered[index];
                  final nombre = (e['nombre'] ?? 'Sin nombre') as String;
                  final foto = e['empresa_foto_url'] as String?;

                  return InkWell(
                    onTap: () {
                      if (widget.onEmpresaSelected != null) {
                        widget.onEmpresaSelected!(e);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          foto != null
                              ? Image.network(
                                  foto,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: Icon(
                                            Icons.apartment,
                                            size: 48,
                                            color: Color(0xFFD92344),
                                          ),
                                        ),
                                      ),
                                )
                              : Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Icon(
                                      Icons.apartment,
                                      size: 48,
                                      color: Color(0xFFD92344),
                                    ),
                                  ),
                                ),

                          // Gradient overlay to make text readable
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.45),
                                ],
                              ),
                            ),
                          ),

                          // Name over the image
                          Positioned(
                            left: 12,
                            right: 12,
                            bottom: 12,
                            child: Text(
                              nombre,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                shadows: [
                                  Shadow(
                                    blurRadius: 4.0,
                                    color: Colors.black45,
                                    offset: Offset(1.0, 1.0),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );

              // If a fixed height is provided, wrap grid in SizedBox so only grid scrolls
              if (widget.height != null) {
                return SizedBox(height: widget.height, child: grid);
              }

              return grid;
            },
          ),
        ),
      ],
    );
  }
}
