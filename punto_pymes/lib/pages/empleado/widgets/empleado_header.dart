import 'package:flutter/material.dart';
import '../../../theme.dart';

class EmpleadoHeader extends StatelessWidget {
  final String name;
  final String affiliation;
  final VoidCallback? onLogout;
  final VoidCallback? onProfile;
  final String? avatarUrl;

  const EmpleadoHeader({
    super.key,
    required this.name,
    required this.affiliation,
    this.onLogout,
    this.onProfile,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .map((e) => e.isEmpty ? '' : e[0])
        .take(2)
        .join()
        .toUpperCase();

    final double topPad = MediaQuery.of(context).padding.top;

    return Container(
      // background extends into the notch area but content is pushed down
      padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, 20),
      decoration: AppDecorations.headerGradient.copyWith(
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha((0.28 * 255).round()),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar: muestra foto si existe, si no muestra iniciales
          GestureDetector(
            onTap: onProfile,
            child: Container(
              width: AppSizes.avatar,
              height: AppSizes.avatar,
              decoration: AppDecorations.avatarContainer.copyWith(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.15 * 255).round()),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: avatarUrl != null && avatarUrl!.isNotEmpty
                    ? Image.network(
                        avatarUrl!,
                        width: AppSizes.avatar,
                        height: AppSizes.avatar,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Información del usuario
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: AppTextStyles.headline.copyWith(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((0.2 * 255).round()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    affiliation,
                    style: AppTextStyles.smallLabel.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // (Se removió el botón de perfil redundante; el avatar es clickeable)
          // Botón de logout mejorado
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onLogout,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((0.15 * 255).round()),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withAlpha((0.3 * 255).round()),
                    width: 1.5,
                  ),
                ),
                child: const Icon(Icons.logout, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
