import 'package:flutter/material.dart';
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
    final accent = Theme.of(context).primaryColor;

    return SafeArea(
      top: true,
      bottom: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (showBack)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  tooltip: 'Volver',
                ),
              ),
            const CircleAvatar(
              radius: 26,
              backgroundColor: Colors.white,
              child: Icon(Icons.shield, color: Color(0xFFD92344), size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (actions != null)
              Row(mainAxisSize: MainAxisSize.min, children: actions!)
            else if (showLogout)
              Container(
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: () => showLogoutConfirmation(
                    context,
                    afterRoute: '/access-selection',
                  ),
                  icon: Icon(Icons.exit_to_app, color: accent),
                  tooltip: 'Cerrar sesión',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
