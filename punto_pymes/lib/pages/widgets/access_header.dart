import 'package:flutter/material.dart';

/// Encabezado de la pantalla (logo / imagen de cabecera).
///
/// Nota: aquí se puede colocar una `Image.asset(...)` con el logo o
/// una imagen de cabecera. No se incluye ninguna asset concreta
/// para evitar referencias a imágenes inexistentes.
class AccessHeader extends StatelessWidget {
  const AccessHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        image: const DecorationImage(
          image: AssetImage('assets/images/logo.png'),
          fit: BoxFit.cover, // hace que la imagen rellene todo el contorno
        ),
      ),
      // Overlay ligero para mejorar contraste del contenido encima
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black.withValues(alpha: 0.06), Colors.transparent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    );
  }
}
