import 'package:flutter/material.dart';
import '../../service/supabase_service.dart';

/// Muestra las empresas registradas desde Supabase en forma de grilla.
class InstitutionsGrid extends StatefulWidget {
  final void Function(Map<String, dynamic> empresa)? onEmpresaSelected;
  const InstitutionsGrid({super.key, this.onEmpresaSelected});

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
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(minHeight: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
            ],
          ),
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

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemCount: empresas.length,
                itemBuilder: (context, index) {
                  final e = empresas[index];
                  final nombre = (e['nombre'] ?? 'Sin nombre') as String;
                  final foto = e['empresa_foto_url'] as String?;

                  return InkWell(
                    onTap: () {
                      if (widget.onEmpresaSelected != null) {
                        widget.onEmpresaSelected!(e);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFECEF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: foto != null
                                ? Image.network(
                                    foto,
                                    height: 64,
                                    width: 64,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.apartment, size: 48, color: Color(0xFFD92344)),
                                  )
                                : const Icon(Icons.apartment, size: 48, color: Color(0xFFD92344)),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            nombre,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
