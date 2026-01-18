import 'package:flutter/material.dart';
import '../../../theme.dart';

class CompanyTile extends StatelessWidget {
  final Map<String, dynamic> empresa;
  final VoidCallback? onTap;
  final Widget? trailing;

  const CompanyTile({
    super.key,
    required this.empresa,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final foto = empresa['empresa_foto_url'] as String?;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppDecorations.card,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Row(
            children: [
              if (foto != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    foto,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        // ignore: deprecated_member_use
                        color: AppColors.accentBlue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.business,
                        color: AppColors.accentBlue,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: AppColors.accentBlue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.business,
                    color: AppColors.accentBlue,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      empresa['nombre'] ?? 'Sin nombre',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (empresa['ruc'] != null)
                      Text(
                        'RUC: ${empresa['ruc']}',
                        style: TextStyle(color: AppColors.mutedGray),
                      ),
                    if (empresa['correo'] != null)
                      Text(
                        '${empresa['correo']}',
                        style: TextStyle(color: AppColors.mutedGray),
                      ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.mutedGray,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
