import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme.dart';
import '../logout_helper.dart';

class SuperadminHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showLogout;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final Color? backgroundColor;

  const SuperadminHeader({
    super.key,
    this.title = 'Super Administrador',
    this.subtitle = 'Gestión del Sistema NEXUS',
    this.showLogout = true,
    this.showBack = false,
    this.onBack,
    this.actions,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? Theme.of(context).primaryColor;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Builder(
          builder: (context) {
            final topInset = MediaQuery.of(context).padding.top;
            return Container(
              width: double.infinity,
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
                  // Avatar: same structure as EmpleadoHeader
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
                        child: Container(
                          width: AppSizes.avatar * 0.6,
                          height: AppSizes.avatar * 0.6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.shield,
                              color: AppColors.brandRedAlt,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Información (título + subtítulo) igual que EmpleadoHeader
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
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
                            subtitle,
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
                  // Logout button (same visual style)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => showLogoutConfirmation(
                        context,
                        afterRoute: '/access-selection',
                      ),
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
