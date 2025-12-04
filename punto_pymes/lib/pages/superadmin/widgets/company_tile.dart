import 'package:flutter/material.dart';

class CompanyTile extends StatelessWidget {
  final Map<String, dynamic> empresa;
  final VoidCallback? onTap;
  final Widget? trailing;

  const CompanyTile({super.key, required this.empresa, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    final foto = empresa['empresa_foto_url'] as String?;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        leading: foto != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  foto,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFECEF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.business, color: Color(0xFFD92344)),
                  ),
                ),
              )
            : Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECEF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.business, color: Color(0xFFD92344)),
              ),
        title: Text(
          empresa['nombre'] ?? 'Sin nombre',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (empresa['ruc'] != null) Text('RUC: ${empresa['ruc']}'),
            if (empresa['correo'] != null) Text('${empresa['correo']}'),
          ],
        ),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
