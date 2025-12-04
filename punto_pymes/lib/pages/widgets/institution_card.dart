import 'package:flutter/material.dart';

class InstitutionCard extends StatelessWidget {
  final String name;
  final String imageUrl; // Agregamos la URL de la imagen
  final VoidCallback onTap;

  const InstitutionCard({
    required this.name,
    required this.imageUrl, // La URL es requerida
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      // ClipRRect recorta la imagen con los bordes redondeados
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          12,
        ), // Bordes redondeados de la tarjeta
        child: Stack(
          fit:
              StackFit.expand, // Hace que los hijos del Stack llenen el espacio
          children: [
            // 1. Imagen de fondo (El logo azul que llena toda la tarjeta)
            Image.network(
              imageUrl,
              fit: BoxFit
                  .cover, // 'cover' hace que la imagen llene el contenedor sin deformarse
              // Muestra un icono de error si la imagen no carga
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300], // Fondo gris en caso de error
                  child: const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
            ),

            // 2. Capa superior con el icono y el texto
            // Usamos un degradado sutil para asegurar que el texto blanco se lea bien sobre cualquier imagen
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    // ignore: deprecated_member_use
                    Colors.black.withOpacity(0.1), // Sombra muy sutil arriba
                    // ignore: deprecated_member_use
                    Colors.black.withOpacity(
                      0.4,
                    ), // Sombra más oscura abajo para el texto
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment
                      .center, // Centra el contenido verticalmente
                  children: [
                    // Icono del banco (color blanco para resaltar)
                    const Icon(
                      Icons.account_balance_rounded,
                      color: Colors.white,
                      size: 40,
                    ),

                    const SizedBox(height: 12), // Espacio entre icono y texto
                    // Nombre de la institución (texto blanco)
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // Texto en blanco
                        shadows: [
                          Shadow(
                            blurRadius: 4.0,
                            color: Colors.black45,
                            offset: Offset(1.0, 1.0),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
