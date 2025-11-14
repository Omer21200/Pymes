import 'package:flutter/material.dart';

class ProfileCard extends StatelessWidget {
  final String userName;
  final String institutionName;
  final String role;
  final VoidCallback? onAction;
  final String? confirmTitle;
  final String? confirmMessage;

  const ProfileCard({
    required this.userName,
    required this.institutionName,
    this.role = 'Empleado',
    this.onAction,
    this.confirmTitle,
    this.confirmMessage,
    super.key,
  });

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _initials(userName);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFDC0F1A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  institutionName,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    role,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              // Mostrar diálogo de confirmación antes de ejecutar la acción (p.ej. cerrar sesión)
              await showDialog<void>(
                context: context,
                builder: (ctx) {
                  bool isProcessing = false;
                  return StatefulBuilder(
                    builder: (ctx2, setState) => AlertDialog(
                      title: Text(confirmTitle ?? 'Confirmar'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(confirmMessage ?? '¿Deseas cerrar sesión?'),
                          const SizedBox(height: 12),
                          if (isProcessing)
                            const Center(child: CircularProgressIndicator()),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: isProcessing
                              ? null
                              : () => Navigator.of(ctx2).pop(),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: isProcessing
                              ? null
                              : () async {
                                  if (onAction == null) {
                                    Navigator.of(ctx2).pop();
                                    return;
                                  }
                                  setState(() => isProcessing = true);
                                  try {
                                    await Future.sync(onAction!);
                                  } catch (e) {
                                    ScaffoldMessenger.of(ctx2).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error ejecutando la acción: $e',
                                        ),
                                      ),
                                    );
                                  }
                                  // Intentar cerrar el diálogo; si la acción navegó ya, esto puede no tener efecto
                                  try {
                                    if (Navigator.of(ctx2).canPop())
                                      Navigator.of(ctx2).pop();
                                  } catch (_) {}
                                },
                          child: const Text('Cerrar sesión'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            icon: const Icon(Icons.login_outlined, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
