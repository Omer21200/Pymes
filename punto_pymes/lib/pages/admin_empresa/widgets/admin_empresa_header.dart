import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme.dart';

class AdminEmpresaHeader extends StatelessWidget {
  final String? nombreAdmin;
  final String? nombreEmpresa;
  final VoidCallback? onLogout;
  final bool showBack;
  final VoidCallback? onBack;

  const AdminEmpresaHeader({
    super.key,
    this.nombreAdmin,
    this.nombreEmpresa,
    this.onLogout,
    this.showBack = false,
    this.onBack,
  });

  String _getInitials() {
    if (nombreAdmin == null || nombreAdmin!.isEmpty) return 'AD';
    final parts = nombreAdmin!.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return nombreAdmin!.substring(0, 2).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Builder(
          builder: (context) {
            final topInset = MediaQuery.of(context).padding.top;
            return Container(
              padding: EdgeInsets.fromLTRB(20, topInset + 20, 20, 20),
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
                  if (showBack)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Material(
                        color: Colors.white.withAlpha((0.14 * 255).round()),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: onBack,
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Avatar: initials inside avatarContainer
                  Container(
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
                      child: Center(
                        child: Text(
                          _getInitials(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Admin ${nombreEmpresa ?? "Empresa"}',
                          style: AppTextStyles.headline.copyWith(
                            color: Colors.white,
                          ),
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
                            nombreAdmin ?? 'Administrador',
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
                        child: const Icon(
                          Icons.logout,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
