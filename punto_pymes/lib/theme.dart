import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // 1. Paleta de Colores
  static const Color primaryColor = Color(0xFFD92344); // Rojo corporativo
  static const Color secondaryColor = Color(0xFF2C3E50); // Azul oscuro textos
  static const Color backgroundColor = Color(0xFFF5F7FA); // Fondo gris suave
  static const Color surfaceColor = Colors.white; // Tarjetas
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color textGrey = Color(0xFF616161);
  static const Color iconGrey = Color(0xFF9E9E9E);

  // Colores de soporte (Pasteles)
  static const Color accentBlue = Color(0xFFE3F2FD);
  static const Color accentPink = Color(0xFFFFEBEE);
  static const Color accentOrange = Color(0xFFFFF3E0);

  // 2. Decoración Estándar para Tarjetas (¡Úsala en tus Containers!)
 static BoxDecoration get cardDecoration {
    return BoxDecoration(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      border: Border.all(color: Colors.grey.withOpacity(0.1)),
    );
  }

  // 2. Estilo del contenedor del Logo (Fondo suave del color primario)
  static BoxDecoration get avatarDecoration {
    return BoxDecoration(
      color: primaryColor.withOpacity(0.08), // Un rojo muy suave en lugar de azul random
      borderRadius: BorderRadius.circular(12),
    );
  }

  // 3. Definición del Tema Global
 static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      
      // Textos definidos aquí para no ensuciar los archivos
      textTheme: TextTheme(
        headlineMedium: GoogleFonts.inter(
          fontSize: 24, fontWeight: FontWeight.bold, color: secondaryColor
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.bold, color: secondaryColor
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14, color: textGrey
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 13, color: iconGrey
        ),
      ),

      // Estilo por defecto de los botones
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      
      // Iconos
      iconTheme: const IconThemeData(color: primaryColor),
    );
  }
  static BoxDecoration get adminAvatarDecoration {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [primaryColor.withOpacity(0.7), primaryColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: primaryColor.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        )
      ],
    );
  }

  // 4. Estilo para la etiqueta de Rol (Ej: ADMIN EMPRESA)
  static BoxDecoration get roleTagDecoration {
    return BoxDecoration(
      color: const Color(0xFFE3F2FD), // Azul muy suave (puedes cambiarlo si quieres)
      borderRadius: BorderRadius.circular(6),
    );
  }

  // 5. Estilo de texto para la etiqueta de Rol
  static TextStyle get roleTagTextStyle {
    return GoogleFonts.inter(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF1565C0), // Azul oscuro
    );
  }
}