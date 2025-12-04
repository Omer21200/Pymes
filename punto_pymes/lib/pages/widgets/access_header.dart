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
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: const DecorationImage(
          image: AssetImage('assets/images/pymes.png'),
          fit: BoxFit.cover,
        ),
      ),
      // Si quieres un overlay (oscurecer la imagen), puedes envolver
      // el contenido en un Stack y añadir un Container con color y opacidad.
      child: Container(),
    );
  }
}
