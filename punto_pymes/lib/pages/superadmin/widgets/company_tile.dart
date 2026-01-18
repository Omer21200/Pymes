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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          child: Row(
            children: [
              if (foto != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    foto,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
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
                    color: AppColors.accentBlue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
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
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (empresa['ruc'] != null)
                      Text(
                        'RUC: ${empresa['ruc']}',
                        style: TextStyle(
                          color: AppColors.mutedGray,
                          fontSize: 13,
                        ),
                      ),
                    if (empresa['correo'] != null)
                      Text(
                        '${empresa['correo']}',
                        style: TextStyle(
                          color: AppColors.mutedGray,
                          fontSize: 13,
                        ),
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
