import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Asegúrate de tener esta dependencia o usa texto normal

class AppTheme {
  // 1. Paleta de Colores
  static const Color primaryColor = Color(0xFFD92344); // Tu rojo corporativo
  static const Color secondaryColor = Color(0xFF2C3E50); // Un azul oscuro para textos/títulos
  static const Color backgroundColor = Color(0xFFF5F7FA); // Gris muy claro para fondos (moderno)
  static const Color surfaceColor = Colors.white; // Para tarjetas
  static const Color errorColor = Color(0xFFD32F2F);
  
  // Colores de soporte para dashboard (pasteles suaves para fondos de iconos)
  static const Color accentBlue = Color(0xFFE3F2FD);
  static const Color accentPink = Color(0xFFFFEBEE);
  static const Color accentOrange = Color(0xFFFFF3E0);

  // 2. Definición del Tema Global
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      
      /* // Estilo de Tarjetas (Cards)
      cardTheme: CardTheme(
        color: surfaceColor,
        elevation: 0, // Quitamos elevación por defecto para usar sombras custom o bordes sutiles
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200), // Borde muy sutil
        ),
        margin: const EdgeInsets.only(bottom: 16),
      ), */

      // Estilo de AppBars
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white, 
          fontSize: 20, 
          fontWeight: FontWeight.bold
        ),
      ),

      // Estilos de Texto (TextTheme)
      textTheme: TextTheme(
        headlineMedium: GoogleFonts.inter( // O TextStyle normal si no usas google_fonts
          fontSize: 28, 
          fontWeight: FontWeight.bold, 
          color: secondaryColor
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20, 
          fontWeight: FontWeight.w700, 
          color: secondaryColor
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16, 
          fontWeight: FontWeight.w600, 
          color: secondaryColor
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14, 
          color: Colors.grey[700]
        ),
      ),

      // Estilo de Botones
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }
}