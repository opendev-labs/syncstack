import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // SyncStack Core Colors - Infra-Grade Palette
  static const Color cyanAccent = Color(0xFF00A3FF); 
  static const Color darkCyan = Color(0xFF007ACC); 
  static const Color deepBlack = Color(0xFF000000); 
  static const Color surfaceBlack = Color(0xFF0A0A0A); 
  static const Color elevatedSurface = Color(0xFF121212); 
  static const Color borderGlow = Color(0xFF1A1A1A); 
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGrey = Color(0xFF888888);
  static const Color textDimmed = Color(0xFF555555);
  
  static const Color errorRed = Color(0xFFFF3B30);
  static const Color warningOrange = Color(0xFFFF9500);
  static const Color infoBlue = Color(0xFF00A3FF);

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
              color: cyanAccent.withOpacity(0.3),
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
      primaryColor: cyanAccent,
      colorScheme: const ColorScheme.dark(
        primary: cyanAccent,
        secondary: darkCyan,
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
        ).copyWith(fontFamilyFallback: ['sans-serif']),
        displayMedium: GoogleFonts.spaceGrotesk(
          fontSize: 28, 
          fontWeight: FontWeight.bold, 
          color: textWhite,
          letterSpacing: -0.5,
        ).copyWith(fontFamilyFallback: ['sans-serif']),
        displaySmall: GoogleFonts.spaceGrotesk(
          fontSize: 20, 
          fontWeight: FontWeight.w600, 
          color: textWhite,
        ).copyWith(fontFamilyFallback: ['sans-serif']),
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
            color: cyanAccent.withOpacity(0.2),
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
          borderSide: const BorderSide(color: cyanAccent, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textGrey, fontSize: 13),
        hintStyle: const TextStyle(color: textDimmed, fontSize: 13),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cyanAccent,
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
          foregroundColor: cyanAccent,
          side: const BorderSide(color: cyanAccent, width: 1.5),
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
        color: cyanAccent,
        size: 20,
      ),
    );
  }

  // Code Syntax Highlighting Theme (Matrix/Cyberpunk Style)
  static Map<String, TextStyle> get codeTheme => {
    'root': const TextStyle(color: Color(0xffabb2bf), backgroundColor: Color(0xff0a0a0a)),
    'comment': const TextStyle(color: Color(0xff5c6370), fontStyle: FontStyle.italic),
    'quote': const TextStyle(color: Color(0xff5c6370), fontStyle: FontStyle.italic),
    'doctag': const TextStyle(color: Color(0xffc678dd)),
    'keyword': const TextStyle(color: Color(0xffc678dd)),
    'formula': const TextStyle(color: Color(0xffc678dd)),
    'section': const TextStyle(color: Color(0xffe06c75)),
    'name': const TextStyle(color: Color(0xffe06c75)),
    'selector-tag': const TextStyle(color: Color(0xffe06c75)),
    'deletion': const TextStyle(color: Color(0xffe06c75)),
    'subst': const TextStyle(color: Color(0xffe06c75)),
    'literal': const TextStyle(color: Color(0xff56b6c2)),
    'string': const TextStyle(color: cyanAccent),
    'regexp': const TextStyle(color: cyanAccent),
    'addition': const TextStyle(color: cyanAccent),
    'attribute': const TextStyle(color: cyanAccent),
    'meta-string': const TextStyle(color: cyanAccent),
    'built_in': const TextStyle(color: Color(0xffe6c07b)),
    'class': const TextStyle(color: Color(0xffe6c07b)),
    'title': const TextStyle(color: Color(0xff61afef)),
    'variable': const TextStyle(color: Color(0xff61afef)),
    'template-variable': const TextStyle(color: Color(0xff61afef)),
    'type': const TextStyle(color: Color(0xff61afef)),
    'symbol': const TextStyle(color: Color(0xff61afef)),
    'bullet': const TextStyle(color: Color(0xff61afef)),
    'number': const TextStyle(color: Color(0xffd19a66)),
    'link': const TextStyle(color: Color(0xff61afef), decoration: TextDecoration.underline),
  };
}
