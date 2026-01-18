import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Anti-Gravity Core Colors - Matt High-Contrast Palette
  static const Color neonGreen = Color(0xFF00FF41); 
  static const Color darkGreen = Color(0xFF00BD32); 
  static const Color deepBlack = Color(0xFF000000); 
  static const Color surfaceBlack = Color(0xFF050505); 
  static const Color elevatedSurface = Color(0xFF0A0A0A); 
  static const Color borderGlow = Color(0xFF151515); 
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGrey = Color(0xFF757575);
  static const Color textDimmed = Color(0xFF424242);
  
  static const Color errorRed = Color(0xFFFF0033);
  static const Color warningOrange = Color(0xFFFF9500);
  static const Color infoBlue = Color(0xFF007AFF);

  // Matt Box Decoration (Replaces Glassmorphism)
  static BoxDecoration mattBox({
    Color? color,
    bool withBorder = true,
    double radius = 4,
  }) {
    return BoxDecoration(
      color: color ?? surfaceBlack,
      borderRadius: BorderRadius.circular(radius),
      border: withBorder
          ? Border.all(
              color: neonGreen.withOpacity(0.3),
              width: 1,
            )
          : null,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: deepBlack,
      primaryColor: neonGreen,
      colorScheme: const ColorScheme.dark(
        primary: neonGreen,
        secondary: darkGreen,
        surface: surfaceBlack,
        background: deepBlack,
        error: errorRed,
        onPrimary: deepBlack,
        onSecondary: deepBlack,
        onSurface: textWhite,
        onBackground: textWhite,
      ),
      
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.spaceGrotesk(
          fontSize: 40, 
          fontWeight: FontWeight.bold, 
          color: textWhite,
          letterSpacing: -1,
        ),
        displayMedium: GoogleFonts.spaceGrotesk(
          fontSize: 28, 
          fontWeight: FontWeight.bold, 
          color: textWhite,
          letterSpacing: -0.5,
        ),
        displaySmall: GoogleFonts.spaceGrotesk(
          fontSize: 20, 
          fontWeight: FontWeight.w600, 
          color: textWhite,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textWhite,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15, 
          color: textWhite,
          letterSpacing: 0.1,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13, 
          color: textGrey,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textWhite,
          letterSpacing: 0.5,
        ),
      ),

      cardTheme: CardThemeData(
        color: surfaceBlack,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(
            color: neonGreen.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: elevatedSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: borderGlow, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: borderGlow, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: neonGreen, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textGrey, fontSize: 13),
        hintStyle: const TextStyle(color: textDimmed, fontSize: 13),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonGreen,
          foregroundColor: deepBlack,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            letterSpacing: 1.0,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: neonGreen,
          side: const BorderSide(color: neonGreen, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            letterSpacing: 1.0,
          ),
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: surfaceBlack,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textWhite,
        ),
      ),

      iconTheme: const IconThemeData(
        color: neonGreen,
        size: 20,
      ),
    );
  }
}
