import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Brand Colors ─────────────────────────────────────────────────────────────
  static const Color maroon      = Color(0xFF7B1E1E);
  static const Color maroonDark  = Color(0xFF5A1414);
  static const Color maroonLight = Color(0xFFE57373); // lightened for dark mode
  static const Color orange      = Color(0xFFE8620A);
  static const Color orangeLight = Color(0xFFFF8C38);
  static const Color orangeDark  = Color(0xFFFFB74D); // lightened for dark mode

  // ── Surface Colors ────────────────────────────────────────────────────────────
  static const Color surface     = Color(0xFFF7F2F2); // light mode scaffold
  static const Color cardBg      = Colors.white;

  // ── Dark Mode Surfaces ────────────────────────────────────────────────────────
  static const Color darkSurface = Color(0xFF1A1414); // very dark maroon-tinted bg
  static const Color darkCard    = Color(0xFF251E1E); // dark card
  static const Color darkInput   = Color(0xFF2E2424); // dark input fill

  // ── Shared text colors ────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF1C1B1F);
  static const Color textSecondary = Color(0xFF49454F);
  static const Color textHint      = Color(0xFF79747E);

  static const Color darkTextPrimary   = Color(0xFFF0E8E8);
  static const Color darkTextSecondary = Color(0xFFBBAAAA);
  static const Color darkTextHint      = Color(0xFF8A7878);

  // ═══════════════════════════════════════════════════════════════════════════
  //  LIGHT THEME
  // ═══════════════════════════════════════════════════════════════════════════
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary:                  maroon,
          onPrimary:                Colors.white,
          primaryContainer:         Color(0xFFFBEBEB),
          onPrimaryContainer:       maroonDark,
          secondary:                orange,
          onSecondary:              Colors.white,
          secondaryContainer:       Color(0xFFFFF0E6),
          onSecondaryContainer:     Color(0xFF6B2D00),
          tertiary:                 Color(0xFF4A90D9),
          onTertiary:               Colors.white,
          error:                    Color(0xFFBA1A1A),
          onError:                  Colors.white,
          errorContainer:           Color(0xFFFFDAD6),
          onErrorContainer:         Color(0xFF410002),
          surface:                  cardBg,
          onSurface:                textPrimary,
          surfaceContainerHighest:  surface,
          onSurfaceVariant:         textSecondary,
          outline:                  Color(0xFF79747E),
        ),
        textTheme: GoogleFonts.interTextTheme(
          // Anchor every text style to a dark base so they're always readable
          // on the light surface background, regardless of Flutter defaults.
          const TextTheme(
            displayLarge:  TextStyle(color: textPrimary),
            displayMedium: TextStyle(color: textPrimary),
            displaySmall:  TextStyle(color: textPrimary),
            headlineLarge: TextStyle(color: textPrimary),
            headlineMedium:TextStyle(color: textPrimary),
            headlineSmall: TextStyle(color: textPrimary),
            titleLarge:    TextStyle(color: textPrimary),
            titleMedium:   TextStyle(color: textPrimary),
            titleSmall:    TextStyle(color: textPrimary),
            bodyLarge:     TextStyle(color: textPrimary),
            bodyMedium:    TextStyle(color: textPrimary),
            bodySmall:     TextStyle(color: textSecondary),
            labelLarge:    TextStyle(color: textPrimary),
            labelMedium:   TextStyle(color: textSecondary),
            labelSmall:    TextStyle(color: textSecondary),
          ),
        ),
        scaffoldBackgroundColor: surface,
        appBarTheme: AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: maroon,
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: cardBg,
          surfaceTintColor: Colors.transparent,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: maroon,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: maroon,
            side: const BorderSide(color: maroon, width: 1.5),
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD0C8C8)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD0C8C8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: maroon, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFBA1A1A)),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          filled: true,
          fillColor: Colors.white,
          // Label and hint are explicitly dark so they're always visible
          labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
          hintStyle: const TextStyle(color: textHint, fontSize: 14),
          // Icons inside the field use the secondary text color
          prefixIconColor: textSecondary,
          suffixIconColor: textSecondary,
        ),
        // Text field cursor and selection
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: maroon,
          selectionColor: Color(0x667B1E1E),
          selectionHandleColor: maroon,
        ),
        dividerTheme: const DividerThemeData(color: Color(0xFFF0E8E8), thickness: 1),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? maroon : Colors.grey.shade400),
          trackColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected)
                  ? maroon.withOpacity(0.3)
                  : Colors.grey.shade200),
        ),
        listTileTheme: const ListTileThemeData(
          textColor: textPrimary,
          iconColor: textSecondary,
        ),
        iconTheme: const IconThemeData(color: textSecondary),
        chipTheme: ChipThemeData(
          labelStyle: const TextStyle(color: textPrimary),
          backgroundColor: surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

  // ═══════════════════════════════════════════════════════════════════════════
  //  DARK THEME
  // ═══════════════════════════════════════════════════════════════════════════
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary:                  maroonLight,      // lighter maroon on dark bg
          onPrimary:                Color(0xFF3A0000),
          primaryContainer:         Color(0xFF5A1414),
          onPrimaryContainer:       Color(0xFFFFDAD6),
          secondary:                orangeDark,        // lighter orange on dark bg
          onSecondary:              Color(0xFF4A1900),
          secondaryContainer:       Color(0xFF6B3300),
          onSecondaryContainer:     Color(0xFFFFDBC9),
          tertiary:                 Color(0xFF90CAF9),
          onTertiary:               Color(0xFF00315E),
          error:                    Color(0xFFFFB4AB),
          onError:                  Color(0xFF690005),
          errorContainer:           Color(0xFF93000A),
          onErrorContainer:         Color(0xFFFFDAD6),
          surface:                  darkCard,
          onSurface:                darkTextPrimary,
          surfaceContainerHighest:  darkSurface,
          onSurfaceVariant:         darkTextSecondary,
          outline:                  Color(0xFF6A5555),
        ),
        textTheme: GoogleFonts.interTextTheme(
          const TextTheme(
            displayLarge:  TextStyle(color: darkTextPrimary),
            displayMedium: TextStyle(color: darkTextPrimary),
            displaySmall:  TextStyle(color: darkTextPrimary),
            headlineLarge: TextStyle(color: darkTextPrimary),
            headlineMedium:TextStyle(color: darkTextPrimary),
            headlineSmall: TextStyle(color: darkTextPrimary),
            titleLarge:    TextStyle(color: darkTextPrimary),
            titleMedium:   TextStyle(color: darkTextPrimary),
            titleSmall:    TextStyle(color: darkTextPrimary),
            bodyLarge:     TextStyle(color: darkTextPrimary),
            bodyMedium:    TextStyle(color: darkTextPrimary),
            bodySmall:     TextStyle(color: darkTextSecondary),
            labelLarge:    TextStyle(color: darkTextPrimary),
            labelMedium:   TextStyle(color: darkTextSecondary),
            labelSmall:    TextStyle(color: darkTextSecondary),
          ),
        ),
        scaffoldBackgroundColor: darkSurface,
        appBarTheme: AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: maroonDark, // keep maroon header in dark mode
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: darkCard,
          surfaceTintColor: Colors.transparent,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: maroonLight,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: maroonLight,
            side: const BorderSide(color: maroonLight, width: 1.5),
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF5A4444)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF5A4444)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: maroonLight, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFFFB4AB)),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          filled: true,
          fillColor: darkInput,
          labelStyle: const TextStyle(color: darkTextSecondary, fontSize: 14),
          hintStyle: const TextStyle(color: darkTextHint, fontSize: 14),
          prefixIconColor: darkTextSecondary,
          suffixIconColor: darkTextSecondary,
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: maroonLight,
          selectionColor: maroonLight.withOpacity(0.4),
          selectionHandleColor: maroonLight,
        ),
        dividerTheme: const DividerThemeData(color: Color(0xFF3A2E2E), thickness: 1),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? maroonLight : Colors.grey.shade600),
          trackColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected)
                  ? maroonLight.withOpacity(0.35)
                  : Colors.grey.shade800),
        ),
        listTileTheme: const ListTileThemeData(
          textColor: darkTextPrimary,
          iconColor: darkTextSecondary,
        ),
        iconTheme: const IconThemeData(color: darkTextSecondary),
        chipTheme: ChipThemeData(
          labelStyle: const TextStyle(color: darkTextPrimary),
          backgroundColor: darkCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: darkCard,
        ),
      );
}
