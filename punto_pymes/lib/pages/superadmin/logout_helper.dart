import 'package:flutter/material.dart';
import '../../service/supabase_service.dart';

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
      title: const Text('Cerrar sesión'),
      content: const Text('¿Seguro que quieres cerrar sesión?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
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
