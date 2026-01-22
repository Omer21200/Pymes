import 'package:flutter/material.dart';
import '../../service/supabase_service.dart';
import '../../theme.dart';

/// Muestra un diálogo de confirmación para cerrar sesión.
/// Si el usuario confirma, navega a la ruta '/login' y limpia la pila.
Future<bool> showLogoutConfirmation(
  BuildContext context, {
  String afterRoute = '/login',
}) async {
  final navigator = Navigator.of(context);
  final choice = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Cerrar sesión',
        // use brandRed to better match header/background red
        style: TextStyle(color: AppColors.brandRed),
      ),
      content: const Text('¿Seguro que quieres cerrar sesión?'),
      actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(foregroundColor: AppColors.brandRed),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandRed,
            foregroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
            elevation: 8,
            shadowColor: AppColors.brandRed.withAlpha(102),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text('Cerrar sesión'),
        ),
      ],
    ),
  );

  if (choice == true) {
    // Cerrar sesión en Supabase y navegar a la ruta indicada
    try {
      await SupabaseService.instance.signOut();
    } catch (_) {
      // ignore signOut errors, still redirect
    }
    navigator.pushNamedAndRemoveUntil(afterRoute, (route) => false);
    return true;
  }

  return false;
}
